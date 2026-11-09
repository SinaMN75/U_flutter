import "dart:io";

import "package:u/src/cli/archive.dart";
import "package:u/src/cli/commands.dart";
import "package:u/src/cli/core.dart";

enum _Output {
  apk("Android APK (arm64 + arm)", Target.android),
  aab("Android App Bundle for Google Play", Target.android),
  ios("iOS archive in Xcode Organizer", Target.ios),
  ipa("iOS .ipa (needs signing)", Target.ios),
  macos("macOS .app zipped", Target.macos),
  windows("Windows release folder zipped", Target.windows),
  linux("Linux bundle zipped", Target.linux),
  web("Web build zipped, with and without the CanvasKit CDN", Target.web);

  const _Output(this.summary, this.platform);

  final String summary;
  final Target platform;

  static _Output parse(String v) => switch (v.toLowerCase()) {
    "apk" || "android" => apk,
    "aab" || "appbundle" || "bundle" => aab,
    "ios" || "archive" || "xcarchive" => ios,
    "ipa" => ipa,
    "macos" || "mac" || "osx" => macos,
    "windows" || "win" => windows,
    "linux" => linux,
    "web" => web,
    _ => throw CliException("Unknown build target \"$v\". Use: apk, aab, ios, ipa, macos, windows, linux, web or all."),
  };

  /// The operating system this output can be built on, or null for any.
  String? get host => switch (this) {
    ios || ipa || macos => "macos",
    windows => "windows",
    linux => "linux",
    _ => null,
  };
}

String _desktop(Project p) {
  final String? home = Platform.environment[Platform.isWindows ? "USERPROFILE" : "HOME"];
  if (home != null && Directory("$home/Desktop").existsSync()) {
    return "$home/Desktop";
  }
  return p.path("build/release");
}

Future<void> _run(Project p, String exe, List<String> args) async {
  Out.line("\n${Out.cyan("\$ $exe ${args.join(" ")}")}");
  if (p.dryRun) {
    return;
  }
  final Process process = await Process.start(exe, args, workingDirectory: p.root, runInShell: Platform.isWindows, mode: ProcessStartMode.inheritStdio);
  final int code = await process.exitCode;
  if (code != 0) {
    throw CliException("$exe ${args.join(" ")} failed (exit code $code).");
  }
}

/// The only folder inside [parent] matching [test], e.g. the x64 or arm64 build folder.
String _find(Project p, String parent, bool Function(String name) test, String what) {
  final Directory d = Directory(p.path(parent));
  final List<FileSystemEntity> found = d.existsSync() ? d.listSync().where((FileSystemEntity e) => test(e.uri.pathSegments.where((String s) => s.isNotEmpty).last)).toList() : <FileSystemEntity>[];
  if (found.isEmpty) {
    throw CliException("$what not found in $parent.");
  }
  return found.first.path.replaceAll(RegExp(r"[/\\]$"), "");
}

// =============================================================================================
// build

