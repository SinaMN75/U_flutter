import "dart:convert";
import "dart:math" as math;

import "package:u/src/cli/core.dart";
import "package:u/src/cli/image.dart";
import "package:u/src/cli/platforms.dart";

const String androidRes = "android/app/src/main/res";

/// Android density folders and their scale against mdpi.
const Map<String, double> androidDensities = <String, double>{"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4};

/// Xcode's asset catalog JSON layout (`"key" : value`).
String xcodeJson(Map<String, dynamic> json) => "${const JsonEncoder.withIndent("  ").convert(json).replaceAll("\": ", "\" : ")}\n";

const Map<String, dynamic> xcodeInfo = <String, dynamic>{"version": 1, "author": "xcode"};

/// A color, or an image when the value is a path.
class Fill {
  Fill.color(Rgba this.color) : image = null;

  Fill.image(Bitmap this.image) : color = null;

  static Fill? parse(Project p, String? value) {
    if (value == null) {
      return null;
    }
    return Rgba.isColor(value) ? Fill.color(Rgba.parse(value)) : Fill.image(Bitmap.load(p, value));
  }

  final Rgba? color;
  final Bitmap? image;

  /// A [size]×[size] square: the color, or the image scaled to cover it.
  Bitmap square(int size) {
    if (color != null) {
      return Bitmap(size, size, color!);
    }
    final Bitmap img = image!;
    final double s = math.max(size / img.width, size / img.height);
    final Bitmap scaled = img.resize(math.max(size, (img.width * s).round()), math.max(size, (img.height * s).round()));
    return scaled.crop((scaled.width - size) ~/ 2, (scaled.height - size) ~/ 2, size, size);
  }
}

double _inset(Args a, String name, double fallback) {
  final String? v = a.option(name);
  if (v == null) {
    return fallback;
  }
  final double? n = double.tryParse(v.replaceAll("%", ""));
  if (n == null || n < 0 || n >= 50) {
    throw CliException("--$name takes a percentage of each side between 0 and 49, e.g. --$name 16");
  }
  return n / 100;
}

// =============================================================================================
// icon

Future<void> cmdIcon(Project p, Args a) async {
  const String usage = "dart run u:app icon <image.png> [--background <#hex|image.png>] [--foreground <image.png>] [--monochrome [image.png]]";
  if (a.positional.isEmpty) {
    throw CliException("Missing image.\n  Usage: $usage");
  }
  final Bitmap source = _squared(Bitmap.load(p, a.positional.first));
  if (source.width < 1024) {
    Out.warn("The image is ${source.width}×${source.height}. Use 1024×1024 or larger so big icons stay sharp.");
  }
  final Fill? background = Fill.parse(p, a.option("background"));
  final String? fgPath = a.option("foreground");
  final Bitmap foreground = fgPath == null ? source : _squared(Bitmap.load(p, fgPath));
  final String? mono = a.option("monochrome") ?? (a.flag("monochrome") ? "auto" : null);
  final Bitmap? monochrome = mono == null ? null : (mono == "auto" ? foreground.tinted(Rgba.white) : _squared(Bitmap.load(p, mono)));
  final double inset = _inset(a, "inset", 0.16);
  final Rgba flat = a.option("ios-background") != null ? Rgba.parse(a.option("ios-background")!) : (background?.color ?? Rgba.white);

  p.section(Target.android, () => _androidIcon(p, source, background, foreground, monochrome, inset));
  p.section(Target.ios, () => _iosIcon(p, source, flat));
  p.section(Target.macos, () => _macosIcon(p, source));
  p.section(Target.windows, () => p.writeBytes("windows/runner/resources/app_icon.ico", encodeIco(source, <int>[16, 20, 24, 32, 40, 48, 64, 96, 128, 256]), "app_icon.ico (16–256 px)"));
  p.section(Target.linux, () => _linuxIcon(p, source));
  p.section(Target.web, () => _webIcon(p, source, background, foreground));
}

/// Pads a non-square image with transparency to a centered square.
Bitmap _squared(Bitmap img) {
  if (img.width == img.height) {
    return img;
  }
  final int size = math.max(img.width, img.height);
  return Bitmap(size, size)..draw(img, (size - img.width) ~/ 2, (size - img.height) ~/ 2);
}

