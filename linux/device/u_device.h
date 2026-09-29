#ifndef FLUTTER_PLUGIN_U_DEVICE_H_
#define FLUTTER_PLUGIN_U_DEVICE_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

// Registers "u/device" and "u/device/network": device info from DMI / os-release /
// sysconf, package info from the running binary, network state from GNetworkMonitor
// plus the kernel's default routes, battery from /sys/class/power_supply.
void u_device_register(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_U_DEVICE_H_
