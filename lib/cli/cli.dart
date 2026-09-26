import "dart:async";
import "dart:io";

import "package:u/cli/commands.dart";
import "package:u/cli/core.dart";
import "package:u/cli/report.dart";

class _Command {
  const _Command(this.name, this.usage, this.summary, this.run, {this.examples = const <String>[], this.aliases = const <String>[]});

  final String name;
  final String usage;
  final String summary;
  final FutureOr<void> Function(Project p, Args a) run;
  final List<String> examples;
  final List<String> aliases;
}

const List<_Command> _commands = <_Command>[
  _Command("info", "info", "Show the name, id, version, SDK levels, permissions… of every platform", cmdInfo, aliases: <String>["show", "status"]),
  _Command("doctor", "doctor", "Find template leftovers and settings that disagree across platforms", cmdDoctor, aliases: <String>["check"]),
  _Command(
    "name",
    "name <name> [--short <web short name>]",
    "App name users see (launcher, home screen, window title, browser tab)",
    cmdName,
    examples: <String>["name \"My Shop\"", "name \"فروشگاه من\" --platforms android,ios"],
    aliases: <String>["rename", "label"],
  ),
  _Command(
    "id",
    "id <com.company.app> [--android <id>] [--ios <id>] [--macos <id>] [--linux <id>]",
    "applicationId / bundle id (moves MainActivity into the new package)",
    cmdId,
    examples: <String>["id com.sinamn75.shop", "id com.sinamn75.shop --ios com.sinamn75.shopIos"],
    aliases: <String>["bundle-id", "package", "app-id"],
  ),
  _Command(
    "min-sdk",
    "min-sdk <platform> <version> [<platform> <version> ...]",
    "Minimum OS version: android (API level), ios, macos",
    cmdMinSdk,
    examples: <String>["min-sdk android 24", "min-sdk ios 18", "min-sdk android 24 ios 16 macos 12", "min-sdk android default"],
    aliases: <String>["min", "minsdk", "min-os"],
  ),
  _Command("target-sdk", "target-sdk <level|default>", "Android targetSdk", cmdTargetSdk, examples: <String>["target-sdk 36"]),
  _Command("compile-sdk", "compile-sdk <level|default>", "Android compileSdk", cmdCompileSdk, examples: <String>["compile-sdk 36"]),
  _Command("ndk", "ndk <version|default>", "Android ndkVersion (fixes \"plugin requires a newer NDK\" errors)", cmdNdk, examples: <String>["ndk 27.0.12077973"]),
  _Command("java", "java <8|11|17|21>", "Android Java source/target + Kotlin jvmTarget", cmdJava, examples: <String>["java 17"]),
  _Command("version", "version <x.y.z+build>", "Set the app version in pubspec.yaml (every platform reads it)", cmdVersion, examples: <String>["version 1.4.0+27"]),
  _Command(
    "bump",
    "bump [major|minor|patch|build]",
    "Increase the version; the build number always goes up",
    cmdBump,
    examples: <String>["bump", "bump patch", "bump minor", "bump major"],
  ),
  _Command("description", "description <text>", "pubspec + web manifest / meta description", cmdDescription, examples: <String>["description \"Order food in two taps\""]),
  _Command(
    "permission",
    "permission [add|remove|list] <names...> [--message <iOS/macOS prompt text>]",
    "Friendly cross-platform permissions: camera, internet, location, photos…",
    cmdPermission,
    examples: <String>[
      "permission list",
      "permission add camera microphone",
      "permission add internet,location,notifications",
      "permission add location --message \"We show stores near you\"",
      "permission remove contacts",
    ],
    aliases: <String>["permissions", "perm"],
  ),
  _Command("orientation", "orientation <portrait|landscape|all>", "Lock or free screen orientation (Android, iOS, web)", cmdOrientation, examples: <String>["orientation portrait"]),
  _Command(
    "deep-link",
    "deep-link [add|remove] <scheme> [--host <host>]",
    "Register a custom URL scheme (myapp://) on Android, iOS, macOS",
    cmdDeepLink,
    examples: <String>["deep-link myapp", "deep-link myapp --host open", "deep-link remove myapp"],
    aliases: <String>["scheme", "url-scheme"],
  ),
  _Command("binary", "binary <name>", "Linux / Windows executable file name", cmdBinary, examples: <String>["binary my_shop"], aliases: <String>["exe"]),
  _Command("team", "team <TEAM_ID>", "Apple DEVELOPMENT_TEAM for iOS + macOS signing", cmdTeam, examples: <String>["team ABCDE12345"]),
  _Command("company", "company <name>", "Windows CompanyName", cmdCompany, examples: <String>["company \"Sina Co.\""]),
  _Command("copyright", "copyright <text>", "macOS PRODUCT_COPYRIGHT + Windows LegalCopyright", cmdCopyright, examples: <String>["copyright \"© 2026 Sina Co.\""]),
  _Command("web-color", "web-color <#hex> [--background <#hex>]", "Web manifest theme/background color + <meta theme-color>", cmdWebColor, examples: <String>["web-color \"#0175C2\""]),
  _Command(
    "signing",
    "signing --create   |   signing",
    "Android release signing: create a .jks step by step (like Android Studio) or use an existing one",
    cmdSigning,
    examples: <String>["signing --create", "signing"],
  ),
];