void _androidIcon(Project p, Bitmap source, Fill? background, Bitmap foreground, Bitmap? monochrome, double inset) {
  for (final MapEntry<String, double> d in androidDensities.entries) {
    final int size = (48 * d.value).round();
    p.writeBytes("$androidRes/mipmap-${d.key}/ic_launcher.png", Bitmap.square(source, size).png(), "ic_launcher.png ($size px)");
  }
  p.edit(AndroidFiles.manifest, (String t) {
    final (int, int)? app = Xml.openTag(t, "application");
    if (app == null) {
      throw EditSkip("<application> not found");
    }
    String tag = Xml.setAttr(t.substring(app.$1, app.$2), "android:icon", "@mipmap/ic_launcher");
    if (Xml.attr(tag, "android:roundIcon") != null) {
      tag = Xml.setAttr(tag, "android:roundIcon", "@mipmap/ic_launcher");
    }
    return t.replaceRange(app.$1, app.$2, tag);
  }, "android:icon = @mipmap/ic_launcher");

  const String adaptive = "$androidRes/mipmap-anydpi-v26/ic_launcher.xml";
  if (background == null) {
    p.delete(adaptive, "removed (no --background, so Android uses the plain icon)");
    p.delete("$androidRes/mipmap-anydpi-v26/ic_launcher_round.xml", "removed");
    p.delete("$androidRes/values/ic_launcher_background.xml", "removed");
    for (final String d in androidDensities.keys) {
      for (final String n in <String>["foreground", "background", "monochrome"]) {
        p.delete("$androidRes/drawable-$d/ic_launcher_$n.png", "removed");
      }
      p.pruneEmptyDirs("$androidRes/drawable-$d", androidRes);
    }
    p.pruneEmptyDirs("$androidRes/mipmap-anydpi-v26", androidRes);
    Out.note("Add --background \"#FFFFFF\" (or an image) for an adaptive icon that fills every launcher shape.");
    return;
  }
  for (final MapEntry<String, double> d in androidDensities.entries) {
    final int size = (108 * d.value).round();
    p.writeBytes("$androidRes/drawable-${d.key}/ic_launcher_foreground.png", Bitmap.square(foreground, size, inset: inset).png(), "adaptive foreground ($size px)");
    if (background.image != null) {
      p.writeBytes("$androidRes/drawable-${d.key}/ic_launcher_background.png", background.square(size).png(), "adaptive background ($size px)");
    } else {
      p.delete("$androidRes/drawable-${d.key}/ic_launcher_background.png", "removed (background is a color)");
    }
    if (monochrome != null) {
      p.writeBytes("$androidRes/drawable-${d.key}/ic_launcher_monochrome.png", Bitmap.square(monochrome, size, inset: inset).png(), "themed icon ($size px)");
    } else {
      p.delete("$androidRes/drawable-${d.key}/ic_launcher_monochrome.png", "removed");
    }
  }
  if (background.color != null) {
    p.write(
      "$androidRes/values/ic_launcher_background.xml",
      "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources>\n    <color name=\"ic_launcher_background\">${background.color!.hex}</color>\n</resources>\n",
      "ic_launcher_background = ${background.color!.hex}",
    );
  } else {
    p.delete("$androidRes/values/ic_launcher_background.xml", "removed (background is an image)");
  }
  final String bg = background.color != null ? "@color/ic_launcher_background" : "@drawable/ic_launcher_background";
  final String xml =
      "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
      "<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">\n"
      "    <background android:drawable=\"$bg\" />\n"
      "    <foreground android:drawable=\"@drawable/ic_launcher_foreground\" />\n"
      "${monochrome != null ? "    <monochrome android:drawable=\"@drawable/ic_launcher_monochrome\" />\n" : ""}"
      "</adaptive-icon>\n";
  p.write(adaptive, xml, "adaptive icon${monochrome != null ? " + themed (Android 13+)" : ""}");
  if (p.exists("$androidRes/mipmap-anydpi-v26/ic_launcher_round.xml")) {
    p.write("$androidRes/mipmap-anydpi-v26/ic_launcher_round.xml", xml, "adaptive round icon");
  }
}

const List<(String, String, String, int)> _iosIcons = <(String, String, String, int)>[
  ("20x20", "iphone", "2x", 40),
  ("20x20", "iphone", "3x", 60),
  ("29x29", "iphone", "1x", 29),
  ("29x29", "iphone", "2x", 58),
  ("29x29", "iphone", "3x", 87),
  ("40x40", "iphone", "2x", 80),
  ("40x40", "iphone", "3x", 120),
  ("60x60", "iphone", "2x", 120),
  ("60x60", "iphone", "3x", 180),
  ("20x20", "ipad", "1x", 20),
  ("20x20", "ipad", "2x", 40),
  ("29x29", "ipad", "1x", 29),
  ("29x29", "ipad", "2x", 58),
  ("40x40", "ipad", "1x", 40),
  ("40x40", "ipad", "2x", 80),
  ("76x76", "ipad", "1x", 76),
  ("76x76", "ipad", "2x", 152),
  ("83.5x83.5", "ipad", "2x", 167),
  ("1024x1024", "ios-marketing", "1x", 1024),
];

