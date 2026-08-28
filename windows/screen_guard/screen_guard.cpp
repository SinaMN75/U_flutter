#include "screen_guard.h"

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

// Fully excludes the window from screen capture (Windows 10 2004+).
#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif
#ifndef WDA_NONE
#define WDA_NONE 0x00000000
#endif

namespace u {

// static
void ScreenGuard::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  // Owned by the registrar via the returned plugin; kept alive for the app's
  // lifetime. The instance is intentionally leaked to the process here because
  // the channel handler must outlive this call.
  auto* guard = new ScreenGuard(registrar);
  (void)guard;
}

ScreenGuard::ScreenGuard(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "u/screen_guard",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });
}

ScreenGuard::~ScreenGuard() {}

void ScreenGuard::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "enable") {
    ApplyScreenGuard(true);
    result->Success();
  } else if (call.method_name() == "disable") {
    ApplyScreenGuard(false);
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void ScreenGuard::ApplyScreenGuard(bool enabled) {
  flutter::FlutterView* view = registrar_->GetView();
  if (!view) {
    return;
  }
  // Apply affinity to the top-level window, not the Flutter child view.
  HWND hwnd = GetAncestor(view->GetNativeWindow(), GA_ROOT);
  if (!hwnd) {
    return;
  }
  // WDA_EXCLUDEFROMCAPTURE renders the window absent from screenshots and
  // recordings; fall back to WDA_MONITOR (black) on older Windows builds.
  if (enabled) {
    if (!SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE)) {
      SetWindowDisplayAffinity(hwnd, WDA_MONITOR);
    }
  } else {
    SetWindowDisplayAffinity(hwnd, WDA_NONE);
  }
}

}  // namespace u
