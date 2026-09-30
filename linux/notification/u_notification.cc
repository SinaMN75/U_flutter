#include "u_notification.h"

#include <gio/gio.h>

#include <cstring>
#include <map>
#include <set>
#include <string>
#include <vector>

namespace {

constexpr const char* kService = "org.freedesktop.Notifications";
constexpr const char* kPath = "/org/freedesktop/Notifications";
constexpr const char* kInterface = "org.freedesktop.Notifications";

struct Shown {
  int64_t id = 0;
  std::string payload;
  std::string group;
  std::string title;
  std::string body;
  std::string reply_action;
};

struct Notifications {
  GDBusConnection* bus = nullptr;
  FlMethodChannel* channel = nullptr;
  FlEventChannel* events = nullptr;
  bool listening = false;
  std::vector<FlValue*> queued;
  std::set<std::string> capabilities;
  std::map<guint32, Shown> by_server;
  std::map<int64_t, guint32> by_id;
};

Notifications* g_notify = nullptr;

// --- arguments -------------------------------------------------------------------

FlValue* Lookup(FlValue* map, const char* key) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) return nullptr;
  return fl_value_lookup_string(map, key);
}

std::string Str(FlValue* map, const char* key) {
  FlValue* value = Lookup(map, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING ? fl_value_get_string(value) : "";
}

bool Bool(FlValue* map, const char* key) {
  FlValue* value = Lookup(map, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL && fl_value_get_bool(value);
}

int64_t Int(FlValue* map, const char* key, int64_t fallback) {
  FlValue* value = Lookup(map, key);
  if (value == nullptr) return fallback;
  if (fl_value_get_type(value) == FL_VALUE_TYPE_INT) return fl_value_get_int(value);
  if (fl_value_get_type(value) == FL_VALUE_TYPE_FLOAT) return static_cast<int64_t>(fl_value_get_float(value));
  return fallback;
}

std::string AppId() {
  GApplication* app = g_application_get_default();
  const gchar* id = app != nullptr ? g_application_get_application_id(app) : nullptr;
  if (id != nullptr) return id;
  const gchar* name = g_get_prgname();
  return name != nullptr ? name : "flutter-app";
}

// --- events ---------------------------------------------------------------------------

void Emit(const char* type, const Shown& shown, const std::string& action, const std::string& input) {
  FlValue* event = fl_value_new_map();
  fl_value_set_string_take(event, "type", fl_value_new_string(type));
  fl_value_set_string_take(event, "id", fl_value_new_int(shown.id));
  if (!action.empty()) fl_value_set_string_take(event, "actionId", fl_value_new_string(action.c_str()));
  if (!input.empty()) fl_value_set_string_take(event, "input", fl_value_new_string(input.c_str()));
  if (!shown.payload.empty()) fl_value_set_string_take(event, "payload", fl_value_new_string(shown.payload.c_str()));
  if (g_notify->listening) {
    fl_event_channel_send(g_notify->events, event, nullptr, nullptr);
    fl_value_unref(event);
  } else {
    g_notify->queued.push_back(event);
  }
}

void Forget(guint32 server) {
  const auto it = g_notify->by_server.find(server);
  if (it == g_notify->by_server.end()) return;
  const auto current = g_notify->by_id.find(it->second.id);
  if (current != g_notify->by_id.end() && current->second == server) g_notify->by_id.erase(current);
  g_notify->by_server.erase(it);
}

void OnSignal(GDBusConnection*, const gchar*, const gchar*, const gchar*, const gchar* signal, GVariant* parameters, gpointer) {
  if (strcmp(signal, "ActionInvoked") == 0) {
    guint32 server = 0;
    const gchar* key = nullptr;
    g_variant_get(parameters, "(u&s)", &server, &key);
    const auto it = g_notify->by_server.find(server);
    if (it == g_notify->by_server.end() || key == nullptr) return;
    if (strcmp(key, "default") == 0) {
      Emit("tap", it->second, "", "");
    } else if (strcmp(key, "inline-reply") != 0) {
      Emit("action", it->second, key, "");
    }
  } else if (strcmp(signal, "NotificationReplied") == 0) {
    guint32 server = 0;
    const gchar* text = nullptr;
    g_variant_get(parameters, "(u&s)", &server, &text);
    const auto it = g_notify->by_server.find(server);
    if (it != g_notify->by_server.end()) Emit("reply", it->second, it->second.reply_action, text != nullptr ? text : "");
  } else if (strcmp(signal, "NotificationClosed") == 0) {
    guint32 server = 0;
    guint32 reason = 0;
    g_variant_get(parameters, "(uu)", &server, &reason);
    const auto it = g_notify->by_server.find(server);
    // Reason 2: dismissed by the user.
    if (it != g_notify->by_server.end() && reason == 2) Emit("dismiss", it->second, "", "");
    Forget(server);
  }
}

// --- showing -----------------------------------------------------------------------------

struct PendingShow {
  FlMethodCall* call;
  Shown shown;
};

void OnNotified(GObject* source, GAsyncResult* result, gpointer data) {
  auto* pending = static_cast<PendingShow*>(data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) reply = g_dbus_connection_call_finish(G_DBUS_CONNECTION(source), result, &error);
  bool ok = false;
  if (reply != nullptr) {
    guint32 server = 0;
    g_variant_get(reply, "(u)", &server);
    const auto previous = g_notify->by_id.find(pending->shown.id);
    if (previous != g_notify->by_id.end() && previous->second != server) g_notify->by_server.erase(previous->second);
    g_notify->by_server[server] = pending->shown;
    g_notify->by_id[pending->shown.id] = server;
    ok = true;
  }
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(ok)));
  fl_method_call_respond(pending->call, response, nullptr);
  g_object_unref(pending->call);
  delete pending;
}

