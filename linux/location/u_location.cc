#include "u_location.h"

#include <gio/gio.h>

#include <cstring>
#include <string>

namespace {

constexpr const char* kService = "org.freedesktop.GeoClue2";
constexpr const char* kManagerPath = "/org/freedesktop/GeoClue2/Manager";
constexpr const char* kManager = "org.freedesktop.GeoClue2.Manager";
constexpr const char* kClient = "org.freedesktop.GeoClue2.Client";
constexpr const char* kLocation = "org.freedesktop.GeoClue2.Location";
constexpr const char* kProperties = "org.freedesktop.DBus.Properties";

FlMethodChannel* g_channel = nullptr;
FlEventChannel* g_updates = nullptr;
FlEventChannel* g_heading = nullptr;
FlEventChannel* g_geofence = nullptr;
FlEventChannel* g_visits = nullptr;

// One GeoClue client: a one-shot request (call != nullptr) or the live stream (call == nullptr).
struct Session {
  GDBusConnection* bus = nullptr;
  std::string path;
  guint subscription = 0;
  guint timeout = 0;
  FlMethodCall* call = nullptr;
  guint accuracy = 6;
  guint distance = 0;
  bool done = false;
  // Async D-Bus calls still in flight; the session is freed only when this reaches 0 after Stop.
  int pending = 0;
  bool stopped = false;
};

Session* g_stream = nullptr;

const gchar* StringArg(FlValue* args, const char* key) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) return nullptr;
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING ? fl_value_get_string(value) : nullptr;
}

double NumberArg(FlValue* args, const char* key, double fallback) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) return fallback;
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr) return fallback;
  if (fl_value_get_type(value) == FL_VALUE_TYPE_INT) return static_cast<double>(fl_value_get_int(value));
  if (fl_value_get_type(value) == FL_VALUE_TYPE_FLOAT) return fl_value_get_float(value);
  return fallback;
}

// GeoClue accuracy levels: 1 country, 4 city, 5 neighbourhood, 6 street, 8 exact.
guint AccuracyLevel(const gchar* accuracy) {
  if (accuracy == nullptr) return 6;
  if (strcmp(accuracy, "lowest") == 0) return 1;
  if (strcmp(accuracy, "low") == 0) return 4;
  if (strcmp(accuracy, "balanced") == 0) return 5;
  if (strcmp(accuracy, "best") == 0 || strcmp(accuracy, "navigation") == 0) return 8;
  return 6;
}

std::string DesktopId() {
  GApplication* app = g_application_get_default();
  const gchar* id = app != nullptr ? g_application_get_application_id(app) : nullptr;
  if (id != nullptr) return id;
  const gchar* name = g_get_prgname();
  return name != nullptr ? name : "flutter-app";
}

std::string ErrorCode(GError* error) {
  if (error == nullptr) return "unavailable";
  if (g_error_matches(error, G_DBUS_ERROR, G_DBUS_ERROR_ACCESS_DENIED)) return "permissionDenied";
  if (g_error_matches(error, G_DBUS_ERROR, G_DBUS_ERROR_SERVICE_UNKNOWN) || g_error_matches(error, G_DBUS_ERROR, G_DBUS_ERROR_NAME_HAS_NO_OWNER)) return "unsupported";
  return "unavailable";
}

void RespondError(FlMethodCall* call, const std::string& code) {
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_error_response_new(code.c_str(), nullptr, nullptr));
  fl_method_call_respond(call, response, nullptr);
}

void Respond(FlMethodCall* call, FlValue* value) {
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  fl_value_unref(value);
  fl_method_call_respond(call, response, nullptr);
}

