#include "include/u/u_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "u_plugin.h"

void UPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  u::UPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
