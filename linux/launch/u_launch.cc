#include "u_launch.h"

#include <gio/gdesktopappinfo.h>
#include <gio/gio.h>

#include <cstring>
#include <string>
#include <vector>

namespace {

FlMethodChannel* g_launch_channel = nullptr;
FlEventChannel* g_launch_events = nullptr;
FlMethodChannel* g_share_channel = nullptr;
FlEventChannel* g_share_events = nullptr;

const gchar* StringArg(FlValue* args, const char* key) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) return nullptr;
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING ? fl_value_get_string(value) : nullptr;
}

std::vector<std::string> ListArg(FlValue* args, const char* key) {
  std::vector<std::string> out;
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) return out;
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_LIST) return out;
  for (size_t i = 0; i < fl_value_get_length(value); i++) {
    FlValue* item = fl_value_get_list_value(value, i);
    if (fl_value_get_type(item) == FL_VALUE_TYPE_STRING) out.emplace_back(fl_value_get_string(item));
  }
  return out;
}

// GIO picks the default handler and goes through the OpenURI portal inside Flatpak.
bool Open(const std::string& uri) {
  if (uri.empty()) return false;
  g_autoptr(GError) error = nullptr;
  return g_app_info_launch_default_for_uri(uri.c_str(), nullptr, &error);
}

std::string SchemeOf(const std::string& url) {
  const size_t colon = url.find(':');
  return colon == std::string::npos || colon < 2 ? std::string() : url.substr(0, colon);
}

bool HasHandler(const std::string& scheme) {
  if (scheme.empty()) return false;
  if (scheme == "http" || scheme == "https" || scheme == "file") return true;
  g_autoptr(GAppInfo) info = g_app_info_get_default_for_uri_scheme(scheme.c_str());
  return info != nullptr;
}

bool Spawn(const std::vector<std::string>& argv) {
  std::vector<gchar*> raw;
  for (const std::string& a : argv) raw.push_back(const_cast<gchar*>(a.c_str()));
  raw.push_back(nullptr);
  g_autoptr(GError) error = nullptr;
  return g_spawn_async(nullptr, raw.data(), nullptr, G_SPAWN_SEARCH_PATH, nullptr, nullptr, nullptr, &error);
}

bool OpenSettings(const std::string& page) {
  g_autofree gchar* gnome = g_find_program_in_path("gnome-control-center");
  if (gnome == nullptr) return false;
  const char* panel = "applications";
  if (page == "wifi") panel = "wifi";
  else if (page == "bluetooth") panel = "bluetooth";
  else if (page == "display") panel = "display";
  else if (page == "sound") panel = "sound";
  else if (page == "dateTime") panel = "datetime";
  else if (page == "language") panel = "region";
  else if (page == "notifications" || page == "notificationChannel") panel = "notifications";
  else if (page == "location") panel = "location";
  else if (page == "battery") panel = "power";
  else if (page == "dataUsage" || page == "vpn" || page == "airplaneMode") panel = "network";
  else if (page == "accessibility") panel = "universal-access";
  else if (page == "defaultApps") panel = "default-apps";
  else if (page == "security") panel = "privacy";
  return Spawn({gnome, panel});
}

// xdg-email handles attachments with most clients; plain mailto: otherwise.
std::string Email(FlValue* args) {
  g_autofree gchar* xdg = g_find_program_in_path("xdg-email");
  if (xdg != nullptr) {
    std::vector<std::string> argv = {xdg};
    for (const std::string& cc : ListArg(args, "cc")) argv.insert(argv.end(), {"--cc", cc});
    for (const std::string& bcc : ListArg(args, "bcc")) argv.insert(argv.end(), {"--bcc", bcc});
    if (const gchar* subject = StringArg(args, "subject")) argv.insert(argv.end(), {"--subject", subject});
    if (const gchar* body = StringArg(args, "body")) argv.insert(argv.end(), {"--body", body});
    for (const std::string& file : ListArg(args, "attachments")) argv.insert(argv.end(), {"--attach", file});
    for (const std::string& to : ListArg(args, "to")) argv.push_back(to);
    if (Spawn(argv)) return "opened";
  }
  const gchar* mailto = StringArg(args, "mailto");
  return mailto != nullptr && Open(mailto) ? "opened" : "unavailable";
}

// Arguments after the executable, read from /proc so no runner changes are needed.
std::vector<std::string> Arguments() {
  std::vector<std::string> out;
  g_autofree gchar* contents = nullptr;
  gsize length = 0;
  if (!g_file_get_contents("/proc/self/cmdline", &contents, &length, nullptr)) return out;
  size_t start = 0;
  bool first = true;
  for (size_t i = 0; i < length; i++) {
    if (contents[i] != '\0') continue;
    if (!first) out.emplace_back(contents + start, i - start);
    first = false;
    start = i + 1;
  }
  return out;
}

FlValue* InitialLink() {
  for (const std::string& arg : Arguments()) {
    if (!SchemeOf(arg).empty() && SchemeOf(arg) != "file" && !g_file_test(arg.c_str(), G_FILE_TEST_EXISTS)) return fl_value_new_string(arg.c_str());
  }
  return fl_value_new_null();
}