// Reads a Location object into the map ULocation expects.
FlValue* ReadLocation(GDBusConnection* bus, const gchar* path) {
  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(bus, kService, path, kProperties, "GetAll", g_variant_new("(s)", kLocation), G_VARIANT_TYPE("(a{sv})"),
                                                          G_DBUS_CALL_FLAGS_NONE, 2000, nullptr, nullptr);
  if (reply == nullptr) return nullptr;
  g_autoptr(GVariant) props = g_variant_get_child_value(reply, 0);
  FlValue* map = fl_value_new_map();
  double value = 0;
  if (g_variant_lookup(props, "Latitude", "d", &value)) fl_value_set_string_take(map, "latitude", fl_value_new_float(value));
  if (g_variant_lookup(props, "Longitude", "d", &value)) fl_value_set_string_take(map, "longitude", fl_value_new_float(value));
  if (g_variant_lookup(props, "Accuracy", "d", &value)) fl_value_set_string_take(map, "accuracy", fl_value_new_float(value));
  // GeoClue marks unknown altitude with -DBL_MAX and unknown speed / heading with a negative value.
  if (g_variant_lookup(props, "Altitude", "d", &value) && value > -1e300) fl_value_set_string_take(map, "altitude", fl_value_new_float(value));
  if (g_variant_lookup(props, "Speed", "d", &value) && value >= 0) fl_value_set_string_take(map, "speed", fl_value_new_float(value));
  if (g_variant_lookup(props, "Heading", "d", &value) && value >= 0) fl_value_set_string_take(map, "heading", fl_value_new_float(value));
  guint64 seconds = 0;
  guint64 micros = 0;
  if (g_variant_lookup(props, "Timestamp", "(tt)", &seconds, &micros)) {
    fl_value_set_string_take(map, "time", fl_value_new_int(static_cast<int64_t>(seconds * 1000 + micros / 1000)));
  } else {
    fl_value_set_string_take(map, "time", fl_value_new_int(g_get_real_time() / 1000));
  }
  fl_value_set_string_take(map, "source", fl_value_new_string("geoclue"));
  if (fl_value_lookup_string(map, "latitude") == nullptr || fl_value_lookup_string(map, "longitude") == nullptr) {
    fl_value_unref(map);
    return nullptr;
  }
  return map;
}

void Release(Session* session) {
  if (!session->stopped || session->pending > 0) return;
  if (session->bus != nullptr) g_object_unref(session->bus);
  delete session;
}

void StopSession(Session* session) {
  if (session == nullptr || session->stopped) return;
  session->stopped = true;
  if (session->timeout != 0) g_source_remove(session->timeout);
  session->timeout = 0;
  if (session->bus != nullptr) {
    if (session->subscription != 0) g_dbus_connection_signal_unsubscribe(session->bus, session->subscription);
    session->subscription = 0;
    if (!session->path.empty()) {
      g_dbus_connection_call(session->bus, kService, session->path.c_str(), kClient, "Stop", nullptr, nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr, nullptr, nullptr);
    }
  }
  if (session->call != nullptr) g_object_unref(session->call);
  session->call = nullptr;
  Release(session);
}

// A one-shot session ends at its first answer; the stream only when Dart cancels.
void Finish(Session* session, FlValue* position, const std::string& error) {
  if (session->done || session->stopped) {
    if (position != nullptr) fl_value_unref(position);
    return;
  }
  if (session->call == nullptr) {
    if (position != nullptr) {
      fl_event_channel_send(g_updates, position, nullptr, nullptr);
      fl_value_unref(position);
    } else {
      fl_event_channel_send_error(g_updates, error.c_str(), nullptr, nullptr, nullptr, nullptr);
    }
    return;
  }
  session->done = true;
  if (position != nullptr) {
    Respond(session->call, position);
  } else {
    RespondError(session->call, error);
  }
  StopSession(session);
}

void OnLocationUpdated(GDBusConnection* bus, const gchar*, const gchar*, const gchar*, const gchar*, GVariant* parameters, gpointer data) {
  auto* session = static_cast<Session*>(data);
  const gchar* next = nullptr;
  g_variant_get(parameters, "(&o&o)", nullptr, &next);
  FlValue* position = next != nullptr ? ReadLocation(bus, next) : nullptr;
  if (position != nullptr) Finish(session, position, "");
}

