//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <u/u_plugin_c_api.h>
#include <webview_all_windows/webview_all_windows_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  UPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UPluginCApi"));
  WebviewAllWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WebviewAllWindowsPlugin"));
}
