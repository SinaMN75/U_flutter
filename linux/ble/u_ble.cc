#include "u_ble.h"

#include <gio/gio.h>

#include <algorithm>
#include <cstring>
#include <iterator>
#include <map>
#include <string>
#include <vector>

namespace {

constexpr const char* kBluez = "org.bluez";
constexpr const char* kAdapter = "org.bluez.Adapter1";
constexpr const char* kDevice = "org.bluez.Device1";
constexpr const char* kService = "org.bluez.GattService1";
constexpr const char* kCharacteristic = "org.bluez.GattCharacteristic1";
constexpr const char* kProperties = "org.freedesktop.DBus.Properties";
constexpr const char* kObjectManager = "org.freedesktop.DBus.ObjectManager";

FlMethodChannel* g_channel = nullptr;
FlEventChannel* g_scan = nullptr;
FlEventChannel* g_events = nullptr;
GDBusConnection* g_bus = nullptr;
guint g_properties_subscription = 0;
guint g_added_subscription = 0;
bool g_scanning = false;
bool g_events_listening = false;
std::vector<std::string> g_scan_services;

struct PendingConnect {
  FlMethodCall* call = nullptr;
  guint timeout = 0;
};

struct Subscription {
  std::string id;
  std::string service;
  std::string characteristic;
};

std::map<std::string, PendingConnect> g_connecting;    // device path → call
std::map<std::string, std::string> g_connected;        // device path → id
std::map<std::string, Subscription> g_subscriptions;  // characteristic path → names

void RespondError(FlMethodCall* call, const std::string& code) {
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_error_response_new(code.c_str(), nullptr, nullptr));
  fl_method_call_respond(call, response, nullptr);
}

void Respond(FlMethodCall* call, FlValue* value) {
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  if (value != nullptr) fl_value_unref(value);
  fl_method_call_respond(call, response, nullptr);
}

const gchar* StringArg(FlValue* args, const char* key) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) return nullptr;
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING ? fl_value_get_string(value) : nullptr;
}

int64_t IntArg(FlValue* args, const char* key, int64_t fallback) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) return fallback;
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_INT ? fl_value_get_int(value) : fallback;
}

bool BoolArg(FlValue* args, const char* key, bool fallback) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) return fallback;
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL ? fl_value_get_bool(value) : fallback;
}

std::string Lower(std::string text) {
  std::transform(text.begin(), text.end(), text.begin(), [](unsigned char c) { return static_cast<char>(g_ascii_tolower(c)); });
  return text;
}

GDBusConnection* Bus() {
  if (g_bus == nullptr) g_bus = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, nullptr);
  return g_bus;
}

// a{oa{sa{sv}}} of everything BlueZ exposes, or nullptr when BlueZ is not running.
GVariant* ManagedObjects() {
  GDBusConnection* bus = Bus();
  if (bus == nullptr) return nullptr;
  GVariant* reply = g_dbus_connection_call_sync(bus, kBluez, "/", kObjectManager, "GetManagedObjects", nullptr, G_VARIANT_TYPE("(a{oa{sa{sv}}})"), G_DBUS_CALL_FLAGS_NONE, 3000,
                                                nullptr, nullptr);
  if (reply == nullptr) return nullptr;
  GVariant* objects = g_variant_get_child_value(reply, 0);
  g_variant_unref(reply);
  return objects;
}

// Calls [visit] with (path, interface, properties) for every interface of every object.
template <typename Visit>
void ForEachInterface(GVariant* objects, Visit visit) {
  GVariantIter objects_iter;
  g_variant_iter_init(&objects_iter, objects);
  const gchar* path = nullptr;
  GVariant* interfaces = nullptr;
  while (g_variant_iter_next(&objects_iter, "{&o@a{sa{sv}}}", &path, &interfaces)) {
    GVariantIter interfaces_iter;
    g_variant_iter_init(&interfaces_iter, interfaces);
    const gchar* name = nullptr;
    GVariant* properties = nullptr;
    while (g_variant_iter_next(&interfaces_iter, "{&s@a{sv}}", &name, &properties)) {
      visit(std::string(path), std::string(name), properties);
      g_variant_unref(properties);
    }
    g_variant_unref(interfaces);
  }
}

