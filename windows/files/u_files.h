#ifndef FLUTTER_PLUGIN_U_FILES_H_
#define FLUTTER_PLUGIN_U_FILES_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace u {

// Native side of the "u/files" channel on Windows: free space, the Save As dialog,
// open / show in Explorer, keeping the system awake, secrets in Credential Manager
// (DPAPI-protected, per user) and BITS jobs for downloads that survive the app
// exiting or the machine rebooting.
class UFiles {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit UFiles(flutter::PluginRegistrarWindows* registrar);
  ~UFiles();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_FILES_H_