void OnStarted(GObject* source, GAsyncResult* result, gpointer data) {
  auto* session = static_cast<Session*>(data);
  session->pending--;
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) reply = g_dbus_connection_call_finish(G_DBUS_CONNECTION(source), result, &error);
  if (session->stopped) return Release(session);
  if (reply == nullptr) Finish(session, nullptr, ErrorCode(error));
}

void SetProperty(Session* session, const char* name, GVariant* value) {
  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(session->bus, kService, session->path.c_str(), kProperties, "Set", g_variant_new("(ssv)", kClient, name, value), nullptr,
                                                          G_DBUS_CALL_FLAGS_NONE, 2000, nullptr, nullptr);
}

void OnClient(GObject* source, GAsyncResult* result, gpointer data) {
  auto* session = static_cast<Session*>(data);
  session->pending--;
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) reply = g_dbus_connection_call_finish(G_DBUS_CONNECTION(source), result, &error);
  if (session->stopped) return Release(session);
  if (reply == nullptr) return Finish(session, nullptr, ErrorCode(error));
  const gchar* path = nullptr;
  g_variant_get(reply, "(&o)", &path);
  session->path = path != nullptr ? path : "";
  // GeoClue refuses to start without a desktop id.
  SetProperty(session, "DesktopId", g_variant_new_string(DesktopId().c_str()));
  SetProperty(session, "RequestedAccuracyLevel", g_variant_new_uint32(session->accuracy));
  if (session->distance > 0) SetProperty(session, "DistanceThreshold", g_variant_new_uint32(session->distance));
  session->subscription = g_dbus_connection_signal_subscribe(session->bus, kService, kClient, "LocationUpdated", session->path.c_str(), nullptr, G_DBUS_SIGNAL_FLAGS_NONE,
                                                             OnLocationUpdated, session, nullptr);
  session->pending++;
  g_dbus_connection_call(session->bus, kService, session->path.c_str(), kClient, "Start", nullptr, nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr, OnStarted, session);
}

gboolean OnTimeout(gpointer data) {
  auto* session = static_cast<Session*>(data);
  session->timeout = 0;
  Finish(session, nullptr, "timeout");
  return G_SOURCE_REMOVE;
}

Session* StartSession(FlMethodCall* call, guint accuracy, guint distance, guint timeout_ms, std::string* error) {
  g_autoptr(GError) bus_error = nullptr;
  GDBusConnection* bus = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, &bus_error);
  if (bus == nullptr) {
    *error = "unsupported";
    return nullptr;
  }
  auto* session = new Session();
  session->bus = bus;
  session->accuracy = accuracy;
  session->distance = distance;
  if (call != nullptr) session->call = FL_METHOD_CALL(g_object_ref(call));
  if (timeout_ms > 0) session->timeout = g_timeout_add(timeout_ms, OnTimeout, session);
  session->pending++;
  g_dbus_connection_call(bus, kService, kManagerPath, kManager, "GetClient", nullptr, G_VARIANT_TYPE("(o)"), G_DBUS_CALL_FLAGS_NONE, -1, nullptr, OnClient, session);
  return session;
}