std::string AdapterPath() {
  g_autoptr(GVariant) objects = ManagedObjects();
  if (objects == nullptr) return "";
  std::string found;
  ForEachInterface(objects, [&found](const std::string& path, const std::string& name, GVariant*) {
    if (found.empty() && name == kAdapter) found = path;
  });
  return found;
}

std::string StateName() {
  const std::string adapter = AdapterPath();
  if (adapter.empty()) return "unsupported";
  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(Bus(), kBluez, adapter.c_str(), kProperties, "Get", g_variant_new("(ss)", kAdapter, "Powered"), G_VARIANT_TYPE("(v)"),
                                                          G_DBUS_CALL_FLAGS_NONE, 2000, nullptr, nullptr);
  if (reply == nullptr) return "unauthorized";
  g_autoptr(GVariant) boxed = g_variant_get_child_value(reply, 0);
  g_autoptr(GVariant) powered = g_variant_get_variant(boxed);
  return g_variant_get_boolean(powered) ? "poweredOn" : "poweredOff";
}

std::string DevicePath(const std::string& adapter, const std::string& address) {
  std::string tail = address;
  std::replace(tail.begin(), tail.end(), ':', '_');
  return adapter + "/dev_" + tail;
}

std::vector<std::string> Uuids(GVariant* properties) {
  std::vector<std::string> out;
  g_autoptr(GVariant) value = g_variant_lookup_value(properties, "UUIDs", G_VARIANT_TYPE_STRING_ARRAY);
  if (value == nullptr) return out;
  gsize count = 0;
  g_autofree const gchar** items = g_variant_get_strv(value, &count);
  for (gsize i = 0; i < count; i++) out.push_back(Lower(items[i]));
  return out;
}

// Device1 properties → the map UBleDevice.fromMap reads; nullptr when it does not match the scan's services.
FlValue* DeviceMap(GVariant* properties) {
  const gchar* address = nullptr;
  if (!g_variant_lookup(properties, "Address", "&s", &address)) return nullptr;
  const std::vector<std::string> uuids = Uuids(properties);
  bool matches = g_scan_services.empty();
  for (const std::string& uuid : uuids) {
    if (std::find(g_scan_services.begin(), g_scan_services.end(), uuid) != g_scan_services.end()) matches = true;
  }
  if (!matches) return nullptr;
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "id", fl_value_new_string(address));
  const gchar* name = nullptr;
  if (!g_variant_lookup(properties, "Name", "&s", &name)) g_variant_lookup(properties, "Alias", "&s", &name);
  fl_value_set_string_take(map, "name", fl_value_new_string(name != nullptr ? name : ""));
  gint16 rssi = 0;
  g_variant_lookup(properties, "RSSI", "n", &rssi);
  fl_value_set_string_take(map, "rssi", fl_value_new_int(rssi));
  FlValue* services = fl_value_new_list();
  for (const std::string& uuid : uuids) fl_value_append_take(services, fl_value_new_string(uuid.c_str()));
  fl_value_set_string_take(map, "services", services);
  FlValue* manufacturer = fl_value_new_map();
  g_autoptr(GVariant) data = g_variant_lookup_value(properties, "ManufacturerData", G_VARIANT_TYPE("a{qv}"));
  if (data != nullptr) {
    GVariantIter iter;
    g_variant_iter_init(&iter, data);
    guint16 company = 0;
    GVariant* boxed = nullptr;
    while (g_variant_iter_next(&iter, "{qv}", &company, &boxed)) {
      gsize length = 0;
      const guint8* bytes = static_cast<const guint8*>(g_variant_get_fixed_array(boxed, &length, 1));
      fl_value_set_take(manufacturer, fl_value_new_int(company), fl_value_new_uint8_list(bytes, length));
      g_variant_unref(boxed);
    }
  }
  fl_value_set_string_take(map, "manufacturerData", manufacturer);
  return map;
}

GVariant* DeviceProperties(const gchar* path) {
  GVariant* reply = g_dbus_connection_call_sync(Bus(), kBluez, path, kProperties, "GetAll", g_variant_new("(s)", kDevice), G_VARIANT_TYPE("(a{sv})"), G_DBUS_CALL_FLAGS_NONE, 2000,
                                                nullptr, nullptr);
  if (reply == nullptr) return nullptr;
  GVariant* properties = g_variant_get_child_value(reply, 0);
  g_variant_unref(reply);
  return properties;
}

