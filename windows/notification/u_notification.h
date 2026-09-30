#ifndef FLUTTER_PLUGIN_U_NOTIFICATION_H_
#define FLUTTER_PLUGIN_U_NOTIFICATION_H_

#include <flutter/plugin_registrar_windows.h>

namespace u {

// Native side of UNotification on Windows ("u/notify" + "u/notify/events"): toast
// notifications with a COM activator (clicks and replies reach the app even after it closed),
// scheduled toasts, in-place progress updates, history and a taskbar badge overlay.
void RegisterNotification(flutter::PluginRegistrarWindows* registrar);

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_NOTIFICATION_H_
