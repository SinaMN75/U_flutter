import "dart:io";

import "package:u/cli/cli.dart";

/// `dart run u:app <command>`: edits the native settings of the Flutter app it runs in.
/// Run `dart run u:app help` for the full command list.
Future<void> main(List<String> args) async => exitCode = await runCli(args);
