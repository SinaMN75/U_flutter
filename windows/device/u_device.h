#ifndef FLUTTER_PLUGIN_U_DEVICE_H_
#define FLUTTER_PLUGIN_U_DEVICE_H_

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace u {

// Native side of UDevice, UPackage and UConnectivity on Windows ("u/device" and
// "u/device/network"): registry + version resources for device / package info,
// Network List Manager + IP Helper for connectivity, GetSystemPowerStatus for battery.
//
// IP Helper change callbacks arrive on a thread-pool thread; they are marshalled to
// the platform thread through a message-only window and coalesced with a short timer.
class UDevice {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit UDevice(flutter::PluginRegistrarWindows* registrar);
  ~UDevice();

  // Called on the platform thread by the message window.
  void OnNetworkChanged();

 private:
  void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void StartWatching();
  void StopWatching();

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> events_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
  void* window_ = nullptr;           // HWND
  void* interface_notify_ = nullptr; // HANDLE from NotifyIpInterfaceChange
  void* address_notify_ = nullptr;   // HANDLE from NotifyUnicastIpAddressChange
};

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_DEVICE_H_
