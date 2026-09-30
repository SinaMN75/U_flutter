#ifndef FLUTTER_PLUGIN_U_LAUNCH_H_
#define FLUTTER_PLUGIN_U_LAUNCH_H_

#include <flutter/plugin_registrar_windows.h>

namespace u {

// Native side of ULaunch on Windows ("u/launch" + "u/launch/events"): ShellExecute, protocol
// associations, ms-settings: pages, Simple MAPI for mail with attachments, Microsoft Store pages,
// and deep links passed on the command line.
void RegisterLaunch(flutter::PluginRegistrarWindows* registrar);

// Native side of UShare on Windows ("u/share" + "u/share/received"): the Windows share sheet
// through DataTransferManager, and files passed on the command line ("Open with").
void RegisterShare(flutter::PluginRegistrarWindows* registrar);

}  // namespace u

#endif  // FLUTTER_PLUGIN_U_LAUNCH_H_