void EmitScan(GVariant* properties) {
  if (!g_scanning || properties == nullptr) return;
  FlValue* map = DeviceMap(properties);
  if (map == nullptr) return;
  fl_event_channel_send(g_scan, map, nullptr, nullptr);
  fl_value_unref(map);
}

void EmitEvent(FlValue* event) {
  if (g_events_listening) fl_event_channel_send(g_events, event, nullptr, nullptr);
  fl_value_unref(event);
}

// Write length the link allows: BlueZ 5.62+ exposes MTU on characteristics; older versions only guarantee 23.
gint64 MaxWrite(const std::string& device_path) {
  guint16 mtu = 23;
  g_autoptr(GVariant) objects = ManagedObjects();
  if (objects == nullptr) return 20;
  ForEachInterface(objects, [&mtu, &device_path](const std::string& path, const std::string& name, GVariant* properties) {
    if (name != kCharacteristic || path.rfind(device_path + "/", 0) != 0) return;
    guint16 value = 0;
    if (g_variant_lookup(properties, "MTU", "q", &value) && value > mtu) mtu = value;
  });
  return mtu - 3;
}

void FinishConnect(const std::string& path, const std::string& error) {
  const auto it = g_connecting.find(path);
  if (it == g_connecting.end()) return;
  PendingConnect pending = it->second;
  g_connecting.erase(it);
  if (pending.timeout != 0) g_source_remove(pending.timeout);
  if (error.empty()) {
    const gchar* id = StringArg(fl_method_call_get_args(pending.call), "id");
    g_connected[path] = id != nullptr ? id : "";
    Respond(pending.call, fl_value_new_int(MaxWrite(path)));
  } else {
    g_dbus_connection_call(Bus(), kBluez, path.c_str(), kDevice, "Disconnect", nullptr, nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr, nullptr, nullptr);
    RespondError(pending.call, error);
  }
  g_object_unref(pending.call);
}

void OnPropertiesChanged(GDBusConnection*, const gchar*, const gchar* path, const gchar*, const gchar*, GVariant* parameters, gpointer) {
  const gchar* interface = nullptr;
  g_autoptr(GVariant) changed = nullptr;
  g_variant_get(parameters, "(&s@a{sv}@as)", &interface, &changed, nullptr);
  if (strcmp(interface, kDevice) == 0) {
    if (g_scanning) {
      g_autoptr(GVariant) properties = DeviceProperties(path);
      EmitScan(properties);
    }
    gboolean flag = FALSE;
    if (g_variant_lookup(changed, "ServicesResolved", "b", &flag) && flag) FinishConnect(path, "");
    if (g_variant_lookup(changed, "Connected", "b", &flag) && !flag) {
      FinishConnect(path, "failed");
      const auto it = g_connected.find(path);
      if (it != g_connected.end()) {
        FlValue* event = fl_value_new_map();
        fl_value_set_string_take(event, "event", fl_value_new_string("disconnected"));
        fl_value_set_string_take(event, "id", fl_value_new_string(it->second.c_str()));
        g_connected.erase(it);
        const std::string prefix = std::string(path) + "/";
        for (auto sub = g_subscriptions.begin(); sub != g_subscriptions.end();) sub = sub->first.rfind(prefix, 0) == 0 ? g_subscriptions.erase(sub) : std::next(sub);
        EmitEvent(event);
      }
    }
  } else if (strcmp(interface, kCharacteristic) == 0) {
    const auto it = g_subscriptions.find(path);
    if (it == g_subscriptions.end()) return;
    g_autoptr(GVariant) value = g_variant_lookup_value(changed, "Value", G_VARIANT_TYPE_BYTESTRING);
    if (value == nullptr) return;
    gsize length = 0;
    const guint8* bytes = static_cast<const guint8*>(g_variant_get_fixed_array(value, &length, 1));
    FlValue* event = fl_value_new_map();
    fl_value_set_string_take(event, "event", fl_value_new_string("value"));
    fl_value_set_string_take(event, "id", fl_value_new_string(it->second.id.c_str()));
    fl_value_set_string_take(event, "service", fl_value_new_string(it->second.service.c_str()));
    fl_value_set_string_take(event, "characteristic", fl_value_new_string(it->second.characteristic.c_str()));
    fl_value_set_string_take(event, "value", fl_value_new_uint8_list(bytes, length));
    EmitEvent(event);
  }
}

