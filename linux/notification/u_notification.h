#ifndef FLUTTER_PLUGIN_U_NOTIFICATION_H_
#define FLUTTER_PLUGIN_U_NOTIFICATION_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

// Registers "u/notify" + "u/notify/events": org.freedesktop.Notifications over the session bus
// (buttons, inline reply where the server supports it, progress hint, urgency, images) and the
// Unity launcher-entry badge. Scheduling runs in Dart (Linux has no notification scheduler).
void u_notification_register(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_U_NOTIFICATION_H_
