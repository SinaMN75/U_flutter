#ifndef FLUTTER_PLUGIN_U_CAMERA_H_
#define FLUTTER_PLUGIN_U_CAMERA_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

// Registers the "u/camera" method channel on this registrar. Backed by V4L2,
// so it works on desktop Linux, embedded boards and the Raspberry Pi without
// any extra runtime dependency.
void u_camera_register(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_U_CAMERA_H_
