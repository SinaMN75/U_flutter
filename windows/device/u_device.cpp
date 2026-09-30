// winsock2 must precede windows.h (pulled in by the Flutter headers in u_device.h).
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <netioapi.h>

#include "u_device.h"

#include <netlistmgr.h>
#include <shlobj.h>
#include <tlhelp32.h>
#include <wrl/client.h>

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cwctype>
#include <set>
#include <string>
#include <vector>

namespace u {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using Microsoft::WRL::ComPtr;

constexpr UINT kNetworkChangedMessage = WM_APP + 0x55;
constexpr UINT_PTR kDebounceTimer = 1;
constexpr UINT_PTR kRecheckTimer = 2;
constexpr wchar_t kWindowClass[] = L"UDeviceMessageWindow";

std::string Narrow(const std::wstring& wide) {
  if (wide.empty()) return std::string();
  const int size = WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()), nullptr, 0, nullptr, nullptr);
  std::string out(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()), out.data(), size, nullptr, nullptr);
  return out;
}

std::wstring Lower(std::wstring text) {
  std::transform(text.begin(), text.end(), text.begin(), [](wchar_t c) { return static_cast<wchar_t>(std::towlower(c)); });
  return text;
}

bool Contains(const std::wstring& haystack, const wchar_t* needle) { return haystack.find(needle) != std::wstring::npos; }

EncodableValue Text(const std::wstring& value) { return value.empty() ? EncodableValue() : EncodableValue(Narrow(value)); }

int64_t UnixMillis(const FILETIME& time) {
  ULARGE_INTEGER value;
  value.LowPart = time.dwLowDateTime;
  value.HighPart = time.dwHighDateTime;
  return static_cast<int64_t>((value.QuadPart - 116444736000000000ULL) / 10000ULL);
}

// Reads from the 64-bit registry view even in a 32-bit process.
std::wstring RegString(HKEY root, const wchar_t* path, const wchar_t* name) {
  DWORD size = 0;
  const DWORD flags = RRF_RT_REG_SZ | RRF_SUBKEY_WOW6464KEY;
  if (RegGetValueW(root, path, name, flags, nullptr, nullptr, &size) != ERROR_SUCCESS || size == 0) return std::wstring();
  std::wstring value(size / sizeof(wchar_t), L'\0');
  if (RegGetValueW(root, path, name, flags, nullptr, value.data(), &size) != ERROR_SUCCESS) return std::wstring();
  value.resize(wcslen(value.c_str()));
  return value;
}

DWORD RegDword(HKEY root, const wchar_t* path, const wchar_t* name) {
  DWORD value = 0;
  DWORD size = sizeof(value);
  if (RegGetValueW(root, path, name, RRF_RT_REG_DWORD | RRF_SUBKEY_WOW6464KEY, nullptr, &value, &size) != ERROR_SUCCESS) return 0;
  return value;
}

// GetVersionEx lies without an app manifest; RtlGetVersion never does.
RTL_OSVERSIONINFOW OsVersion() {
  RTL_OSVERSIONINFOW info = {};
  info.dwOSVersionInfoSize = sizeof(info);
  using RtlGetVersionFn = LONG(WINAPI*)(PRTL_OSVERSIONINFOW);
  if (HMODULE ntdll = GetModuleHandleW(L"ntdll.dll")) {
    if (auto fn = reinterpret_cast<RtlGetVersionFn>(GetProcAddress(ntdll, "RtlGetVersion"))) fn(&info);
  }
  return info;
}

