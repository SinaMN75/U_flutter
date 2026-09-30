#ifndef FLUTTER_PLUGIN_U_LAUNCH_H_
#define FLUTTER_PLUGIN_U_LAUNCH_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

// Registers "u/launch" + "u/launch/events" (GIO default handlers, xdg-email, GNOME Settings
// panels, appstream:// store pages, deep links from argv) and "u/share" + "u/share/received"
// (Linux has no share sheet: Dart copies text / reveals files; files from argv are received).
void u_launch_register(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_U_LAUNCH_H_