void Show(FlMethodCall* call, FlValue* r) {
  if (g_notify->bus == nullptr) {
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(FALSE)));
    fl_method_call_respond(call, response, nullptr);
    return;
  }
  Shown shown;
  shown.id = Int(r, "id", 0);
  shown.payload = Str(r, "payload");
  shown.group = Str(r, "group");
  shown.title = Str(r, "title");
  shown.body = Str(r, "body");
  std::string body = shown.body;
  FlValue* lines = Lookup(r, "lines");
  if (lines != nullptr && fl_value_get_type(lines) == FL_VALUE_TYPE_LIST) {
    for (size_t i = 0; i < fl_value_get_length(lines); i++) {
      FlValue* line = fl_value_get_list_value(lines, i);
      if (fl_value_get_type(line) == FL_VALUE_TYPE_STRING) body += (body.empty() ? "" : "\n") + std::string(fl_value_get_string(line));
    }
  }
  if (!Str(r, "subtitle").empty()) body = Str(r, "subtitle") + "\n" + body;

  GVariantBuilder actions;
  g_variant_builder_init(&actions, G_VARIANT_TYPE("as"));
  g_variant_builder_add(&actions, "s", "default");
  g_variant_builder_add(&actions, "s", "Open");
  const bool inline_reply = g_notify->capabilities.count("inline-reply") > 0;
  std::string reply_placeholder;
  FlValue* list = Lookup(r, "actions");
  if (list != nullptr && fl_value_get_type(list) == FL_VALUE_TYPE_LIST) {
    for (size_t i = 0; i < fl_value_get_length(list); i++) {
      FlValue* action = fl_value_get_list_value(list, i);
      const std::string id = Str(action, "id");
      const std::string title = Str(action, "title");
      if (Bool(action, "input")) {
        if (!inline_reply || !shown.reply_action.empty()) continue;
        // KDE's inline reply: the server shows a text field and sends NotificationReplied.
        shown.reply_action = id;
        reply_placeholder = Str(action, "inputPlaceholder");
        g_variant_builder_add(&actions, "s", "inline-reply");
        g_variant_builder_add(&actions, "s", title.c_str());
      } else {
        g_variant_builder_add(&actions, "s", id.c_str());
        g_variant_builder_add(&actions, "s", title.c_str());
      }
    }
  }

  GVariantBuilder hints;
  g_variant_builder_init(&hints, G_VARIANT_TYPE("a{sv}"));
  const std::string importance = Str(r, "importance");
  const guchar urgency = importance == "min" || importance == "low" ? 0 : (importance == "normal" ? 1 : 2);
  g_variant_builder_add(&hints, "{sv}", "urgency", g_variant_new_byte(urgency));
  g_variant_builder_add(&hints, "{sv}", "desktop-entry", g_variant_new_string(AppId().c_str()));
  if (!Str(r, "category").empty()) g_variant_builder_add(&hints, "{sv}", "category", g_variant_new_string(Str(r, "category").c_str()));
  const std::string image = !Str(r, "image").empty() ? Str(r, "image") : Str(r, "largeIcon");
  if (!image.empty()) g_variant_builder_add(&hints, "{sv}", "image-path", g_variant_new_string(image.c_str()));
  if (Bool(r, "silent")) g_variant_builder_add(&hints, "{sv}", "suppress-sound", g_variant_new_boolean(TRUE));
  if (!Str(r, "sound").empty()) g_variant_builder_add(&hints, "{sv}", "sound-name", g_variant_new_string(Str(r, "sound").c_str()));
  if (Bool(r, "ongoing")) g_variant_builder_add(&hints, "{sv}", "resident", g_variant_new_boolean(TRUE));
  if (!reply_placeholder.empty()) g_variant_builder_add(&hints, "{sv}", "x-kde-reply-placeholder-text", g_variant_new_string(reply_placeholder.c_str()));
  FlValue* progress = Lookup(r, "progress");
  if (progress != nullptr && fl_value_get_type(progress) == FL_VALUE_TYPE_MAP && !Bool(progress, "indeterminate")) {
    const int64_t max = Int(progress, "max", 100);
    const int32_t percent = static_cast<int32_t>(max > 0 ? Int(progress, "value", 0) * 100 / max : 0);
    g_variant_builder_add(&hints, "{sv}", "value", g_variant_new_int32(percent));
  }

  const auto previous = g_notify->by_id.find(shown.id);
  const guint32 replaces = previous == g_notify->by_id.end() ? 0 : previous->second;
  const int64_t timeout = Int(r, "timeoutMs", -1);
  const gchar* app_name = g_get_application_name();
  auto* pending = new PendingShow{FL_METHOD_CALL(g_object_ref(call)), shown};
  g_dbus_connection_call(g_notify->bus, kService, kPath, kInterface, "Notify",
                         g_variant_new("(susssasa{sv}i)", app_name != nullptr ? app_name : AppId().c_str(), replaces, "", shown.title.c_str(), body.c_str(), &actions, &hints,
                                       static_cast<gint32>(timeout > 0 ? timeout : -1)),
                         G_VARIANT_TYPE("(u)"), G_DBUS_CALL_FLAGS_NONE, 5000, nullptr, OnNotified, pending);
}