// Windows names zones "Iran Standard Time"; the ICU that ships with Windows 10 1903+ maps them to IANA.
std::string IanaTimeZone() {
  DYNAMIC_TIME_ZONE_INFORMATION zone = {};
  if (GetDynamicTimeZoneInformation(&zone) == TIME_ZONE_ID_INVALID) return std::string();
  HMODULE icu = LoadLibraryExW(L"icu.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
  if (icu == nullptr) return std::string();
  using ToIanaFn = int32_t(__cdecl*)(const wchar_t*, int32_t, const char*, wchar_t*, int32_t, int*);
  std::string out;
  if (auto fn = reinterpret_cast<ToIanaFn>(GetProcAddress(icu, "ucal_getTimeZoneIDForWindowsID"))) {
    wchar_t id[128] = {};
    int status = 0;
    const int32_t length = fn(zone.TimeZoneKeyName, -1, nullptr, id, 128, &status);
    if (status <= 0 && length > 0) out = Narrow(std::wstring(id, length));
  }
  FreeLibrary(icu);
  return out;
}

EncodableList Locales() {
  EncodableList out;
  ULONG count = 0;
  ULONG size = 0;
  if (!GetUserPreferredUILanguages(MUI_LANGUAGE_NAME, &count, nullptr, &size) || size == 0) return out;
  std::wstring buffer(size, L'\0');
  if (!GetUserPreferredUILanguages(MUI_LANGUAGE_NAME, &count, buffer.data(), &size)) return out;
  for (const wchar_t* p = buffer.c_str(); *p != L'\0'; p += wcslen(p) + 1) out.push_back(EncodableValue(Narrow(p)));
  return out;
}

constexpr wchar_t kBios[] = L"HARDWARE\\DESCRIPTION\\System\\BIOS";
constexpr wchar_t kCurrentVersion[] = L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";

std::vector<std::string> VirtualMachineReasons() {
  const std::wstring vendor = Lower(RegString(HKEY_LOCAL_MACHINE, kBios, L"SystemManufacturer"));
  const std::wstring model = Lower(RegString(HKEY_LOCAL_MACHINE, kBios, L"SystemProductName"));
  std::vector<std::string> reasons;
  for (const wchar_t* marker : {L"vmware", L"virtualbox", L"innotek", L"qemu", L"parallels", L"xen", L"kvm", L"bochs"}) {
    if (Contains(vendor, marker) || Contains(model, marker)) reasons.push_back("hypervisor " + Narrow(marker));
  }
  if (Contains(vendor, L"microsoft") && Contains(model, L"virtual machine")) reasons.push_back("Hyper-V guest");
  return reasons;
}

EncodableMap DeviceInfo() {
  const RTL_OSVERSIONINFOW version = OsVersion();
  const DWORD ubr = RegDword(HKEY_LOCAL_MACHINE, kCurrentVersion, L"UBR");
  const std::wstring manufacturer = RegString(HKEY_LOCAL_MACHINE, kBios, L"SystemManufacturer");
  const std::wstring model = RegString(HKEY_LOCAL_MACHINE, kBios, L"SystemProductName");

  wchar_t name[256] = {};
  DWORD name_length = 256;
  if (!GetComputerNameExW(ComputerNamePhysicalDnsHostname, name, &name_length)) name[0] = L'\0';

  // Set once at Windows setup, unique per installation.
  const std::wstring id = RegString(HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Cryptography", L"MachineGuid");

  SYSTEM_INFO system = {};
  GetNativeSystemInfo(&system);
  std::string arch;
  switch (system.wProcessorArchitecture) {
    case PROCESSOR_ARCHITECTURE_AMD64: arch = "x86_64"; break;
    case PROCESSOR_ARCHITECTURE_ARM64: arch = "arm64"; break;
    case PROCESSOR_ARCHITECTURE_INTEL: arch = "x86"; break;
    case PROCESSOR_ARCHITECTURE_ARM: arch = "arm"; break;
    default: arch = "unknown";
  }

  MEMORYSTATUSEX memory = {};
  memory.dwLength = sizeof(memory);
  GlobalMemoryStatusEx(&memory);

  EncodableValue is24h;
  wchar_t time_format[80] = {};
  if (GetLocaleInfoEx(LOCALE_NAME_USER_DEFAULT, LOCALE_STIMEFORMAT, time_format, 80) > 0) is24h = EncodableValue(wcschr(time_format, L'H') != nullptr);

  const std::string timezone = IanaTimeZone();
  const std::string build = std::to_string(version.dwBuildNumber);
  EncodableMap extra = {
      {EncodableValue("productName"), Text(RegString(HKEY_LOCAL_MACHINE, kCurrentVersion, L"ProductName"))},
      {EncodableValue("editionId"), Text(RegString(HKEY_LOCAL_MACHINE, kCurrentVersion, L"EditionID"))},
      {EncodableValue("displayVersion"), Text(RegString(HKEY_LOCAL_MACHINE, kCurrentVersion, L"DisplayVersion"))},
      {EncodableValue("buildLab"), Text(RegString(HKEY_LOCAL_MACHINE, kCurrentVersion, L"BuildLabEx"))},
      {EncodableValue("biosVersion"), Text(RegString(HKEY_LOCAL_MACHINE, kBios, L"BIOSVersion"))},
      {EncodableValue("boardProduct"), Text(RegString(HKEY_LOCAL_MACHINE, kBios, L"BaseBoardProduct"))},
      {EncodableValue("cpuName"), Text(RegString(HKEY_LOCAL_MACHINE, L"HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", L"ProcessorNameString"))},
  };
  return EncodableMap{
      {EncodableValue("platform"), EncodableValue("windows")},
      // Windows 11 still reports major version 10; build 22000 is the dividing line.
      {EncodableValue("os"), EncodableValue(version.dwBuildNumber >= 22000 ? "Windows 11" : "Windows 10")},
      {EncodableValue("osVersion"), EncodableValue(std::to_string(version.dwMajorVersion) + "." + std::to_string(version.dwMinorVersion) + "." + build)},
      {EncodableValue("osBuild"), EncodableValue(ubr ? build + "." + std::to_string(ubr) : build)},
      {EncodableValue("model"), Text(model)},
      {EncodableValue("manufacturer"), Text(manufacturer)},
      {EncodableValue("brand"), Text(manufacturer)},
      {EncodableValue("name"), Text(name)},
      {EncodableValue("type"), EncodableValue("desktop")},
      {EncodableValue("physical"), EncodableValue(VirtualMachineReasons().empty())},
      {EncodableValue("id"), Text(id)},
      {EncodableValue("arch"), EncodableValue(arch)},
      {EncodableValue("cores"), EncodableValue(static_cast<int32_t>(system.dwNumberOfProcessors))},
      {EncodableValue("memory"), EncodableValue(static_cast<int64_t>(memory.ullTotalPhys))},
      {EncodableValue("locales"), EncodableValue(Locales())},
      {EncodableValue("timeZone"), timezone.empty() ? EncodableValue() : EncodableValue(timezone)},
      {EncodableValue("is24h"), is24h},
      {EncodableValue("extra"), EncodableValue(extra)},
  };
}

// Flutter's Runner.rc stamps ProductVersion with the pubspec version ("1.2.3+4"),
// ProductName / InternalName with the project and CompanyName with the org.
EncodableMap PackageInfo() {
  std::vector<wchar_t> path(MAX_PATH);
  DWORD length = 0;
  while ((length = GetModuleFileNameW(nullptr, path.data(), static_cast<DWORD>(path.size()))) == path.size()) path.resize(path.size() * 2);
  const std::wstring exe(path.data(), length);

  std::wstring product_name, product_version, internal_name, company;
  std::wstring fixed_version, fixed_build;
  DWORD ignored = 0;
  const DWORD size = GetFileVersionInfoSizeW(exe.c_str(), &ignored);
  std::vector<BYTE> data(size);
  if (size > 0 && GetFileVersionInfoW(exe.c_str(), 0, size, data.data())) {
    struct Translation {
      WORD language;
      WORD codepage;
    };
    Translation* translations = nullptr;
    UINT translation_bytes = 0;
    if (VerQueryValueW(data.data(), L"\\VarFileInfo\\Translation", reinterpret_cast<LPVOID*>(&translations), &translation_bytes) &&
        translation_bytes >= sizeof(Translation)) {
      wchar_t prefix[64];
      swprintf_s(prefix, L"\\StringFileInfo\\%04x%04x\\", translations[0].language, translations[0].codepage);
      auto query = [&](const wchar_t* key) {
        const std::wstring sub = std::wstring(prefix) + key;
        wchar_t* value = nullptr;
        UINT chars = 0;
        return VerQueryValueW(data.data(), sub.c_str(), reinterpret_cast<LPVOID*>(&value), &chars) && chars > 0 ? std::wstring(value) : std::wstring();
      };
      product_name = query(L"ProductName");
      product_version = query(L"ProductVersion");
      internal_name = query(L"InternalName");
      company = query(L"CompanyName");
    }
    VS_FIXEDFILEINFO* fixed = nullptr;
    UINT fixed_bytes = 0;
    if (VerQueryValueW(data.data(), L"\\", reinterpret_cast<LPVOID*>(&fixed), &fixed_bytes) && fixed != nullptr) {
      fixed_version = std::to_wstring(HIWORD(fixed->dwFileVersionMS)) + L"." + std::to_wstring(LOWORD(fixed->dwFileVersionMS)) + L"." +
                      std::to_wstring(HIWORD(fixed->dwFileVersionLS));
      fixed_build = std::to_wstring(LOWORD(fixed->dwFileVersionLS));
    }
  }

  std::wstring version = product_version;
  std::wstring build;
  const size_t plus = product_version.find(L'+');
  if (plus != std::wstring::npos) {
    version = product_version.substr(0, plus);
    build = product_version.substr(plus + 1);
  } else if (!fixed_version.empty()) {
    version = fixed_version;
    build = fixed_build;
  }

  EncodableValue install_time, update_time;
  WIN32_FILE_ATTRIBUTE_DATA attributes = {};
  if (GetFileAttributesExW(exe.c_str(), GetFileExInfoStandard, &attributes)) {
    install_time = EncodableValue(UnixMillis(attributes.ftCreationTime));
    update_time = EncodableValue(UnixMillis(attributes.ftLastWriteTime));
  }

  const std::wstring app_id = internal_name.empty() ? product_name : internal_name;
  const std::wstring package_name = company.empty() ? app_id : company + L"." + app_id;
  // MSIX / Store installs live under %ProgramFiles%\WindowsApps.
  const bool store = Contains(Lower(exe), L"\\windowsapps\\");
  return EncodableMap{
      {EncodableValue("appName"), Text(product_name)},
      {EncodableValue("packageName"), Text(package_name)},
      {EncodableValue("version"), Text(version)},
      {EncodableValue("buildNumber"), Text(build)},
      {EncodableValue("installer"), store ? EncodableValue("microsoft_store") : EncodableValue()},
      {EncodableValue("installTime"), install_time},
      {EncodableValue("updateTime"), update_time},
      {EncodableValue("executable"), Text(exe)},
  };
}

// COM is normally already initialised on the platform thread; keep the call balanced either way.
struct ComScope {
  HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  ~ComScope() {
    if (SUCCEEDED(hr)) CoUninitialize();
  }
};

bool LooksLikeVpn(const std::wstring& description) {
  for (const wchar_t* marker : {L"vpn", L"tap-", L"tap ", L"wireguard", L"wintun", L"openvpn", L"tunnel", L"fortinet", L"cisco anyconnect", L"globalprotect", L"zerotier", L"tailscale"}) {
    if (Contains(description, marker)) return true;
  }
  return false;
}

EncodableMap NetworkSnapshot() {
  ComScope com;
  std::set<std::string> kinds;
  std::wstring interface_name;

  // The interface Windows would route an internet packet through.
  DWORD best = 0;
  sockaddr_in probe = {};
  probe.sin_family = AF_INET;
  inet_pton(AF_INET, "8.8.8.8", &probe.sin_addr);
  const bool have_best = GetBestInterfaceEx(reinterpret_cast<sockaddr*>(&probe), &best) == NO_ERROR;

  ULONG size = 16 * 1024;
  std::vector<BYTE> buffer(size);
  const ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_DNS_SERVER | GAA_FLAG_INCLUDE_GATEWAYS;
  ULONG rc = GetAdaptersAddresses(AF_UNSPEC, flags, nullptr, reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()), &size);
  if (rc == ERROR_BUFFER_OVERFLOW) {
    buffer.resize(size);
    rc = GetAdaptersAddresses(AF_UNSPEC, flags, nullptr, reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()), &size);
  }
  if (rc == NO_ERROR) {
    for (auto* adapter = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data()); adapter != nullptr; adapter = adapter->Next) {
      if (adapter->OperStatus != IfOperStatusUp || adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK) continue;
      const bool routes_out = adapter->FirstGatewayAddress != nullptr;
      const bool is_best = have_best && adapter->IfIndex == best;
      if (!routes_out && !is_best) continue;
      const std::wstring description = Lower(adapter->Description ? adapter->Description : L"");
      std::string kind;
      if (adapter->IfType == IF_TYPE_PPP || adapter->IfType == IF_TYPE_TUNNEL || LooksLikeVpn(description)) {
        kind = "vpn";
      } else if (adapter->IfType == IF_TYPE_IEEE80211) {
        kind = "wifi";
      } else if (adapter->IfType == IF_TYPE_WWANPP || adapter->IfType == IF_TYPE_WWANPP2) {
        kind = "cellular";
      } else if (Contains(description, L"bluetooth")) {
        kind = "bluetooth";
      } else if (adapter->IfType == IF_TYPE_ETHERNET_CSMACD) {
        kind = "ethernet";
      } else {
        kind = "other";
      }
      kinds.insert(kind);
      if (is_best && adapter->FriendlyName != nullptr) interface_name = adapter->FriendlyName;
    }
  }

  bool connected = !kinds.empty();
  EncodableValue internet;
  bool metered = false;
  bool roaming = false;
  bool constrained = false;
  ComPtr<INetworkListManager> nlm;
  if (SUCCEEDED(CoCreateInstance(CLSID_NetworkListManager, nullptr, CLSCTX_ALL, IID_PPV_ARGS(&nlm)))) {
    NLM_CONNECTIVITY connectivity = NLM_CONNECTIVITY_DISCONNECTED;
    if (SUCCEEDED(nlm->GetConnectivity(&connectivity))) {
      connected = connectivity != NLM_CONNECTIVITY_DISCONNECTED && !kinds.empty();
      // NCSI's own internet probe (msftconnecttest.com).
      internet = EncodableValue((connectivity & (NLM_CONNECTIVITY_IPV4_INTERNET | NLM_CONNECTIVITY_IPV6_INTERNET)) != 0);
    }
    ComPtr<INetworkCostManager> costs;
    DWORD cost = 0;
    if (SUCCEEDED(nlm.As(&costs)) && SUCCEEDED(costs->GetCost(&cost, nullptr))) {
      metered = (cost & (NLM_CONNECTION_COST_FIXED | NLM_CONNECTION_COST_VARIABLE)) != 0;
      roaming = (cost & NLM_CONNECTION_COST_ROAMING) != 0;
      constrained = (cost & (NLM_CONNECTION_COST_OVERDATALIMIT | NLM_CONNECTION_COST_APPROACHINGDATALIMIT)) != 0;
    }
  }
  if (kinds.count("cellular") > 0) metered = true;

  EncodableList types;
  if (connected) {
    for (const std::string& kind : kinds) types.push_back(EncodableValue(kind));
  }
  return EncodableMap{
      {EncodableValue("types"), EncodableValue(types)},
      {EncodableValue("connected"), EncodableValue(connected)},
      {EncodableValue("internet"), connected ? internet : EncodableValue(false)},
      {EncodableValue("metered"), EncodableValue(metered)},
      {EncodableValue("roaming"), EncodableValue(roaming)},
      {EncodableValue("constrained"), EncodableValue(constrained)},
      {EncodableValue("interface"), Text(interface_name)},
  };
}