void OnInterfacesAdded(GDBusConnection*, const gchar*, const gchar*, const gchar*, const gchar*, GVariant* parameters, gpointer) {
  if (!g_scanning) return;
  g_autoptr(GVariant) interfaces = nullptr;
  g_variant_get(parameters, "(&o@a{sa{sv}})", nullptr, &interfaces);
  g_autoptr(GVariant) properties = g_variant_lookup_value(interfaces, kDevice, G_VARIANT_TYPE("a{sv}"));
  EmitScan(properties);
}

void EnsureSignals() {
  GDBusConnection* bus = Bus();
  if (bus == nullptr || g_properties_subscription != 0) return;
  g_properties_subscription = g_dbus_connection_signal_subscribe(bus, kBluez, kProperties, "PropertiesChanged", nullptr, nullptr, G_DBUS_SIGNAL_FLAGS_NONE, OnPropertiesChanged, nullptr, nullptr);
  g_added_subscription = g_dbus_connection_signal_subscribe(bus, kBluez, kObjectManager, "InterfacesAdded", nullptr, nullptr, G_DBUS_SIGNAL_FLAGS_NONE, OnInterfacesAdded, nullptr, nullptr);
}

void StopScan() {
  if (!g_scanning) return;
  g_scanning = false;
  const std::string adapter = AdapterPath();
  if (!adapter.empty()) g_dbus_connection_call(Bus(), kBluez, adapter.c_str(), kAdapter, "StopDiscovery", nullptr, nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr, nullptr, nullptr);
}

void StartScan(FlMethodCall* call, FlValue* args) {
  const std::string state = StateName();
  if (state != "poweredOn") return RespondError(call, state);
  StopScan();
  EnsureSignals();
  g_scan_services.clear();
  FlValue* services = args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP ? fl_value_lookup_string(args, "services") : nullptr;
  GVariantBuilder uuids;
  g_variant_builder_init(&uuids, G_VARIANT_TYPE_STRING_ARRAY);
  if (services != nullptr && fl_value_get_type(services) == FL_VALUE_TYPE_LIST) {
    for (size_t i = 0; i < fl_value_get_length(services); i++) {
      FlValue* item = fl_value_get_list_value(services, i);
      if (fl_value_get_type(item) != FL_VALUE_TYPE_STRING) continue;
      g_scan_services.push_back(Lower(fl_value_get_string(item)));
      g_variant_builder_add(&uuids, "s", fl_value_get_string(item));
    }
  }
  GVariantBuilder filter;
  g_variant_builder_init(&filter, G_VARIANT_TYPE("a{sv}"));
  g_variant_builder_add(&filter, "{sv}", "Transport", g_variant_new_string("le"));
  g_variant_builder_add(&filter, "{sv}", "UUIDs", g_variant_builder_end(&uuids));
  const std::string adapter = AdapterPath();
  g_autoptr(GVariant) filtered = g_dbus_connection_call_sync(Bus(), kBluez, adapter.c_str(), kAdapter, "SetDiscoveryFilter", g_variant_new("(a{sv})", &filter), nullptr,
                                                             G_DBUS_CALL_FLAGS_NONE, 2000, nullptr, nullptr);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) started = g_dbus_connection_call_sync(Bus(), kBluez, adapter.c_str(), kAdapter, "StartDiscovery", nullptr, nullptr, G_DBUS_CALL_FLAGS_NONE, 3000, nullptr, &error);
  if (started == nullptr) return RespondError(call, g_error_matches(error, G_DBUS_ERROR, G_DBUS_ERROR_ACCESS_DENIED) ? "unauthorized" : "failed");
  g_scanning = true;
  Respond(call, nullptr);
  // Devices BlueZ already saw recently (they have an RSSI) are reported right away.
  g_autoptr(GVariant) objects = ManagedObjects();
  if (objects == nullptr) return;
  ForEachInterface(objects, [](const std::string&, const std::string& name, GVariant* properties) {
    if (name != kDevice) return;
    gint16 rssi = 0;
    if (g_variant_lookup(properties, "RSSI", "n", &rssi)) EmitScan(properties);
  });
}

