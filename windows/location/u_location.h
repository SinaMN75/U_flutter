#ifndef FLUTTER_PLUGIN_U_LOCATION_H_
#define FLUTTER_PLUGIN_U_LOCATION_H_

#include <flutter/plugin_registrar_windows.h>

namespace u {

// Native side of ULocation on Windows ("u/location" + updates / heading / geofence / visits):
// Windows.Devices.Geolocation for positions and permission, GeofenceMonitor for geofences and
// the Compass sensor for heading. Geocoding and visits are not available on Windows.
void RegisterLocation(flutter::PluginRegistrarWindows* registrar);

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_LOCATION_H_
