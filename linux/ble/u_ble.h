#ifndef FLUTTER_PLUGIN_U_BLE_H_
#define FLUTTER_PLUGIN_U_BLE_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

// Registers "u/ble" + scan / events: BlueZ (org.bluez) over the system D-Bus. Device ids are the
// Bluetooth address ("AA:BB:CC:DD:EE:FF"); the user must be allowed to use Bluetooth by the desktop's policy.
void u_ble_register(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_U_BLE_H_