gboolean OnConnectTimeout(gpointer data) {
  auto* path = static_cast<std::string*>(data);
  const auto it = g_connecting.find(*path);
  if (it != g_connecting.end()) {
    it->second.timeout = 0;
    FinishConnect(*path, "timeout");
  }
  delete path;
  return G_SOURCE_REMOVE;
}

void OnConnected(GObject* source, GAsyncResult* result, gpointer data) {
  auto* path = static_cast<std::string*>(data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) reply = g_dbus_connection_call_finish(G_DBUS_CONNECTION(source), result, &error);
  if (reply == nullptr) {
    FinishConnect(*path, "failed");
  } else {
    g_autoptr(GVariant) properties = DeviceProperties(path->c_str());
    gboolean resolved = FALSE;
    if (properties != nullptr && g_variant_lookup(properties, "ServicesResolved", "b", &resolved) && resolved) FinishConnect(*path, "");
  }
  delete path;
}

void Connect(FlMethodCall* call, FlValue* args) {
  const std::string state = StateName();
  if (state != "poweredOn") return RespondError(call, state);
  const gchar* id = StringArg(args, "id");
  const std::string adapter = AdapterPath();
  if (id == nullptr || strlen(id) != 17) return RespondError(call, "notFound");
  EnsureSignals();
  const std::string path = DevicePath(adapter, id);
  FinishConnect(path, "failed");
  PendingConnect pending;
  pending.call = FL_METHOD_CALL(g_object_ref(call));
  pending.timeout = g_timeout_add(static_cast<guint>(IntArg(args, "timeout", 15000)), OnConnectTimeout, new std::string(path));
  g_connecting[path] = pending;
  g_dbus_connection_call(Bus(), kBluez, path.c_str(), kDevice, "Connect", nullptr, nullptr, G_DBUS_CALL_FLAGS_NONE, static_cast<gint>(IntArg(args, "timeout", 15000)), nullptr, OnConnected,
                         new std::string(path));
}

// Path of [characteristic] inside [service] on the device with [id], or "" when it is not there.
std::string CharacteristicPath(const std::string& id, const std::string& service, const std::string& characteristic) {
  const std::string device = DevicePath(AdapterPath(), id);
  g_autoptr(GVariant) objects = ManagedObjects();
  if (objects == nullptr) return "";
  std::map<std::string, std::string> services;
  std::vector<std::pair<std::string, std::pair<std::string, std::string>>> characteristics;
  ForEachInterface(objects, [&](const std::string& path, const std::string& name, GVariant* properties) {
    if (path.rfind(device + "/", 0) != 0) return;
    const gchar* uuid = nullptr;
    if (!g_variant_lookup(properties, "UUID", "&s", &uuid)) return;
    if (name == kService) services[path] = Lower(uuid);
    if (name == kCharacteristic) {
      const gchar* owner = nullptr;
      g_variant_lookup(properties, "Service", "&o", &owner);
      characteristics.push_back({path, {owner != nullptr ? owner : "", Lower(uuid)}});
    }
  });
  for (const auto& item : characteristics) {
    if (item.second.second == characteristic && services[item.second.first] == service) return item.first;
  }
  return "";
}

void OnCallDone(GObject* source, GAsyncResult* result, gpointer data) {
  auto* call = static_cast<FlMethodCall*>(data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GVariant) reply = g_dbus_connection_call_finish(G_DBUS_CONNECTION(source), result, &error);
  if (reply == nullptr) {
    RespondError(call, "failed");
  } else {
    Respond(call, nullptr);
  }
  g_object_unref(call);
}