EncodableMap Status() {
  EncodableMap out;
  SYSTEM_POWER_STATUS power = {};
  if (GetSystemPowerStatus(&power)) {
    const bool no_battery = (power.BatteryFlag & 128) != 0;
    if (no_battery) {
      out[EncodableValue("batteryState")] = EncodableValue("none");
    } else {
      if (power.BatteryLifePercent <= 100) out[EncodableValue("battery")] = EncodableValue(static_cast<int32_t>(power.BatteryLifePercent));
      std::string state = "unknown";
      if ((power.BatteryFlag & 8) != 0) {
        state = "charging";
      } else if (power.ACLineStatus == 1) {
        state = power.BatteryLifePercent == 100 ? "full" : "notCharging";
      } else if (power.ACLineStatus == 0) {
        state = "discharging";
      }
      out[EncodableValue("batteryState")] = EncodableValue(state);
    }
    out[EncodableValue("powerSave")] = EncodableValue(power.SystemStatusFlag == 1);
  }
  MEMORYSTATUSEX memory = {};
  memory.dwLength = sizeof(memory);
  if (GlobalMemoryStatusEx(&memory)) {
    out[EncodableValue("memFree")] = EncodableValue(static_cast<int64_t>(memory.ullAvailPhys));
    out[EncodableValue("memTotal")] = EncodableValue(static_cast<int64_t>(memory.ullTotalPhys));
  }
  PWSTR folder = nullptr;
  if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr, &folder))) {
    ULARGE_INTEGER free_bytes = {};
    ULARGE_INTEGER total_bytes = {};
    if (GetDiskFreeSpaceExW(folder, &free_bytes, &total_bytes, nullptr)) {
      out[EncodableValue("diskFree")] = EncodableValue(static_cast<int64_t>(free_bytes.QuadPart));
      out[EncodableValue("diskTotal")] = EncodableValue(static_cast<int64_t>(total_bytes.QuadPart));
    }
  }
  CoTaskMemFree(folder);
  out[EncodableValue("uptimeMs")] = EncodableValue(static_cast<int64_t>(GetTickCount64()));
  out[EncodableValue("thermal")] = EncodableValue("unknown");
  return out;
}