// The manager's AvailableAccuracyLevel is 0 when location is switched off in privacy settings.
FlValue* Permission() {
  FlValue* map = fl_value_new_map();
  g_autoptr(GDBusConnection) bus = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, nullptr);
  g_autoptr(GVariant) reply = bus == nullptr ? nullptr
                                             : g_dbus_connection_call_sync(bus, kService, kManagerPath, kProperties, "Get", g_variant_new("(ss)", kManager, "AvailableAccuracyLevel"),
                                                                           G_VARIANT_TYPE("(v)"), G_DBUS_CALL_FLAGS_NONE, 2000, nullptr, nullptr);
  if (reply == nullptr) {
    fl_value_set_string_take(map, "status", fl_value_new_string("unsupported"));
    fl_value_set_string_take(map, "serviceEnabled", fl_value_new_bool(FALSE));
    return map;
  }
  g_autoptr(GVariant) boxed = g_variant_get_child_value(reply, 0);
  g_autoptr(GVariant) level = g_variant_get_variant(boxed);
  const guint available = g_variant_is_of_type(level, G_VARIANT_TYPE_UINT32) ? g_variant_get_uint32(level) : 0;
  // Per-app consent is asked by the desktop's agent when a client starts.
  fl_value_set_string_take(map, "status", fl_value_new_string("whileInUse"));
  fl_value_set_string_take(map, "precise", fl_value_new_bool(available >= 8));
  fl_value_set_string_take(map, "serviceEnabled", fl_value_new_bool(available > 0));
  return map;
}

void HandleMethodCall(FlMethodChannel*, FlMethodCall* call, gpointer) {
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  if (strcmp(method, "permission") == 0 || strcmp(method, "requestPermission") == 0) {
    Respond(call, Permission());
  } else if (strcmp(method, "current") == 0) {
    std::string error;
    const guint timeout = static_cast<guint>(NumberArg(args, "timeoutMs", 20000));
    if (StartSession(call, AccuracyLevel(StringArg(args, "accuracy")), 0, timeout, &error) == nullptr) RespondError(call, error);
  } else if (strcmp(method, "lastKnown") == 0) {
    Respond(call, fl_value_new_null());
  } else if (strcmp(method, "requestPrecise") == 0 || strcmp(method, "geocodingAvailable") == 0) {
    Respond(call, fl_value_new_bool(FALSE));
  } else if (strcmp(method, "reverseGeocode") == 0 || strcmp(method, "geocode") == 0) {
    Respond(call, fl_value_new_list());
  } else {
    // Geofences: Dart evaluates them against the position stream.
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(call, response, nullptr);
  }
}

FlMethodErrorResponse* OnUpdatesListen(FlEventChannel*, FlValue* args, gpointer) {
  StopSession(g_stream);
  std::string error;
  g_stream = StartSession(nullptr, AccuracyLevel(StringArg(args, "accuracy")), static_cast<guint>(NumberArg(args, "distanceFilter", 0)), 0, &error);
  return g_stream == nullptr ? fl_method_error_response_new(error.c_str(), "GeoClue is not available", nullptr) : nullptr;
}

FlMethodErrorResponse* OnUpdatesCancel(FlEventChannel*, FlValue*, gpointer) {
  StopSession(g_stream);
  g_stream = nullptr;
  return nullptr;
}

FlMethodErrorResponse* Unsupported(FlEventChannel*, FlValue*, gpointer) { return fl_method_error_response_new("unsupported", "Not available on Linux", nullptr); }

FlMethodErrorResponse* Nothing(FlEventChannel*, FlValue*, gpointer) { return nullptr; }

}  // namespace

void u_location_register(FlPluginRegistrar* registrar) {
  if (g_channel != nullptr) return;
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_channel = fl_method_channel_new(messenger, "u/location", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(g_channel, HandleMethodCall, nullptr, nullptr);
  g_updates = fl_event_channel_new(messenger, "u/location/updates", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(g_updates, OnUpdatesListen, OnUpdatesCancel, nullptr, nullptr);
  g_heading = fl_event_channel_new(messenger, "u/location/heading", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(g_heading, Unsupported, Nothing, nullptr, nullptr);
  g_geofence = fl_event_channel_new(messenger, "u/location/geofence", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(g_geofence, Nothing, Nothing, nullptr, nullptr);
  g_visits = fl_event_channel_new(messenger, "u/location/visits", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(g_visits, Nothing, Nothing, nullptr, nullptr);
}
