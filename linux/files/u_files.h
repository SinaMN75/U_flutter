#ifndef FLUTTER_PLUGIN_U_FILES_H_
#define FLUTTER_PLUGIN_U_FILES_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

// Registers the "u/files" method channel: free space (statvfs), the GTK save
// dialog, open / show in the file manager (FileManager1 over D-Bus), sleep
// inhibition through logind while downloads run, and the vault key in the
// Secret Service when libsecret is available at build time.
void u_files_register(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_U_FILES_H_
