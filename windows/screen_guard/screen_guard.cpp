#include "screen_guard.h"

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <chrono>
#include <memory>
#include <thread>

// Fully excludes the window from screen capture (Windows 10 2004+).
#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif
#ifndef WDA_NONE
#define WDA_NONE 0x00000000
#endif

namespace {

// Hot-key ids for the PrintScreen variants; the base id is arbitrary but must
// stay unique inside the process.
    constexpr int kHotKeyBase = 0x7501;
    constexpr int kHotKeyModifiers[] = {0, MOD_ALT, MOD_CONTROL, MOD_SHIFT, MOD_WIN};
    constexpr int kHotKeyCount = 5;

}  // namespace

namespace u {

// static
    void ScreenGuard::RegisterWithRegistrar(
            flutter::PluginRegistrarWindows *registrar) {
        // Owned by the registrar via the returned plugin; kept alive for the app's
        // lifetime. The instance is intentionally leaked to the process here because
        // the channel handler must outlive this call.
        auto *guard = new ScreenGuard(registrar);
        (void) guard;
    }

    ScreenGuard::ScreenGuard(flutter::PluginRegistrarWindows *registrar)
            : registrar_(registrar) {
        channel_ = std::make_unique < flutter::MethodChannel < flutter::EncodableValue >> (
                registrar->messenger(), "u/screen_guard",
                        &flutter::StandardMethodCodec::GetInstance());
        channel_->SetMethodCallHandler(
                [this](const auto &call, auto result) {
                    HandleMethodCall(call, std::move(result));
                });
        window_proc_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
                [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
                    return HandleWindowProc(hwnd, message, wparam, lparam);
                });
    }

    ScreenGuard::~ScreenGuard() {
        if (window_proc_id_ != -1) {
            registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_id_);
        }
    }

    void ScreenGuard::HandleMethodCall(
            const flutter::MethodCall <flutter::EncodableValue> &call,
            std::unique_ptr <flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "enable") {
            exit_on_capture_ = true;
            const auto *args = std::get_if<flutter::EncodableMap>(call.arguments());
            if (args != nullptr) {
                auto it = args->find(flutter::EncodableValue("exitOnCapture"));
                if (it != args->end()) {
                    const bool *value = std::get_if<bool>(&it->second);
                    if (value != nullptr) exit_on_capture_ = *value;
                }
            }
            guard_enabled_ = true;
            ApplyScreenGuard(true);
            RegisterCaptureHotKeys(RootWindow());
            result->Success();
        } else if (call.method_name() == "disable") {
            guard_enabled_ = false;
            ApplyScreenGuard(false);
            UnregisterCaptureHotKeys(RootWindow());
            result->Success();
        } else if (call.method_name() == "isCaptured") {
            result->Success(flutter::EncodableValue(false));
        } else if (call.method_name() == "terminate") {
            Terminate();
            result->Success();
        } else {
            result->NotImplemented();
        }
    }

// The display affinity is dropped whenever the window is recreated or moved to
// another monitor, so it is re-asserted from the window procedure.
    std::optional <LRESULT> ScreenGuard::HandleWindowProc(HWND hwnd, UINT message,
                                                          WPARAM wparam,
                                                          LPARAM lparam) {
        (void) lparam;
        if (!guard_enabled_) return std::nullopt;
        switch (message) {
            case WM_HOTKEY:
                if (static_cast<int>(wparam) >= kHotKeyBase &&
                    static_cast<int>(wparam) < kHotKeyBase + kHotKeyCount) {
                    if (OpenClipboard(hwnd)) {
                        EmptyClipboard();
                        CloseClipboard();
                    }
                    OnCapture("screenshot");
                    return 0;
                }
                break;
            case WM_ACTIVATE:
            case WM_SHOWWINDOW:
            case WM_DISPLAYCHANGE:
            case WM_DPICHANGED:
            case WM_WINDOWPOSCHANGED:
                ApplyScreenGuard(true);
                break;
            default:
                break;
        }
        return std::nullopt;
    }

    HWND ScreenGuard::RootWindow() {
        flutter::FlutterView *view = registrar_->GetView();
        if (view == nullptr) return nullptr;
        // Apply affinity to the top-level window, not the Flutter child view.
        return GetAncestor(view->GetNativeWindow(), GA_ROOT);
    }

    void ScreenGuard::ApplyScreenGuard(bool enabled) {
        HWND hwnd = RootWindow();
        if (hwnd == nullptr) return;
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

    void ScreenGuard::RegisterCaptureHotKeys(HWND hwnd) {
        if (hwnd == nullptr || hot_keys_registered_) return;
        for (int i = 0; i < kHotKeyCount; ++i) {
            RegisterHotKey(hwnd, kHotKeyBase + i,
                           kHotKeyModifiers[i] | MOD_NOREPEAT, VK_SNAPSHOT);
        }
        hot_keys_registered_ = true;
    }

    void ScreenGuard::UnregisterCaptureHotKeys(HWND hwnd) {
        if (hwnd == nullptr || !hot_keys_registered_) return;
        for (int i = 0; i < kHotKeyCount; ++i) {
            UnregisterHotKey(hwnd, kHotKeyBase + i);
        }
        hot_keys_registered_ = false;
    }

    void ScreenGuard::OnCapture(const char *reason) {
        if (!guard_enabled_) return;
        channel_->InvokeMethod("onScreenshot", nullptr);
        channel_->InvokeMethod(
                "onViolation",
                std::make_unique<flutter::EncodableValue>(std::string(reason)));
        if (exit_on_capture_) Terminate();
    }

    void ScreenGuard::Terminate() {
        if (terminating_) return;
        terminating_ = true;
        // Detached so the pending channel messages reach Dart before the kill.
        std::thread([]() {
            std::this_thread::sleep_for(std::chrono::milliseconds(150));
            ExitProcess(0);
        }).detach();
    }

}  // namespace u