Future<void> cmdBuild(Project p, Args a) async {
  if (a.positional.isEmpty) {
    throw CliException("Missing build target.\n  Usage: dart run u:app build <apk|aab|ios|ipa|macos|windows|linux|web|all>... [--out <folder>] [--no-clean]");
  }
  final String os = Platform.operatingSystem;
  final List<_Output> outputs = <_Output>[];
  for (final String t in a.positional.expand((String v) => v.split(",")).where((String v) => v.trim().isNotEmpty)) {
    if (t.toLowerCase() == "all") {
      outputs.addAll(<_Output>[_Output.apk, _Output.ios, _Output.macos, _Output.windows, _Output.linux, _Output.web].where((_Output o) => (o.host == null || o.host == os) && p.present(o.platform)));
    } else {
      outputs.add(_Output.parse(t));
    }
  }
  final List<_Output> targets = outputs.toSet().toList();
  for (final _Output o in targets) {
    if (o.host != null && o.host != os) {
      throw CliException("${o.name} can only be built on ${o.host} (this is $os).");
    }
    if (!p.present(o.platform)) {
      throw CliException("This app has no ${o.platform.id}/ folder. Add it with: flutter create --platforms=${o.platform.id} .");
    }
  }
  final String name = RegExp(r"^name:[ \t]*(\S+)", multiLine: true).firstMatch(p.read("pubspec.yaml") ?? "")?.group(1) ?? "app";
  final String full = pubspecVersion(p) ?? "1.0.0+1";
  final String v = full.split("+").first.replaceAll(".", "");
  final String out = a.option("out") != null ? Directory(a.option("out")!).absolute.path : _desktop(p);
  final String base = "$out/$name-$v";
  final List<String> extra = (a.option("args") ?? "").split(" ").where((String s) => s.isNotEmpty).toList();
  final List<String> made = <String>[];

  Out.line("${Out.bold("$name $full")} → ${targets.map((_Output o) => o.name).join(", ")}  ${Out.dim("(files go to $out)")}");
  if (!a.flag("no-clean")) {
    await _run(p, "flutter", <String>["clean"]);
  }
  await _run(p, "flutter", <String>["pub", "get"]);
  if (!p.dryRun) {
    Directory(out).createSync(recursive: true);
  }

  void copy(String from, String to) {
    if (!p.dryRun) {
      File(File(from).isAbsolute ? from : p.path(from)).copySync(to);
    }
    made.add(to);
  }

  void zip(String dir, String to) {
    if (!p.dryRun) {
      zipFolder(dir, to);
    }
    made.add(to);
  }

  for (final _Output o in targets) {
    Out.header(o.summary);
    switch (o) {
      case _Output.apk:
        await _run(p, "flutter", <String>["build", "apk", "--target-platform", "android-arm64,android-arm", "--release", ...extra]);
        copy("build/app/outputs/flutter-apk/app-release.apk", "$base.apk");
      case _Output.aab:
        await _run(p, "flutter", <String>["build", "appbundle", "--release", ...extra]);
        copy("build/app/outputs/bundle/release/app-release.aab", "$base.aab");
      case _Output.ios:
        await _run(p, "flutter", <String>["build", "ios", "--release", "--no-codesign", ...extra]);
        final DateTime now = DateTime.now();
        final String day = "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";
        final String archive = "${Platform.environment["HOME"]}/Library/Developer/Xcode/Archives/$day/$name-$v.xcarchive";
        await _run(p, "xcodebuild", <String>["-workspace", "ios/Runner.xcworkspace", "-scheme", "Runner", "-configuration", "Release", "-archivePath", archive, "archive"]);
        made.add(archive);
        await _run(p, "open", <String>["-a", "Xcode"]);
      case _Output.ipa:
        await _run(p, "flutter", <String>["build", "ipa", "--release", ...extra]);
        copy(p.dryRun ? "build/ios/ipa/$name.ipa" : _find(p, "build/ios/ipa", (String n) => n.endsWith(".ipa"), ".ipa"), "$base.ipa");
      case _Output.macos:
        await _run(p, "flutter", <String>["build", "macos", "--release", ...extra]);
        final String app = p.dryRun ? "build/macos/Build/Products/Release/$name.app" : _find(p, "build/macos/Build/Products/Release", (String n) => n.endsWith(".app"), ".app");
        await _run(p, "ditto", <String>["-c", "-k", "--keepParent", app, "$base-macos.zip"]);
        made.add("$base-macos.zip");
      case _Output.windows:
        await _run(p, "flutter", <String>["build", "windows", "--release", ...extra]);
        zip(p.dryRun ? "build/windows/x64/runner/Release" : "${_find(p, "build/windows", (String n) => n == "x64" || n == "arm64", "Windows build")}/runner/Release", "$base-windows.zip");
      case _Output.linux:
        await _run(p, "flutter", <String>["build", "linux", "--release", ...extra]);
        zip(p.dryRun ? "build/linux/x64/release/bundle" : "${_find(p, "build/linux", (String n) => n == "x64" || n == "arm64", "Linux build")}/release/bundle", "$base-linux.zip");
      case _Output.web:
        final String mode = a.option("web") ?? "both";
        if (!<String>["both", "cdn", "no-cdn"].contains(mode)) {
          throw CliException("--web takes both, cdn or no-cdn.");
        }
        for (final bool cdn in <bool>[if (mode != "no-cdn") true, if (mode != "cdn") false]) {
          await _run(p, "flutter", <String>["build", "web", "--release", if (!cdn) "--no-web-resources-cdn", "--dart-define=U_BUILD_ID=$full", ...extra]);
          zip(p.path("build/web"), cdn ? "$base-web.zip" : "$base-web-no-cdn.zip");
        }
    }
  }
  Out.header(p.dryRun ? "Would create" : "Created");
  for (final String f in made) {
    Out.line("  ${p.dryRun ? Out.yellow("~") : Out.green("✓")} $f");
  }
}
