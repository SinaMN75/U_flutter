#ifndef FLUTTER_PLUGIN_U_CAMERA_H_
#define FLUTTER_PLUGIN_U_CAMERA_H_

#include <flutter/plugin_registrar_windows.h>

namespace u {

// Registers the "u/camera" method channel. Backed by Media Foundation, which
// ships with Windows, so nothing is bundled with the app.
class UCamera {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
};

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_CAMERA_H_
