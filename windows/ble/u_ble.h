#ifndef FLUTTER_PLUGIN_U_BLE_H_
#define FLUTTER_PLUGIN_U_BLE_H_

#include <flutter/plugin_registrar_windows.h>

namespace u {

// Native side of UBle on Windows ("u/ble" + scan / events): BluetoothLEAdvertisementWatcher for scanning,
// BluetoothLEDevice + GATT for connections. Device ids are the Bluetooth address ("AA:BB:CC:DD:EE:FF").
void RegisterBle(flutter::PluginRegistrarWindows* registrar);

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_BLE_H_
