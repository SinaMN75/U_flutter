#ifndef FLUTTER_PLUGIN_U_PLUGIN_H_
#define FLUTTER_PLUGIN_U_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace u {

class UPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  UPlugin();

  virtual ~UPlugin();

  // Disallow copy and assign.
  UPlugin(const UPlugin&) = delete;
  UPlugin& operator=(const UPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_PLUGIN_H_
