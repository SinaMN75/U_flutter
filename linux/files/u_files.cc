#include "u_files.h"

#include <gio/gio.h>
#include <gio/gunixfdlist.h>
#include <gtk/gtk.h>
#include <sys/statvfs.h>
#include <unistd.h>

#include <cstring>
#include <string>

#ifdef U_HAS_LIBSECRET
#include <libsecret/secret.h>
#endif

namespace {

struct UFilesPlugin {
  FlPluginRegistrar* registrar = nullptr;
  FlMethodChannel* channel = nullptr;
  // logind inhibitor: the lock holds for as long as this descriptor stays open.
  int inhibit_fd = -1;
};

UFilesPlugin* g_files = nullptr;

const gchar* StringArg(FlValue* args, const char* key) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) return nullptr;
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING ? fl_value_get_string(value) : nullptr;
}

bool BoolArg(FlValue* args, const char* key) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) return false;
  FlValue* value = fl_value_lookup_string(args, key);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL && fl_value_get_bool(value);
}

FlMethodResponse* Success(FlValue* value) { return FL_METHOD_RESPONSE(fl_method_success_response_new(value)); }

FlMethodResponse* FreeSpace(FlValue* args) {
  const gchar* raw = StringArg(args, "path");
  std::string path = raw ? raw : g_get_home_dir();
  struct statvfs info;
  // The target file usually does not exist yet; walk up to a directory that does.
  while (!path.empty() && statvfs(path.c_str(), &info) != 0) {
    const size_t slash = path.find_last_of('/');
    path = slash == std::string::npos || slash == 0 ? std::string() : path.substr(0, slash);
  }
  if (path.empty()) return Success(fl_value_new_null());
  return Success(fl_value_new_int(static_cast<int64_t>(info.f_bavail) * static_cast<int64_t>(info.f_frsize)));
}

GtkWindow* TopWindow() {
  FlView* view = fl_plugin_registrar_get_view(g_files->registrar);
  if (view == nullptr) return nullptr;
  GtkWidget* top = gtk_widget_get_toplevel(GTK_WIDGET(view));
  return GTK_IS_WINDOW(top) ? GTK_WINDOW(top) : nullptr;
}

FlMethodResponse* SaveAs(FlValue* args) {
  const gchar* source = StringArg(args, "sourcePath");
  const gchar* name = StringArg(args, "fileName");
  GtkFileChooserNative* dialog =
      gtk_file_chooser_native_new(nullptr, TopWindow(), GTK_FILE_CHOOSER_ACTION_SAVE, "_Save", "_Cancel");
  GtkFileChooser* chooser = GTK_FILE_CHOOSER(dialog);
  gtk_file_chooser_set_do_overwrite_confirmation(chooser, TRUE);
  if (name != nullptr) gtk_file_chooser_set_current_name(chooser, name);
  FlValue* result = fl_value_new_null();
  if (gtk_native_dialog_run(GTK_NATIVE_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT && source != nullptr) {
    g_autofree gchar* target = gtk_file_chooser_get_filename(chooser);
    g_autoptr(GFile) from = g_file_new_for_path(source);
    g_autoptr(GFile) to = g_file_new_for_path(target);
    if (g_file_copy(from, to, G_FILE_COPY_OVERWRITE, nullptr, nullptr, nullptr, nullptr)) {
      fl_value_unref(result);
      result = fl_value_new_string(target);
    }
  }
  g_object_unref(dialog);
  return Success(result);
}

bool LaunchUri(const gchar* path) {
  g_autoptr(GFile) file = g_file_new_for_path(path);
  g_autofree gchar* uri = g_file_get_uri(file);
  return g_app_info_launch_default_for_uri(uri, nullptr, nullptr);
}

FlMethodResponse* Reveal(FlValue* args) {
  const gchar* path = StringArg(args, "path");
  if (path == nullptr) return Success(fl_value_new_bool(FALSE));
  g_autoptr(GFile) file = g_file_new_for_path(path);
  g_autofree gchar* uri = g_file_get_uri(file);
  g_autoptr(GDBusConnection) bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
  if (bus != nullptr) {
    const gchar* uris[] = {uri, nullptr};
    g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
        bus, "org.freedesktop.FileManager1", "/org/freedesktop/FileManager1", "org.freedesktop.FileManager1", "ShowItems",
        g_variant_new("(^ass)", uris, ""), nullptr, G_DBUS_CALL_FLAGS_NONE, 3000, nullptr, nullptr);
    if (reply != nullptr) return Success(fl_value_new_bool(TRUE));
  }
  // No FileManager1 service: open the containing folder instead.
  g_autoptr(GFile) parent = g_file_get_parent(file);
  g_autofree gchar* parent_path = parent ? g_file_get_path(parent) : nullptr;
  return Success(fl_value_new_bool(parent_path != nullptr && LaunchUri(parent_path)));
}

