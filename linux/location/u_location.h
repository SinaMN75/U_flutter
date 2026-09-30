#ifndef FLUTTER_PLUGIN_U_LOCATION_H_
#define FLUTTER_PLUGIN_U_LOCATION_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

// Registers "u/location" + updates / heading / geofence / visits: positions from GeoClue2 over
// the system D-Bus (async, so the desktop's location agent can prompt without blocking the UI).
// Heading, visits, geocoding and native geofences do not exist on Linux: Dart falls back.
void u_location_register(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_U_LOCATION_H_
