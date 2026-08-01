#ifndef FLUTTER_PLUGIN_U_SCREEN_GUARD_H_
#define FLUTTER_PLUGIN_U_SCREEN_GUARD_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace u {

// Native screenshot / screen-recording prevention for Windows via
// SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE).
class ScreenGuard {
 public:
  // Registers the "u/screen_guard" channel on the given registrar.
  static void RegisterWithRegistrar(
      flutter::PluginRegistrarWindows* registrar);

  explicit ScreenGuard(flutter::PluginRegistrarWindows* registrar);
  ~ScreenGuard();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void ApplyScreenGuard(bool enabled);

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_SCREEN_GUARD_H_