EncodableMap Integrity() {
  EncodableList reasons;
  BOOL remote = FALSE;
  CheckRemoteDebuggerPresent(GetCurrentProcess(), &remote);
  const bool debugger = IsDebuggerPresent() || remote;
  if (debugger) reasons.push_back(EncodableValue("debugger attached"));

  bool hooked = false;
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, GetCurrentProcessId());
  if (snapshot != INVALID_HANDLE_VALUE) {
    MODULEENTRY32W module = {};
    module.dwSize = sizeof(module);
    for (BOOL more = Module32FirstW(snapshot, &module); more; more = Module32NextW(snapshot, &module)) {
      if (Contains(Lower(module.szModule), L"frida")) {
        hooked = true;
        reasons.push_back(EncodableValue("frida module " + Narrow(module.szModule)));
        break;
      }
    }
    CloseHandle(snapshot);
  }

  const std::vector<std::string> vm = VirtualMachineReasons();
  for (const std::string& reason : vm) reasons.push_back(EncodableValue(reason));
  return EncodableMap{
      {EncodableValue("debugger"), EncodableValue(debugger)},
      {EncodableValue("hooked"), EncodableValue(hooked)},
      {EncodableValue("vm"), EncodableValue(!vm.empty())},
      {EncodableValue("reasons"), EncodableValue(reasons)},
  };
}

