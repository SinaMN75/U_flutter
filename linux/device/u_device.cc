#include "u_device.h"

#include <gio/gio.h>
#include <langinfo.h>
#include <locale.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/utsname.h>
#include <unistd.h>

#include <cstdlib>
#include <cstring>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>

namespace {

struct UDevicePlugin {
  FlMethodChannel* channel = nullptr;
  FlEventChannel* events = nullptr;
  bool listening = false;
  guint debounce = 0;
  gulong changed_handler = 0;
  gulong connectivity_handler = 0;
  gulong metered_handler = 0;
};

UDevicePlugin* g_device = nullptr;

// --- small helpers ------------------------------------------------------------

std::string Trim(const std::string& text) {
  const size_t start = text.find_first_not_of(" \t\r\n");
  if (start == std::string::npos) return std::string();
  const size_t end = text.find_last_not_of(" \t\r\n");
  return text.substr(start, end - start + 1);
}

std::string ReadFile(const std::string& path) {
  g_autofree gchar* contents = nullptr;
  gsize length = 0;
  if (!g_file_get_contents(path.c_str(), &contents, &length, nullptr)) return std::string();
  return Trim(std::string(contents, length));
}

bool Exists(const std::string& path) { return g_file_test(path.c_str(), G_FILE_TEST_EXISTS); }

bool StartsWith(const std::string& text, const char* prefix) { return text.rfind(prefix, 0) == 0; }

std::string Lower(std::string text) {
  for (char& c : text) c = static_cast<char>(g_ascii_tolower(c));
  return text;
}

void SetString(FlValue* map, const char* key, const std::string& value) {
  fl_value_set_string_take(map, key, value.empty() ? fl_value_new_null() : fl_value_new_string(value.c_str()));
}

void SetInt(FlValue* map, const char* key, int64_t value) { fl_value_set_string_take(map, key, fl_value_new_int(value)); }

void SetBool(FlValue* map, const char* key, bool value) { fl_value_set_string_take(map, key, fl_value_new_bool(value)); }

void SetNull(FlValue* map, const char* key) { fl_value_set_string_take(map, key, fl_value_new_null()); }

std::map<std::string, std::string> OsRelease() {
  std::map<std::string, std::string> out;
  std::string text = ReadFile("/etc/os-release");
  if (text.empty()) text = ReadFile("/usr/lib/os-release");
  std::istringstream lines(text);
  std::string line;
  while (std::getline(lines, line)) {
    const size_t eq = line.find('=');
    if (eq == std::string::npos) continue;
    std::string value = line.substr(eq + 1);
    if (value.size() >= 2 && (value.front() == '"' || value.front() == '\'')) value = value.substr(1, value.size() - 2);
    out[line.substr(0, eq)] = value;
  }
  return out;
}

// Returns reasons the machine looks virtual (DMI strings + the CPU's hypervisor flag).
std::vector<std::string> VirtualMachineReasons() {
  std::vector<std::string> reasons;
  const std::string vendor = Lower(ReadFile("/sys/class/dmi/id/sys_vendor"));
  const std::string product = Lower(ReadFile("/sys/class/dmi/id/product_name"));
  for (const char* marker : {"qemu", "vmware", "virtualbox", "innotek", "kvm", "xen", "parallels", "bochs"}) {
    if (vendor.find(marker) != std::string::npos || product.find(marker) != std::string::npos) reasons.push_back(std::string("hypervisor ") + marker);
  }
  if (vendor.find("microsoft") != std::string::npos && product.find("virtual machine") != std::string::npos) reasons.push_back("Hyper-V guest");
  if (reasons.empty()) {
    const std::string cpuinfo = ReadFile("/proc/cpuinfo");
    if (cpuinfo.find(" hypervisor") != std::string::npos) reasons.push_back("CPU reports a hypervisor");
  }
  return reasons;
}

// --- device -------------------------------------------------------------------

std::string TimeZone() {
  const char* env = g_getenv("TZ");
  if (env != nullptr && *env != '\0') {
    std::string tz = env[0] == ':' ? env + 1 : env;
    const size_t zoneinfo = tz.find("zoneinfo/");
    if (zoneinfo != std::string::npos) tz = tz.substr(zoneinfo + 9);
    if (!tz.empty() && tz[0] != '/') return tz;
  }
  g_autofree gchar* link = g_file_read_link("/etc/localtime", nullptr);
  if (link != nullptr) {
    const std::string target = link;
    const size_t zoneinfo = target.find("zoneinfo/");
    if (zoneinfo != std::string::npos) return target.substr(zoneinfo + 9);
  }
  return ReadFile("/etc/timezone");
}

FlValue* Locales() {
  FlValue* list = fl_value_new_list();
  std::set<std::string> seen;
  for (const gchar* const* name = g_get_language_names(); *name != nullptr; name++) {
    std::string tag = *name;
    if (tag == "C" || tag == "POSIX" || tag.find('.') != std::string::npos || tag.find('@') != std::string::npos) continue;
    for (char& c : tag) {
      if (c == '_') c = '-';
    }
    if (seen.insert(tag).second) fl_value_append_take(list, fl_value_new_string(tag.c_str()));
  }
  return list;
}

// Reads the user's LC_TIME without touching the process-wide locale.
void Set24h(FlValue* map) {
  locale_t locale = newlocale(LC_TIME_MASK, "", static_cast<locale_t>(0));
  if (locale == static_cast<locale_t>(0)) {
    SetNull(map, "is24h");
    return;
  }
  const char* format = nl_langinfo_l(T_FMT, locale);
  if (strstr(format, "%H") || strstr(format, "%k") || strstr(format, "%T") || strstr(format, "%R")) {
    SetBool(map, "is24h", true);
  } else if (strstr(format, "%I") || strstr(format, "%l") || strstr(format, "%r")) {
    SetBool(map, "is24h", false);
  } else {
    SetNull(map, "is24h");
  }
  freelocale(locale);
}

FlValue* DeviceInfo() {
  std::map<std::string, std::string> os = OsRelease();
  struct utsname uts = {};
  uname(&uts);
  const std::string vendor = ReadFile("/sys/class/dmi/id/sys_vendor");
  const std::string product = ReadFile("/sys/class/dmi/id/product_name");
  std::string id = ReadFile("/etc/machine-id");
  if (id.empty()) id = ReadFile("/var/lib/dbus/machine-id");
  std::string arch = uts.machine;
  if (arch == "aarch64") arch = "arm64";
  const long pages = sysconf(_SC_PHYS_PAGES);
  const long page_size = sysconf(_SC_PAGE_SIZE);

  FlValue* extra = fl_value_new_map();
  SetString(extra, "id", os["ID"]);
  SetString(extra, "idLike", os["ID_LIKE"]);
  SetString(extra, "prettyName", os["PRETTY_NAME"]);
  SetString(extra, "versionCodename", os["VERSION_CODENAME"]);
  SetString(extra, "kernel", uts.release);
  SetString(extra, "desktop", g_getenv("XDG_CURRENT_DESKTOP") ? g_getenv("XDG_CURRENT_DESKTOP") : "");
  SetString(extra, "sessionType", g_getenv("XDG_SESSION_TYPE") ? g_getenv("XDG_SESSION_TYPE") : "");
  SetString(extra, "boardName", ReadFile("/sys/class/dmi/id/board_name"));
  SetString(extra, "biosVersion", ReadFile("/sys/class/dmi/id/bios_version"));
  SetBool(extra, "flatpak", Exists("/.flatpak-info"));
  SetBool(extra, "snap", g_getenv("SNAP") != nullptr);

  FlValue* map = fl_value_new_map();
  SetString(map, "platform", "linux");
  SetString(map, "os", os["NAME"].empty() ? "Linux" : os["NAME"]);
  SetString(map, "osVersion", os["VERSION_ID"]);
  SetString(map, "osBuild", uts.release);
  SetString(map, "model", product);
  SetString(map, "manufacturer", vendor);
  SetString(map, "brand", vendor);
  SetString(map, "name", g_get_host_name());
  // SMBIOS chassis type 30 is "Tablet"; everything else here is a PC form factor.
  SetString(map, "type", ReadFile("/sys/class/dmi/id/chassis_type") == "30" ? "tablet" : "desktop");
  SetBool(map, "physical", VirtualMachineReasons().empty());
  SetString(map, "id", id);
  SetString(map, "arch", arch);
  SetInt(map, "cores", sysconf(_SC_NPROCESSORS_ONLN));
  if (pages > 0 && page_size > 0) SetInt(map, "memory", static_cast<int64_t>(pages) * page_size);
  fl_value_set_string_take(map, "locales", Locales());
  SetString(map, "timeZone", TimeZone());
  Set24h(map);
  fl_value_set_string_take(map, "extra", extra);
  return map;
}

// --- package ------------------------------------------------------------------

// Name and version come from flutter_assets/version.json on the Dart side.
FlValue* PackageInfo() {
  FlValue* map = fl_value_new_map();
  g_autofree gchar* exe = g_file_read_link("/proc/self/exe", nullptr);
  SetString(map, "executable", exe ? exe : "");
  struct stat info = {};
  if (exe != nullptr && stat(exe, &info) == 0) {
    SetInt(map, "updateTime", static_cast<int64_t>(info.st_mtim.tv_sec) * 1000 + info.st_mtim.tv_nsec / 1000000);
  }
  GApplication* app = g_application_get_default();
  const gchar* app_id = app != nullptr ? g_application_get_application_id(app) : nullptr;
  SetString(map, "packageName", app_id ? app_id : "");
  const gchar* name = g_get_application_name();
  SetString(map, "appName", name ? name : "");
  std::string installer;
  if (g_getenv("FLATPAK_ID") != nullptr || Exists("/.flatpak-info")) {
    installer = "flatpak";
  } else if (g_getenv("SNAP") != nullptr) {
    installer = "snap";
  } else if (g_getenv("APPIMAGE") != nullptr) {
    installer = "appimage";
  }
  SetString(map, "installer", installer);
  return map;
}

// --- network ------------------------------------------------------------------

// Interfaces that hold a default route (IPv4 and IPv6); [primary] gets the lowest-metric one.
std::set<std::string> DefaultRouteInterfaces(std::string* primary) {
  std::set<std::string> out;
  long best = -1;
  {
    std::istringstream lines(ReadFile("/proc/net/route"));
    std::string line;
    std::getline(lines, line);  // header
    while (std::getline(lines, line)) {
      std::istringstream fields(line);
      std::string iface, destination, gateway, flags, refcnt, use, metric, mask;
      if (!(fields >> iface >> destination >> gateway >> flags >> refcnt >> use >> metric >> mask)) continue;
      if (destination != "00000000" || mask != "00000000" || (strtol(flags.c_str(), nullptr, 16) & 0x1) == 0) continue;
      out.insert(iface);
      const long value = strtol(metric.c_str(), nullptr, 10);
      if (best < 0 || value < best) {
        best = value;
        *primary = iface;
      }
    }
  }
  {
    std::istringstream lines(ReadFile("/proc/net/ipv6_route"));
    std::string line;
    while (std::getline(lines, line)) {
      std::istringstream fields(line);
      std::string destination, prefix, source, source_prefix, next_hop, metric, refcnt, use, flags, iface;
      if (!(fields >> destination >> prefix >> source >> source_prefix >> next_hop >> metric >> refcnt >> use >> flags >> iface)) continue;
      if (iface == "lo" || prefix != "00" || destination != std::string(32, '0')) continue;
      out.insert(iface);
      if (primary->empty()) *primary = iface;
    }
  }
  return out;
}

std::string KindOf(const std::string& name) {
  const std::string sys = "/sys/class/net/" + name;
  if (Exists(sys + "/wireless") || Exists(sys + "/phy80211")) return "wifi";
  if (Exists(sys + "/tun_flags")) return "vpn";
  for (const char* prefix : {"tun", "tap", "wg", "ipsec", "vpn", "nordlynx", "tailscale", "zt", "proton"}) {
    if (StartsWith(name, prefix)) return "vpn";
  }
  for (const char* prefix : {"wwan", "rmnet", "ccmni", "wwp"}) {
    if (StartsWith(name, prefix)) return "cellular";
  }
  if (StartsWith(name, "bnep") || StartsWith(name, "bt")) return "bluetooth";
  if (StartsWith(name, "usb") || StartsWith(name, "rndis")) return "usb";
  if (ReadFile(sys + "/type") == "1") return "ethernet";
  return "other";
}

FlValue* NetworkSnapshot() {
  GNetworkMonitor* monitor = g_network_monitor_get_default();
  std::string primary;
  std::set<std::string> kinds;
  for (const std::string& iface : DefaultRouteInterfaces(&primary)) kinds.insert(KindOf(iface));
  const bool connected = !kinds.empty() && g_network_monitor_get_network_available(monitor);

  // Only the NetworkManager and portal monitors actually probe the internet; the netlink
  // fallback reports FULL for any default route, so its answer means "unknown".
  const gchar* impl = G_OBJECT_TYPE_NAME(monitor);
  const bool probes = strstr(impl, "NM") != nullptr || strstr(impl, "Portal") != nullptr;
  const GNetworkConnectivity connectivity = g_network_monitor_get_connectivity(monitor);

  FlValue* map = fl_value_new_map();
  FlValue* types = fl_value_new_list();
  if (connected) {
    for (const std::string& kind : kinds) fl_value_append_take(types, fl_value_new_string(kind.c_str()));
  }
  fl_value_set_string_take(map, "types", types);
  SetBool(map, "connected", connected);
  if (!connected || connectivity == G_NETWORK_CONNECTIVITY_LOCAL || connectivity == G_NETWORK_CONNECTIVITY_LIMITED ||
      connectivity == G_NETWORK_CONNECTIVITY_PORTAL) {
    SetBool(map, "internet", false);
  } else if (probes) {
    SetBool(map, "internet", true);
  } else {
    SetNull(map, "internet");
  }
  SetBool(map, "captivePortal", connected && connectivity == G_NETWORK_CONNECTIVITY_PORTAL);
  SetBool(map, "metered", g_network_monitor_get_network_metered(monitor) || kinds.count("cellular") > 0);
  SetString(map, "interface", primary);
  return map;
}

gboolean EmitNetwork(gpointer) {
  g_device->debounce = 0;
  if (g_device->listening) {
    g_autoptr(FlValue) snapshot = NetworkSnapshot();
    fl_event_channel_send(g_device->events, snapshot, nullptr, nullptr);
  }
  return G_SOURCE_REMOVE;
}

// Route, address and connectivity changes arrive in bursts: report once they settle.
void ScheduleEmit(guint delay_ms) {
  if (g_device->debounce != 0) g_source_remove(g_device->debounce);
  g_device->debounce = g_timeout_add(delay_ms, EmitNetwork, nullptr);
}

void OnNetworkChanged(GNetworkMonitor*, gboolean, gpointer) { ScheduleEmit(300); }

void OnNetworkNotify(GObject*, GParamSpec*, gpointer) { ScheduleEmit(300); }

FlMethodErrorResponse* OnListen(FlEventChannel*, FlValue*, gpointer) {
  g_device->listening = true;
  GNetworkMonitor* monitor = g_network_monitor_get_default();
  if (g_device->changed_handler == 0) {
    g_device->changed_handler = g_signal_connect(monitor, "network-changed", G_CALLBACK(OnNetworkChanged), nullptr);
    g_device->connectivity_handler = g_signal_connect(monitor, "notify::connectivity", G_CALLBACK(OnNetworkNotify), nullptr);
    g_device->metered_handler = g_signal_connect(monitor, "notify::network-metered", G_CALLBACK(OnNetworkNotify), nullptr);
  }
  ScheduleEmit(0);
  return nullptr;
}

FlMethodErrorResponse* OnCancel(FlEventChannel*, FlValue*, gpointer) {
  g_device->listening = false;
  GNetworkMonitor* monitor = g_network_monitor_get_default();
  for (gulong* handler : {&g_device->changed_handler, &g_device->connectivity_handler, &g_device->metered_handler}) {
    if (*handler != 0) g_signal_handler_disconnect(monitor, *handler);
    *handler = 0;
  }
  if (g_device->debounce != 0) g_source_remove(g_device->debounce);
  g_device->debounce = 0;
  return nullptr;
}

// --- status -------------------------------------------------------------------

int64_t MeminfoBytes(const std::string& meminfo, const char* key) {
  const size_t at = meminfo.find(key);
  if (at == std::string::npos) return -1;
  return strtoll(meminfo.c_str() + at + strlen(key), nullptr, 10) * 1024;
}

void SetBattery(FlValue* map) {
  GDir* dir = g_dir_open("/sys/class/power_supply", 0, nullptr);
  bool found = false;
  bool on_ac = false;
  if (dir != nullptr) {
    for (const gchar* entry = g_dir_read_name(dir); entry != nullptr; entry = g_dir_read_name(dir)) {
      const std::string base = std::string("/sys/class/power_supply/") + entry;
      const std::string type = ReadFile(base + "/type");
      if (type == "Mains" && ReadFile(base + "/online") == "1") on_ac = true;
      // scope=Device marks peripherals (mice, headsets), not the system battery.
      if (found || type != "Battery" || ReadFile(base + "/scope") == "Device") continue;
      found = true;
      const std::string capacity = ReadFile(base + "/capacity");
      if (!capacity.empty()) SetInt(map, "battery", strtol(capacity.c_str(), nullptr, 10));
      const std::string status = ReadFile(base + "/status");
      const char* state = status == "Charging" ? "charging" : status == "Discharging" ? "discharging" : status == "Full" ? "full" : status == "Not charging" ? "notCharging" : "unknown";
      SetString(map, "batteryState", state);
    }
    g_dir_close(dir);
  }
  if (!found) SetString(map, "batteryState", "none");
  SetBool(map, "onAc", on_ac);
}

FlValue* Status() {
  FlValue* map = fl_value_new_map();
  SetBattery(map);
#if GLIB_CHECK_VERSION(2, 70, 0)
  GPowerProfileMonitor* power = g_power_profile_monitor_dup_default();
  if (power != nullptr) {
    SetBool(map, "powerSave", g_power_profile_monitor_get_power_saver_enabled(power));
    g_object_unref(power);
  }
#endif
  const std::string meminfo = ReadFile("/proc/meminfo");
  const int64_t total = MeminfoBytes(meminfo, "MemTotal:");
  const int64_t available = MeminfoBytes(meminfo, "MemAvailable:");
  if (total >= 0) SetInt(map, "memTotal", total);
  if (available >= 0) SetInt(map, "memFree", available);
  struct statvfs disk = {};
  if (statvfs(g_get_user_data_dir(), &disk) == 0) {
    SetInt(map, "diskFree", static_cast<int64_t>(disk.f_bavail) * static_cast<int64_t>(disk.f_frsize));
    SetInt(map, "diskTotal", static_cast<int64_t>(disk.f_blocks) * static_cast<int64_t>(disk.f_frsize));
  }
  const std::string uptime = ReadFile("/proc/uptime");
  if (!uptime.empty()) SetInt(map, "uptimeMs", static_cast<int64_t>(g_ascii_strtod(uptime.c_str(), nullptr) * 1000));
  SetString(map, "thermal", "unknown");
  return map;
}

// --- integrity ----------------------------------------------------------------

FlValue* Integrity() {
  FlValue* reasons = fl_value_new_list();
  const std::string status = ReadFile("/proc/self/status");
  const size_t tracer = status.find("TracerPid:");
  const bool debugger = tracer != std::string::npos && strtol(status.c_str() + tracer + 10, nullptr, 10) != 0;
  if (debugger) fl_value_append_take(reasons, fl_value_new_string("debugger attached"));

  bool hooked = false;
  const char* preload = g_getenv("LD_PRELOAD");
  if (preload != nullptr && *preload != '\0') {
    hooked = true;
    fl_value_append_take(reasons, fl_value_new_string("LD_PRELOAD set"));
  }
  if (Lower(ReadFile("/proc/self/maps")).find("frida") != std::string::npos) {
    hooked = true;
    fl_value_append_take(reasons, fl_value_new_string("frida loaded in process"));
  }
  const std::vector<std::string> vm = VirtualMachineReasons();
  for (const std::string& reason : vm) fl_value_append_take(reasons, fl_value_new_string(reason.c_str()));

  FlValue* map = fl_value_new_map();
  SetBool(map, "debugger", debugger);
  SetBool(map, "hooked", hooked);
  SetBool(map, "vm", !vm.empty());
  fl_value_set_string_take(map, "reasons", reasons);
  return map;
}

// --- channel ------------------------------------------------------------------

void HandleMethodCall(FlMethodChannel*, FlMethodCall* call, gpointer) {
  const gchar* method = fl_method_call_get_name(call);
  FlValue* result = nullptr;
  if (strcmp(method, "bootstrap") == 0) {
    result = fl_value_new_map();
    fl_value_set_string_take(result, "device", DeviceInfo());
    fl_value_set_string_take(result, "package", PackageInfo());
    fl_value_set_string_take(result, "network", NetworkSnapshot());
  } else if (strcmp(method, "network") == 0) {
    result = NetworkSnapshot();
  } else if (strcmp(method, "status") == 0) {
    result = Status();
  } else if (strcmp(method, "integrity") == 0) {
    result = Integrity();
  }
  g_autoptr(FlMethodResponse) response = nullptr;
  if (result != nullptr) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    fl_value_unref(result);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(call, response, nullptr);
}

}  // namespace

void u_device_register(FlPluginRegistrar* registrar) {
  if (g_device != nullptr) return;
  g_device = new UDevicePlugin();
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_device->channel = fl_method_channel_new(messenger, "u/device", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(g_device->channel, HandleMethodCall, nullptr, nullptr);
  g_device->events = fl_event_channel_new(messenger, "u/device/network", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(g_device->events, OnListen, OnCancel, nullptr, nullptr);
}