void SetNotify(FlMethodCall* call, FlValue* args) {
  const gchar* id = StringArg(args, "id");
  const gchar* service = StringArg(args, "service");
  const gchar* characteristic = StringArg(args, "characteristic");
  if (id == nullptr || service == nullptr || characteristic == nullptr) return RespondError(call, "notFound");
  const std::string path = CharacteristicPath(id, Lower(service), Lower(characteristic));
  if (path.empty()) return RespondError(call, "notFound");
  const bool enable = BoolArg(args, "enable", true);
  if (enable) {
    g_subscriptions[path] = Subscription{id, Lower(service), Lower(characteristic)};
  } else {
    g_subscriptions.erase(path);
  }
  g_dbus_connection_call(Bus(), kBluez, path.c_str(), kCharacteristic, enable ? "StartNotify" : "StopNotify", nullptr, nullptr, G_DBUS_CALL_FLAGS_NONE, 5000, nullptr, OnCallDone,
                         g_object_ref(call));
}

void Write(FlMethodCall* call, FlValue* args) {
  const gchar* id = StringArg(args, "id");
  const gchar* service = StringArg(args, "service");
  const gchar* characteristic = StringArg(args, "characteristic");
  FlValue* value = args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP ? fl_value_lookup_string(args, "value") : nullptr;
  if (id == nullptr || service == nullptr || characteristic == nullptr || value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_UINT8_LIST) return RespondError(call, "failed");
  const std::string path = CharacteristicPath(id, Lower(service), Lower(characteristic));
  if (path.empty()) return RespondError(call, "disconnected");
  GVariantBuilder options;
  g_variant_builder_init(&options, G_VARIANT_TYPE("a{sv}"));
  g_variant_builder_add(&options, "{sv}", "type", g_variant_new_string(BoolArg(args, "withResponse", true) ? "request" : "command"));
  GVariant* bytes = g_variant_new_fixed_array(G_VARIANT_TYPE_BYTE, fl_value_get_uint8_list(value), fl_value_get_length(value), 1);
  g_dbus_connection_call(Bus(), kBluez, path.c_str(), kCharacteristic, "WriteValue", g_variant_new("(@aya{sv})", bytes, &options), nullptr, G_DBUS_CALL_FLAGS_NONE, 10000, nullptr,
                         OnCallDone, g_object_ref(call));
}

void Disconnect(FlMethodCall* call, FlValue* args) {
  const gchar* id = StringArg(args, "id");
  if (id != nullptr && strlen(id) == 17) {
    const std::string path = DevicePath(AdapterPath(), id);
    g_dbus_connection_call(Bus(), kBluez, path.c_str(), kDevice, "Disconnect", nullptr, nullptr, G_DBUS_CALL_FLAGS_NONE, -1, nullptr, nullptr, nullptr);
  }
  Respond(call, nullptr);
}

void HandleMethodCall(FlMethodChannel*, FlMethodCall* call, gpointer) {
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  if (strcmp(method, "state") == 0 || strcmp(method, "requestPermission") == 0) {
    Respond(call, fl_value_new_string(StateName().c_str()));
  } else if (strcmp(method, "startScan") == 0) {
    StartScan(call, args);
  } else if (strcmp(method, "stopScan") == 0) {
    StopScan();
    Respond(call, nullptr);
  } else if (strcmp(method, "connect") == 0) {
    Connect(call, args);
  } else if (strcmp(method, "disconnect") == 0) {
    Disconnect(call, args);
  } else if (strcmp(method, "setNotify") == 0) {
    SetNotify(call, args);
  } else if (strcmp(method, "write") == 0) {
    Write(call, args);
  } else {
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(call, response, nullptr);
  }
}

FlMethodErrorResponse* OnEventsListen(FlEventChannel*, FlValue*, gpointer) {
  g_events_listening = true;
  EnsureSignals();
  return nullptr;
}

FlMethodErrorResponse* OnEventsCancel(FlEventChannel*, FlValue*, gpointer) {
  g_events_listening = false;
  return nullptr;
}

FlMethodErrorResponse* Nothing(FlEventChannel*, FlValue*, gpointer) { return nullptr; }

}  // namespace

void u_ble_register(FlPluginRegistrar* registrar) {
  if (g_channel != nullptr) return;
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_channel = fl_method_channel_new(messenger, "u/ble", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(g_channel, HandleMethodCall, nullptr, nullptr);
  g_scan = fl_event_channel_new(messenger, "u/ble/scan", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(g_scan, Nothing, Nothing, nullptr, nullptr);
  g_events = fl_event_channel_new(messenger, "u/ble/events", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(g_events, OnEventsListen, OnEventsCancel, nullptr, nullptr);
}