// --- change notifications ---------------------------------------------------

// IP Helper calls these on a thread-pool thread; hop to the platform thread.
void CALLBACK OnInterfaceChange(PVOID context, PMIB_IPINTERFACE_ROW, MIB_NOTIFICATION_TYPE) {
  PostMessageW(static_cast<HWND>(context), kNetworkChangedMessage, 0, 0);
}

void CALLBACK OnAddressChange(PVOID context, PMIB_UNICASTIPADDRESS_ROW, MIB_NOTIFICATION_TYPE) {
  PostMessageW(static_cast<HWND>(context), kNetworkChangedMessage, 0, 0);
}

LRESULT CALLBACK WindowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
  auto* device = reinterpret_cast<UDevice*>(GetWindowLongPtrW(window, GWLP_USERDATA));
  if (device != nullptr) {
    if (message == kNetworkChangedMessage) {
      // Interface + address + route events arrive in bursts: report once they settle.
      SetTimer(window, kDebounceTimer, 400, nullptr);
      return 0;
    }
    if (message == WM_TIMER && (wparam == kDebounceTimer || wparam == kRecheckTimer)) {
      KillTimer(window, wparam);
      device->OnNetworkChanged();
      // NCSI finishes its internet probe a few seconds after a link comes up, without any
      // IP change; look again so "internet" flips to true without waiting for the next event.
      if (wparam == kDebounceTimer) SetTimer(window, kRecheckTimer, 5000, nullptr);
      return 0;
    }
  }
  return DefWindowProcW(window, message, wparam, lparam);
}

