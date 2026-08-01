#include "include/u/u_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#include "u_plugin_private.h"

#define U_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), u_plugin_get_type(), \
                              UPlugin))

struct _UPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(UPlugin, u_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void u_plugin_handle_method_call(
    UPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    response = get_platform_version();
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void u_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(u_plugin_parent_class)->dispose(object);
}

static void u_plugin_class_init(UPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = u_plugin_dispose;
}

static void u_plugin_init(UPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  UPlugin* plugin = U_PLUGIN(user_data);
  u_plugin_handle_method_call(plugin, method_call);
}

void u_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  UPlugin* plugin = U_PLUGIN(
      g_object_new(u_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "u",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