_Command? _find(String name) {
  final String n = name.toLowerCase();
  for (final _Command c in _commands) {
    if (c.name == n || c.aliases.contains(n)) {
      return c;
    }
  }
  return null;
}

void _help() {
  Out.line("${Out.bold("u app")}: change your Flutter app's native settings on all 6 platforms from one command.\n");
  Out.line("${Out.bold("Usage")}  dart run u:app <command> [arguments] [--platforms android,ios,...] [--dry-run]\n");
  Out.line(Out.bold("Commands"));
  for (final _Command c in _commands) {
    Out.line("  ${Out.cyan(c.name.padRight(13))}${c.summary}");
  }
  Out.line("\n${Out.bold("Global options")}");
  Out.line("  ${"--platforms".padRight(13)}Only touch these platforms, e.g. --platforms android,ios");
  Out.line("  ${"--dry-run".padRight(13)}Show what would change without writing anything (-n)");
  Out.line("  ${"--help".padRight(13)}Help for a command, e.g. dart run u:app min-sdk --help");
  Out.line("\n${Out.bold("Examples")}");
  for (final String e in <String>["info", "name \"My Shop\"", "id com.sinamn75.shop", "min-sdk android 24 ios 18", "permission add camera location internet", "bump patch"]) {
    Out.line("  dart run u:app $e");
  }
  Out.line();
}

void _commandHelp(_Command c) {
  Out.line("${Out.bold(c.name)}: ${c.summary}\n");
  Out.line("${Out.bold("Usage")}  dart run u:app ${c.usage}");
  if (c.aliases.isNotEmpty) {
    Out.line("${Out.bold("Aliases")}  ${c.aliases.join(", ")}");
  }
  if (c.examples.isNotEmpty) {
    Out.line("\n${Out.bold("Examples")}");
    for (final String e in c.examples) {
      Out.line("  dart run u:app $e");
    }
  }
  Out.line("\nAdd --dry-run to preview, --platforms android,ios to limit the platforms.\n");
}

/// Entry point for `dart run u:app`. Returns the process exit code.
Future<int> runCli(List<String> raw) async {
  final Args args = Args(raw);
  if (args.positional.isEmpty || args.positional.first == "help") {
    final _Command? c = args.positional.length > 1 ? _find(args.positional[1]) : null;
    if (c != null) {
      _commandHelp(c);
    } else {
      _help();
    }
    return 0;
  }
  final _Command? command = _find(args.positional.first);
  if (command == null) {
    Out.error("Unknown command \"${args.positional.first}\". Run `dart run u:app help` to see all commands.");
    return 64;
  }
  if (args.flag("help")) {
    _commandHelp(command);
    return 0;
  }
  args.positional.removeAt(0);
  try {
    final Project project = Project.find(dryRun: args.flag("dry-run"), only: args.platforms);
    await command.run(project, args);
    if (project.dryRun) {
      Out.line("\n${Out.yellow("Dry run: nothing was written.")} ${project.changes} change(s) would be made.");
    } else if (command.name != "info" && command.name != "doctor" && !(command.name == "permission" && (args.positional.isEmpty || args.positional.first == "list"))) {
      Out.line("\n${project.changes == 0 ? Out.dim("Nothing to change.") : Out.green("Done: ${project.changes} change(s).")}");
    }
    return 0;
  } on CliException catch (e) {
    Out.error(e.message);
    return 1;
  } on FileSystemException catch (e) {
    Out.error("${e.message}: ${e.path ?? ""} ${e.osError?.message ?? ""}");
    return 1;
  }
}