void Close(guint32 server) {
  if (g_notify->bus == nullptr) return;
  g_dbus_connection_call(g_notify->bus, kService, kPath, kInterface, "CloseNotification", g_variant_new("(u)", server), nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr, nullptr, nullptr);
  Forget(server);
}

// Unity launcher entry: understood by GNOME's Dash to Dock / Ubuntu Dock, KDE Plasma and others.
bool SetBadge(int64_t count) {
  if (g_notify->bus == nullptr) return false;
  const std::string uri = "application://" + AppId() + ".desktop";
  const std::string path = "/com/canonical/unity/launcherentry/" + std::to_string(g_str_hash(uri.c_str()));
  GVariantBuilder props;
  g_variant_builder_init(&props, G_VARIANT_TYPE("a{sv}"));
  g_variant_builder_add(&props, "{sv}", "count", g_variant_new_int64(count));
  g_variant_builder_add(&props, "{sv}", "count-visible", g_variant_new_boolean(count > 0));
  return g_dbus_connection_emit_signal(g_notify->bus, nullptr, path.c_str(), "com.canonical.Unity.LauncherEntry", "Update", g_variant_new("(sa{sv})", uri.c_str(), &props), nullptr);
}

FlValue* Permission() {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "status", fl_value_new_string(g_notify->bus != nullptr && !g_notify->capabilities.empty() ? "granted" : "unsupported"));
  return map;
}