HWND CreateMessageWindow(UDevice* owner) {
  static bool registered = false;
  HINSTANCE instance = GetModuleHandleW(nullptr);
  if (!registered) {
    WNDCLASSEXW descriptor = {};
    descriptor.cbSize = sizeof(descriptor);
    descriptor.lpfnWndProc = WindowProc;
    descriptor.hInstance = instance;
    descriptor.lpszClassName = kWindowClass;
    RegisterClassExW(&descriptor);
    registered = true;
  }
  HWND window = CreateWindowExW(0, kWindowClass, L"", 0, 0, 0, 0, 0, HWND_MESSAGE, nullptr, instance, nullptr);
  if (window != nullptr) SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(owner));
  return window;
}

}  // namespace

void UDevice::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
  // Kept alive for the app's lifetime, like the other feature handlers.
  auto* device = new UDevice(registrar);
  (void)device;
}

UDevice::UDevice(flutter::PluginRegistrarWindows* registrar) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(registrar->messenger(), "u/device", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) { HandleMethodCall(call, std::move(result)); });

  events_ = std::make_unique<flutter::EventChannel<EncodableValue>>(registrar->messenger(), "u/device/network", &flutter::StandardMethodCodec::GetInstance());
  events_->SetStreamHandler(std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
      [this](const EncodableValue*, std::unique_ptr<flutter::EventSink<EncodableValue>>&& events)
          -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
        sink_ = std::move(events);
        StartWatching();
        OnNetworkChanged();
        return nullptr;
      },
      [this](const EncodableValue*) -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
        StopWatching();
        sink_.reset();
        return nullptr;
      }));
}

