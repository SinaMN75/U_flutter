#ifndef FLUTTER_PLUGIN_U_SCREEN_GUARD_H_
#define FLUTTER_PLUGIN_U_SCREEN_GUARD_H_

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <optional>

namespace u {

// Native screenshot / screen-recording prevention for Windows via
// SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE), with PrintScreen
// interception and process termination on a detected capture.
    class ScreenGuard {
    public:
        // Registers the "u/screen_guard" channel on the given registrar.
        static void RegisterWithRegistrar(
                flutter::PluginRegistrarWindows *registrar);

        explicit ScreenGuard(flutter::PluginRegistrarWindows *registrar);

        ~ScreenGuard();

    private:
        void HandleMethodCall(
                const flutter::MethodCall <flutter::EncodableValue> &call,
                std::unique_ptr <flutter::MethodResult<flutter::EncodableValue>> result);

        std::optional <LRESULT> HandleWindowProc(HWND hwnd, UINT message,
                                                 WPARAM wparam, LPARAM lparam);

        HWND RootWindow();

        void ApplyScreenGuard(bool enabled);

        void RegisterCaptureHotKeys(HWND hwnd);

        void UnregisterCaptureHotKeys(HWND hwnd);

        void OnCapture(const char *reason);

        void Terminate();

        flutter::PluginRegistrarWindows *registrar_;
        std::unique_ptr <flutter::MethodChannel<flutter::EncodableValue>> channel_;
        int window_proc_id_ = -1;
        bool guard_enabled_ = false;
        bool exit_on_capture_ = true;
        bool terminating_ = false;
        bool hot_keys_registered_ = false;
    };

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_SCREEN_GUARD_H_