FlValue* Active() {
  FlValue* list = fl_value_new_list();
  for (const auto& entry : g_notify->by_server) {
    FlValue* item = fl_value_new_map();
    fl_value_set_string_take(item, "id", fl_value_new_int(entry.second.id));
    fl_value_set_string_take(item, "title", fl_value_new_string(entry.second.title.c_str()));
    fl_value_set_string_take(item, "body", fl_value_new_string(entry.second.body.c_str()));
    if (!entry.second.group.empty()) fl_value_set_string_take(item, "group", fl_value_new_string(entry.second.group.c_str()));
    fl_value_append_take(list, item);
  }
  return list;
}

void Respond(FlMethodCall* call, FlValue* value) {
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  fl_value_unref(value);
  fl_method_call_respond(call, response, nullptr);
}

void HandleMethodCall(FlMethodChannel*, FlMethodCall* call, gpointer) {
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  if (strcmp(method, "show") == 0) {
    Show(call, args);
  } else if (strcmp(method, "permission") == 0 || strcmp(method, "requestPermission") == 0) {
    Respond(call, Permission());
  } else if (strcmp(method, "cancel") == 0) {
    const auto it = g_notify->by_id.find(Int(args, "id", 0));
    if (it != g_notify->by_id.end()) Close(it->second);
    Respond(call, fl_value_new_null());
  } else if (strcmp(method, "cancelAll") == 0 || strcmp(method, "cancelGroup") == 0) {
    const std::string group = Str(args, "group");
    std::vector<guint32> close;
    for (const auto& entry : g_notify->by_server) {
      if (strcmp(method, "cancelAll") == 0 || entry.second.group == group) close.push_back(entry.first);
    }
    for (guint32 server : close) Close(server);
    Respond(call, fl_value_new_null());
  } else if (strcmp(method, "active") == 0) {
    Respond(call, Active());
  } else if (strcmp(method, "setBadge") == 0) {
    Respond(call, fl_value_new_bool(SetBadge(Int(args, "count", 0))));
  } else if (strcmp(method, "init") == 0 || strcmp(method, "createChannel") == 0 || strcmp(method, "deleteChannel") == 0 || strcmp(method, "createChannelGroup") == 0 ||
             strcmp(method, "launchEvent") == 0) {
    Respond(call, fl_value_new_null());
  } else if (strcmp(method, "channels") == 0) {
    Respond(call, fl_value_new_list());
  } else {
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(call, response, nullptr);
  }
}

FlMethodErrorResponse* OnListen(FlEventChannel*, FlValue*, gpointer) {
  g_notify->listening = true;
  for (FlValue* event : g_notify->queued) {
    fl_event_channel_send(g_notify->events, event, nullptr, nullptr);
    fl_value_unref(event);
  }
  g_notify->queued.clear();
  return nullptr;
}

FlMethodErrorResponse* OnCancel(FlEventChannel*, FlValue*, gpointer) {
  g_notify->listening = false;
  return nullptr;
}

}  // namespace

void u_notification_register(FlPluginRegistrar* registrar) {
  if (g_notify != nullptr) return;
  g_notify = new Notifications();
  g_notify->bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
  if (g_notify->bus != nullptr) {
    g_autoptr(GVariant) caps = g_dbus_connection_call_sync(g_notify->bus, kService, kPath, kInterface, "GetCapabilities", nullptr, G_VARIANT_TYPE("(as)"), G_DBUS_CALL_FLAGS_NONE, 1000,
                                                           nullptr, nullptr);
    if (caps != nullptr) {
      g_autoptr(GVariantIter) iter = nullptr;
      const gchar* cap = nullptr;
      g_variant_get(caps, "(as)", &iter);
      while (g_variant_iter_loop(iter, "&s", &cap)) g_notify->capabilities.insert(cap);
    }
    g_dbus_connection_signal_subscribe(g_notify->bus, kService, kInterface, nullptr, kPath, nullptr, G_DBUS_SIGNAL_FLAGS_NONE, OnSignal, nullptr, nullptr);
  }
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_notify->channel = fl_method_channel_new(messenger, "u/notify", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(g_notify->channel, HandleMethodCall, nullptr, nullptr);
  g_notify->events = fl_event_channel_new(messenger, "u/notify/events", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(g_notify->events, OnListen, OnCancel, nullptr, nullptr);
}