UDevice::~UDevice() {
  StopWatching();
  if (window_ != nullptr) DestroyWindow(static_cast<HWND>(window_));
}

void UDevice::StartWatching() {
  if (window_ == nullptr) window_ = CreateMessageWindow(this);
  if (window_ == nullptr) return;
  HANDLE handle = nullptr;
  if (interface_notify_ == nullptr && NotifyIpInterfaceChange(AF_UNSPEC, OnInterfaceChange, window_, FALSE, &handle) == NO_ERROR) interface_notify_ = handle;
  handle = nullptr;
  if (address_notify_ == nullptr && NotifyUnicastIpAddressChange(AF_UNSPEC, OnAddressChange, window_, FALSE, &handle) == NO_ERROR) address_notify_ = handle;
}

void UDevice::StopWatching() {
  // CancelMibChangeNotify2 waits for running callbacks, so none can post after this.
  if (interface_notify_ != nullptr) CancelMibChangeNotify2(static_cast<HANDLE>(interface_notify_));
  if (address_notify_ != nullptr) CancelMibChangeNotify2(static_cast<HANDLE>(address_notify_));
  interface_notify_ = nullptr;
  address_notify_ = nullptr;
  if (window_ != nullptr) {
    KillTimer(static_cast<HWND>(window_), kDebounceTimer);
    KillTimer(static_cast<HWND>(window_), kRecheckTimer);
  }
}

void UDevice::OnNetworkChanged() {
  if (sink_) sink_->Success(EncodableValue(NetworkSnapshot()));
}

void UDevice::HandleMethodCall(const flutter::MethodCall<EncodableValue>& call, std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const std::string& method = call.method_name();
  if (method == "bootstrap") {
    result->Success(EncodableValue(EncodableMap{
        {EncodableValue("device"), EncodableValue(DeviceInfo())},
        {EncodableValue("package"), EncodableValue(PackageInfo())},
        {EncodableValue("network"), EncodableValue(NetworkSnapshot())},
    }));
  } else if (method == "network") {
    result->Success(EncodableValue(NetworkSnapshot()));
  } else if (method == "status") {
    result->Success(EncodableValue(Status()));
  } else if (method == "integrity") {
    result->Success(EncodableValue(Integrity()));
  } else {
    result->NotImplemented();
  }
}

}  // namespace u