void KeepAwake(bool enabled) {
  if (!enabled) {
    if (g_files->inhibit_fd >= 0) close(g_files->inhibit_fd);
    g_files->inhibit_fd = -1;
    return;
  }
  if (g_files->inhibit_fd >= 0) return;
  g_autoptr(GDBusConnection) bus = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, nullptr);
  if (bus == nullptr) return;
  GUnixFDList* fds = nullptr;
  g_autoptr(GVariant) reply = g_dbus_connection_call_with_unix_fd_list_sync(
      bus, "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "Inhibit",
      g_variant_new("(ssss)", "sleep:idle", g_get_prgname() ? g_get_prgname() : "u", "Downloading files", "block"),
      G_VARIANT_TYPE("(h)"), G_DBUS_CALL_FLAGS_NONE, -1, nullptr, &fds, nullptr, nullptr);
  if (reply != nullptr && fds != nullptr) {
    gint32 index = 0;
    g_variant_get(reply, "(h)", &index);
    g_files->inhibit_fd = g_unix_fd_list_get(fds, index, nullptr);
  }
  if (fds != nullptr) g_object_unref(fds);
}

#ifdef U_HAS_LIBSECRET
const SecretSchema* Schema() {
  static const SecretSchema schema = {
      "com.sinamn75.u.Secret",
      SECRET_SCHEMA_NONE,
      {{"alias", SECRET_SCHEMA_ATTRIBUTE_STRING}, {nullptr, SECRET_SCHEMA_ATTRIBUTE_STRING}},
  };
  return &schema;
}

FlMethodResponse* StoreSecret(FlValue* args) {
  const gchar* alias = StringArg(args, "alias");
  FlValue* secret = args ? fl_value_lookup_string(args, "secret") : nullptr;
  if (alias == nullptr || secret == nullptr || fl_value_get_type(secret) != FL_VALUE_TYPE_UINT8_LIST) {
    return Success(fl_value_new_bool(FALSE));
  }
  // Stored base64-encoded so it works with every libsecret version (binary storage is 0.19+).
  g_autofree gchar* encoded = g_base64_encode(fl_value_get_uint8_list(secret), fl_value_get_length(secret));
  const gboolean ok = secret_password_store_sync(Schema(), SECRET_COLLECTION_DEFAULT, "u vault key", encoded, nullptr,
                                                 nullptr, "alias", alias, nullptr);
  return Success(fl_value_new_bool(ok));
}

FlMethodResponse* LoadSecret(FlValue* args) {
  const gchar* alias = StringArg(args, "alias");
  GError* error = nullptr;
  gchar* encoded = secret_password_lookup_sync(Schema(), nullptr, &error, "alias", alias ? alias : "", nullptr);
  if (error != nullptr) {
    // Locked or unreachable keyring: report it, so Dart never mistakes it for "no key".
    FlMethodResponse* response =
        FL_METHOD_RESPONSE(fl_method_error_response_new("secret_service", error->message, nullptr));
    g_error_free(error);
    return response;
  }
  if (encoded == nullptr) return Success(fl_value_new_null());
  gsize length = 0;
  g_autofree guchar* bytes = g_base64_decode(encoded, &length);
  secret_password_free(encoded);
  return Success(fl_value_new_uint8_list(bytes, length));
}

FlMethodResponse* DeleteSecret(FlValue* args) {
  const gchar* alias = StringArg(args, "alias");
  secret_password_clear_sync(Schema(), nullptr, nullptr, "alias", alias ? alias : "", nullptr);
  return Success(fl_value_new_null());
}
#endif

void HandleMethodCall(FlMethodChannel* channel, FlMethodCall* call, gpointer user_data) {
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "freeSpace") == 0) {
    response = FreeSpace(args);
  } else if (strcmp(method, "saveAs") == 0) {
    response = SaveAs(args);
  } else if (strcmp(method, "open") == 0) {
    const gchar* path = StringArg(args, "path");
    response = Success(fl_value_new_bool(path != nullptr && LaunchUri(path)));
  } else if (strcmp(method, "reveal") == 0) {
    response = Reveal(args);
  } else if (strcmp(method, "keepAwake") == 0) {
    KeepAwake(BoolArg(args, "enabled"));
    response = Success(fl_value_new_null());
#ifdef U_HAS_LIBSECRET
  } else if (strcmp(method, "storeSecret") == 0) {
    response = StoreSecret(args);
  } else if (strcmp(method, "loadSecret") == 0) {
    response = LoadSecret(args);
  } else if (strcmp(method, "deleteSecret") == 0) {
    response = DeleteSecret(args);
#endif
  } else if (strcmp(method, "systemSupported") == 0) {
    // Linux has no system download service; the in-app engine is used.
    response = Success(fl_value_new_bool(FALSE));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(call, response, nullptr);
}

}  // namespace

void u_files_register(FlPluginRegistrar* registrar) {
  if (g_files != nullptr) return;
  g_files = new UFilesPlugin();
  g_files->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_files->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), "u/files", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(g_files->channel, HandleMethodCall, nullptr, nullptr);
}
