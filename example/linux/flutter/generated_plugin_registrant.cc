//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <syncfusion_pdfviewer_linux/syncfusion_pdfviewer_linux_plugin.h>
#include <u/u_plugin.h>
#include <url_launcher_linux/url_launcher_plugin.h>
#include <webview_all_linux/webview_all_linux_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) syncfusion_pdfviewer_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SyncfusionPdfviewerLinuxPlugin");
  syncfusion_pdfviewer_linux_plugin_register_with_registrar(syncfusion_pdfviewer_linux_registrar);
  g_autoptr(FlPluginRegistrar) u_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UPlugin");
  u_plugin_register_with_registrar(u_registrar);
  g_autoptr(FlPluginRegistrar) url_launcher_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UrlLauncherPlugin");
  url_launcher_plugin_register_with_registrar(url_launcher_linux_registrar);
  g_autoptr(FlPluginRegistrar) webview_all_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WebviewAllLinuxPlugin");
  webview_all_linux_plugin_register_with_registrar(webview_all_linux_registrar);
}