void _iconSet(Project p, String dir, List<(String, String, String, int)> entries, String Function(String size, String scale, int px) fileName, Bitmap Function(int px) render) {
  final Set<String> files = <String>{};
  final List<Map<String, dynamic>> images = <Map<String, dynamic>>[];
  for (final (String size, String idiom, String scale, int px) in entries) {
    final String name = fileName(size, scale, px);
    images.add(<String, dynamic>{"size": size, "idiom": idiom, "filename": name, "scale": scale});
    if (files.add(name)) {
      p.writeBytes("$dir/$name", render(px).png(), "$name ($px px)");
    }
  }
  p.write("$dir/Contents.json", xcodeJson(<String, dynamic>{"images": images, "info": xcodeInfo}), "Contents.json");
  if (p.exists(dir)) {
    for (final String old in p.dirFiles(dir)) {
      if (old.toLowerCase().endsWith(".png") && !files.contains(old)) {
        p.delete("$dir/$old", "removed (not in the icon set)");
      }
    }
  }
}

void _iosIcon(Project p, Bitmap source, Rgba flat) {
  _iconSet(p, "ios/Runner/Assets.xcassets/AppIcon.appiconset", _iosIcons, (String size, String scale, int _) => "Icon-App-$size@$scale.png", (int px) => Bitmap.square(source, px).flatten(flat));
  if (!source.opaque) {
    Out.note("Transparent parts are filled with ${flat.hex} (the App Store rejects icons with alpha). Change it with --ios-background.");
  }
}

void _macosIcon(Project p, Bitmap source) {
  const List<(String, String, String, int)> entries = <(String, String, String, int)>[
    ("16x16", "mac", "1x", 16),
    ("16x16", "mac", "2x", 32),
    ("32x32", "mac", "1x", 32),
    ("32x32", "mac", "2x", 64),
    ("128x128", "mac", "1x", 128),
    ("128x128", "mac", "2x", 256),
    ("256x256", "mac", "1x", 256),
    ("256x256", "mac", "2x", 512),
    ("512x512", "mac", "1x", 512),
    ("512x512", "mac", "2x", 1024),
  ];
  _iconSet(p, "macos/Runner/Assets.xcassets/AppIcon.appiconset", entries, (String _, String _, int px) => "app_icon_$px.png", (int px) => Bitmap.square(source, px));
}

const String _linuxIconFile = "runner/resources/app_icon.png";

void _linuxIcon(Project p, Bitmap source) {
  p.writeBytes("linux/$_linuxIconFile", Bitmap.square(source, 512).png(), "app_icon.png (512 px)");
  p.edit(LinuxFiles.cmake, (String t) {
    if (t.contains(_linuxIconFile)) {
      return t;
    }
    final Match? m = RegExp(r"install\(FILES \x22\$\{FLUTTER_ICU_DATA_FILE\}\x22[^)]*\)\n").firstMatch(t);
    if (m == null) {
      throw EditSkip("ICU data install rule not found");
    }
    return t.replaceRange(m.end, m.end, "\ninstall(FILES \"$_linuxIconFile\" DESTINATION \"\${INSTALL_BUNDLE_DATA_DIR}\"\n  COMPONENT Runtime)\n");
  }, "installs app_icon.png into the bundle");
  p.edit(LinuxFiles.app, (String t) {
    if (t.contains("gtk_window_set_icon_from_file")) {
      return t;
    }
    final Match? m = RegExp(r"[ \t]*gtk_window_set_default_size\(window[^;]*;\n").firstMatch(t);
    if (m == null) {
      throw EditSkip("gtk_window_set_default_size not found");
    }
    const String code =
        "\n  g_autofree gchar* exe_path = g_file_read_link(\"/proc/self/exe\", nullptr);\n"
        "  g_autofree gchar* exe_dir = g_path_get_dirname(exe_path);\n"
        "  g_autofree gchar* icon_path = g_build_filename(exe_dir, \"data\", \"app_icon.png\", nullptr);\n"
        "  gtk_window_set_icon_from_file(window, icon_path, nullptr);\n";
    return t.replaceRange(m.end, m.end, code);
  }, "window icon");
}

void _webIcon(Project p, Bitmap source, Fill? background, Bitmap foreground) {
  p.writeBytes("web/favicon.png", Bitmap.square(source, 32).png(), "favicon.png (32 px)");
  final Fill fill = background ?? Fill.color(Rgba.white);
  for (final int size in <int>[192, 512]) {
    p.writeBytes("web/icons/Icon-$size.png", Bitmap.square(source, size).png(), "Icon-$size.png");
    final Bitmap maskable = fill.square(size)..draw(Bitmap.square(foreground, size, inset: 0.1), 0, 0);
    p.writeBytes("web/icons/Icon-maskable-$size.png", maskable.png(), "Icon-maskable-$size.png (80% safe zone)");
  }
}