FlValue* InitialShare() {
  FlValue* files = fl_value_new_list();
  for (const std::string& arg : Arguments()) {
    std::string path = arg;
    if (arg.rfind("file://", 0) == 0) {
      g_autofree gchar* local = g_filename_from_uri(arg.c_str(), nullptr, nullptr);
      if (local == nullptr) continue;
      path = local;
    }
    if (!g_file_test(path.c_str(), G_FILE_TEST_IS_REGULAR)) continue;
    g_autofree gchar* name = g_path_get_basename(path.c_str());
    FlValue* file = fl_value_new_map();
    fl_value_set_string_take(file, "path", fl_value_new_string(path.c_str()));
    fl_value_set_string_take(file, "name", fl_value_new_string(name));
    fl_value_append_take(files, file);
  }
  if (fl_value_get_length(files) == 0) {
    fl_value_unref(files);
    return fl_value_new_null();
  }
  FlValue* share = fl_value_new_map();
  fl_value_set_string_take(share, "files", files);
  return share;
}

FlValue* Status(const char* status) {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "status", fl_value_new_string(status));
  return map;
}

void Respond(FlMethodCall* call, FlValue* value) {
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  fl_value_unref(value);
  fl_method_call_respond(call, response, nullptr);
}

void NotImplemented(FlMethodCall* call) {
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  fl_method_call_respond(call, response, nullptr);
}

void HandleLaunch(FlMethodChannel*, FlMethodCall* call, gpointer) {
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  const gchar* url = StringArg(args, "url");
  if (strcmp(method, "open") == 0) {
    Respond(call, fl_value_new_bool(url != nullptr && Open(url)));
  } else if (strcmp(method, "canOpen") == 0) {
    Respond(call, fl_value_new_bool(url != nullptr && HasHandler(SchemeOf(url))));
  } else if (strcmp(method, "isInstalled") == 0 || strcmp(method, "openApp") == 0) {
    const gchar* raw = StringArg(args, "id");
    const std::string id = raw ? raw : "";
    const bool launch = strcmp(method, "openApp") == 0;
    // A desktop-file id (org.gnome.Maps) or a URL scheme.
    GDesktopAppInfo* app = g_desktop_app_info_new((id + ".desktop").c_str());
    if (app != nullptr) {
      const bool ok = !launch || g_app_info_launch(G_APP_INFO(app), nullptr, nullptr, nullptr);
      g_object_unref(app);
      Respond(call, fl_value_new_bool(ok));
    } else {
      const std::string scheme = id.find(':') == std::string::npos ? id : SchemeOf(id);
      Respond(call, fl_value_new_bool(launch ? Open(scheme + ":") : HasHandler(scheme)));
    }
  } else if (strcmp(method, "openSettings") == 0) {
    const gchar* page = StringArg(args, "page");
    Respond(call, fl_value_new_bool(OpenSettings(page ? page : "app")));
  } else if (strcmp(method, "email") == 0) {
    Respond(call, fl_value_new_string(Email(args).c_str()));
  } else if (strcmp(method, "sms") == 0) {
    Respond(call, fl_value_new_string(url != nullptr && Open(url) ? "opened" : "unavailable"));
  } else if (strcmp(method, "openStore") == 0) {
    const gchar* store = StringArg(args, "store");
    const gchar* id = StringArg(args, "appId");
    GApplication* application = g_application_get_default();
    const gchar* own = application != nullptr ? g_application_get_application_id(application) : nullptr;
    const gchar* target = id != nullptr ? id : own;
    const bool allowed = store == nullptr || strcmp(store, "auto") == 0 || strcmp(store, "flathub") == 0;
    // appstream:// opens GNOME Software / KDE Discover on the app's page.
    Respond(call, fl_value_new_bool(allowed && target != nullptr && Open(std::string("appstream://") + target)));
  } else if (strcmp(method, "initialLink") == 0) {
    Respond(call, InitialLink());
  } else if (strcmp(method, "requestReview") == 0 || strcmp(method, "closeInApp") == 0) {
    Respond(call, fl_value_new_bool(FALSE));
  } else {
    NotImplemented(call);
  }
}

void HandleShare(FlMethodChannel*, FlMethodCall* call, gpointer) {
  const gchar* method = fl_method_call_get_name(call);
  if (strcmp(method, "share") == 0 || strcmp(method, "shareTo") == 0) {
    Respond(call, Status("unavailable"));
  } else if (strcmp(method, "canShareTo") == 0) {
    Respond(call, fl_value_new_bool(FALSE));
  } else if (strcmp(method, "initialShare") == 0) {
    Respond(call, InitialShare());
  } else {
    NotImplemented(call);
  }
}

FlMethodErrorResponse* NoStream(FlEventChannel*, FlValue*, gpointer) { return nullptr; }

}  // namespace

void u_launch_register(FlPluginRegistrar* registrar) {
  if (g_launch_channel != nullptr) return;
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_launch_channel = fl_method_channel_new(messenger, "u/launch", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(g_launch_channel, HandleLaunch, nullptr, nullptr);
  g_launch_events = fl_event_channel_new(messenger, "u/launch/events", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(g_launch_events, NoStream, NoStream, nullptr, nullptr);
  g_share_channel = fl_method_channel_new(messenger, "u/share", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(g_share_channel, HandleShare, nullptr, nullptr);
  g_share_events = fl_event_channel_new(messenger, "u/share/received", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(g_share_events, NoStream, NoStream, nullptr, nullptr);
}
