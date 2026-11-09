import "dart:math" as math;

import "package:u/src/cli/core.dart";
import "package:u/src/cli/icons.dart";
import "package:u/src/cli/image.dart";
import "package:u/src/cli/platforms.dart";
import "package:u/src/cli/plist.dart";

const String _launchImages = "ios/Runner/Assets.xcassets/LaunchImage.imageset";
const String _launchBackground = "ios/Runner/Assets.xcassets/LaunchBackground.imageset";
const String _brandingImages = "ios/Runner/Assets.xcassets/BrandingImage.imageset";
const String _storyboard = "ios/Runner/Base.lproj/LaunchScreen.storyboard";
const String _webImages = "web/splash";
const String _webStart = "<!-- u:splash -->";
const String _webEnd = "<!-- /u:splash -->";

/// One look of the splash screen (light or dark).
class _Look {
  _Look(this.color, this.image, this.background, this.branding, this.android12, this.iconBackground);

  final Rgba color;
  final Bitmap? image;
  final Bitmap? background;
  final Bitmap? branding;
  final Bitmap? android12;
  final Rgba? iconBackground;
}

class _Splash {
  _Splash(this.light, this.dark, this.size, this.brandingSize, {required this.fullscreen});

  final _Look light;
  final _Look? dark;
  final double size;
  final double brandingSize;
  final bool fullscreen;

  Bitmap? get image => light.image;

  double heightOf(Bitmap img, double width) => width * img.height / img.width;
}

Bitmap _atWidth(Bitmap img, double width) => img.resize(math.max(1, width.round()), math.max(1, (width * img.height / img.width).round()));

// =============================================================================================
// splash

void cmdSplash(Project p, Args a) {
  if (a.positional.isNotEmpty && a.positional.first == "remove") {
    _remove(p);
    return;
  }
  if (a.positional.isNotEmpty) {
    throw CliException("Unknown argument \"${a.positional.first}\".\n  Usage: dart run u:app splash --color \"#FFFFFF\" --image logo.png   |   dart run u:app splash remove");
  }
  Bitmap? img(String key) => a.option(key) == null ? null : Bitmap.load(p, a.option(key)!);
  Rgba? col(String key) => a.option(key) == null ? null : Rgba.parse(a.option(key)!);
  final Bitmap? image = img("image");
  final Bitmap? branding = img("branding");
  final double size = a.option("size") != null ? (double.tryParse(a.option("size")!) ?? (throw CliException("--size takes a width in dp, e.g. --size 160"))) : (image == null ? 0 : image.width / 4);
  final double brandingSize = branding == null ? 0 : branding.width / 4;
  final _Look light = _Look(col("color") ?? Rgba.white, image, img("background-image"), branding, img("android12-image"), col("icon-background"));
  final bool hasDark = <String>["dark-color", "dark-image", "dark-background-image", "dark-branding", "android12-dark-image", "dark-icon-background"].any((String k) => a.option(k) != null);
  final _Look? dark = hasDark
      ? _Look(
          col("dark-color") ?? light.color,
          img("dark-image") ?? light.image,
          img("dark-background-image") ?? (a.option("dark-color") != null ? null : light.background),
          img("dark-branding") ?? light.branding,
          img("android12-dark-image") ?? light.android12,
          col("dark-icon-background") ?? light.iconBackground,
        )
      : null;
  final _Splash s = _Splash(light, dark, size, brandingSize, fullscreen: a.flag("fullscreen"));
  if (image != null) {
    Out.note("Logo: ${size.toStringAsFixed(0)}×${s.heightOf(image, size).toStringAsFixed(0)} dp (change with --size).");
  }
  p.section(Target.android, () => _android(p, s));
  p.section(Target.ios, () => _ios(p, s));
  p.section(Target.web, () => _web(p, s));
  for (final Target t in <Target>[Target.macos, Target.linux, Target.windows]) {
    if (p.targets(t)) {
      Out.header(t.id);
      Out.note("Desktop windows open on the first Flutter frame, so there is no native splash to set.");
    }
  }
}

// ---------------------------------------------------------------------------------------------
// Android

String _layerList(String body) => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<layer-list xmlns:android=\"http://schemas.android.com/apk/res/android\">\n$body</layer-list>\n";

const String _templateDrawable =
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
    "<!-- Modify this file to customize your launch splash screen -->\n"
    "<layer-list xmlns:android=\"http://schemas.android.com/apk/res/android\">\n"
    "    <item android:drawable=\"@android:color/white\" />\n\n"
    "    <!-- You can insert your own image assets here -->\n"
    "    <!-- <item>\n"
    "        <bitmap\n"
    "            android:gravity=\"center\"\n"
    "            android:src=\"@mipmap/launch_image\" />\n"
    "    </item> -->\n"
    "</layer-list>\n";

String get _templateDrawableV21 => _templateDrawable.replaceFirst("@android:color/white", "?android:colorBackground");

String _colors(_Look l) =>
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources>\n"
    "    <color name=\"splash_background\">${l.color.hex}</color>\n"
    "${l.iconBackground != null ? "    <color name=\"splash_icon_background\">${l.iconBackground!.hex}</color>\n" : ""}"
    "</resources>\n";

/// Writes [name].png into every density folder (`drawable-night-*` for [night]), or deletes it when [img] is null.
void _densities(Project p, String name, Bitmap? Function(double density) render, String what, {bool night = false}) {
  for (final MapEntry<String, double> d in androidDensities.entries) {
    final String rel = "$androidRes/drawable-${night ? "night-" : ""}${d.key}/$name.png";
    final Bitmap? img = render(d.value);
    if (img == null) {
      p.delete(rel, "removed");
    } else {
      p.writeBytes(rel, img.png(), "$what (${img.width}×${img.height})");
    }
  }
}

void _nodpi(Project p, String dir, Bitmap? img, String what) {
  final String rel = "$androidRes/$dir/splash_background.png";
  if (img == null) {
    p.delete(rel, "removed");
  } else {
    p.writeBytes(rel, img.png(), "$what (${img.width}×${img.height})");
  }
  p.pruneEmptyDirs("$androidRes/$dir", androidRes);
}

/// The Android 12+ splash icon: a 288 dp square whose content must fit the 192 dp circle.
Bitmap? _android12Icon(_Look l, double density) {
  final int canvas = (288 * density).round();
  if (l.android12 != null) {
    return Bitmap.square(l.android12!, canvas);
  }
  if (l.image == null) {
    return null;
  }
  final (int x, int y, int w, int h) = l.image!.contentBox;
  final Bitmap content = l.image!.crop(x, y, w, h);
  final double scale = (192 * density) / math.sqrt(w * w + h * h);
  final Bitmap fitted = content.resize(math.max(1, (w * scale).round()), math.max(1, (h * scale).round()));
  return Bitmap(canvas, canvas)..draw(fitted, (canvas - fitted.width) ~/ 2, (canvas - fitted.height) ~/ 2);
}

String _v31Styles(_Splash s, _Look l, {required bool night}) {
  final StringBuffer b = StringBuffer()
    ..write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources>\n")
    ..write("    <style name=\"LaunchTheme\" parent=\"@android:style/${night ? "Theme.Black.NoTitleBar" : "Theme.Light.NoTitleBar"}\">\n")
    ..write("        <item name=\"android:windowSplashScreenBackground\">@color/splash_background</item>\n");
  if (l.image != null || l.android12 != null) {
    b.write("        <item name=\"android:windowSplashScreenAnimatedIcon\">@drawable/splash_icon</item>\n");
  }
  if (l.iconBackground != null) {
    b.write("        <item name=\"android:windowSplashScreenIconBackgroundColor\">@color/splash_icon_background</item>\n");
  }
  if (l.branding != null) {
    b.write("        <item name=\"android:windowSplashScreenBrandingImage\">@drawable/splash_branding</item>\n");
  }
  if (s.fullscreen) {
    b.write("        <item name=\"android:windowFullscreen\">true</item>\n");
  }
  b.write("    </style>\n</resources>\n");
  return b.toString();
}

/// Adds or removes `<item name="[name]">` inside the LaunchTheme style.
String _launchThemeItem(String t, String name, String? value) {
  final Match? style = RegExp(r'<style\s+name="LaunchTheme"[^>]*>([\s\S]*?)</style>').firstMatch(t);
  if (style == null) {
    throw EditSkip("LaunchTheme not found");
  }
  final RegExp item = RegExp('[ \\t]*<item\\s+name="${RegExp.escape(name)}">[^<]*</item>[ \\t]*\\n?');
  String body = style.group(1)!.replaceAll(item, "");
  if (value != null) {
    final String indent = RegExp(r"\n([ \t]+)<item").firstMatch(style.group(1)!)?.group(1) ?? "        ";
    body = "${body.trimRight()}\n$indent<item name=\"$name\">$value</item>\n    ";
  }
  final int start = style.start + style.group(0)!.indexOf(">") + 1;
  return t.replaceRange(start, start + style.group(1)!.length, body);
}

void _android(Project p, _Splash s) {
  final _Look l = s.light;
  final _Look? d = s.dark;
  final StringBuffer items = StringBuffer();
  items.write(
    l.background != null || d?.background != null
        ? "    <item>\n        <bitmap android:gravity=\"fill\" android:src=\"@drawable/splash_background\" />\n    </item>\n"
        : "    <item android:drawable=\"@color/splash_background\" />\n",
  );
  if (l.image != null) {
    items.write("    <item>\n        <bitmap android:gravity=\"center\" android:src=\"@drawable/splash\" />\n    </item>\n");
  }
  if (l.branding != null) {
    items.write("    <item android:bottom=\"24dp\">\n        <bitmap android:gravity=\"bottom\" android:src=\"@drawable/splash_branding\" />\n    </item>\n");
  }
  final String drawable = _layerList(items.toString());
  p.write("$androidRes/drawable/launch_background.xml", drawable, "launch_background.xml");
  p.write("$androidRes/drawable-v21/launch_background.xml", drawable, "launch_background.xml");
  p.write("$androidRes/values/splash.xml", _colors(l), "splash_background = ${l.color.hex}");
  if (d != null) {
    p.write("$androidRes/values-night/splash.xml", _colors(d), "dark splash_background = ${d.color.hex}");
  } else {
    p.delete("$androidRes/values-night/splash.xml", "removed (no dark options)");
  }

  _densities(p, "splash", (double x) => l.image == null ? null : _atWidth(l.image!, s.size * x), "logo");
  _densities(p, "splash", (double x) => d?.image == null || identical(d!.image, l.image) ? null : _atWidth(d.image!, s.size * x), "dark logo", night: true);
  _densities(p, "splash_branding", (double x) => l.branding == null ? null : _atWidth(l.branding!, s.brandingSize * x), "branding");
  _densities(p, "splash_branding", (double x) => d?.branding == null || identical(d!.branding, l.branding) ? null : _atWidth(d.branding!, s.brandingSize * x), "dark branding", night: true);
  _nodpi(p, "drawable-nodpi", l.background ?? (d?.background != null ? Bitmap(1, 1, l.color) : null), "background");
  _nodpi(p, "drawable-night-nodpi", d == null || identical(d.background, l.background) ? null : (d.background ?? Bitmap(1, 1, d.color)), "dark background");
  _densities(p, "splash_icon", (double x) => _android12Icon(l, x), "Android 12+ icon");
  _densities(p, "splash_icon", (double x) => d == null || (identical(d.image, l.image) && identical(d.android12, l.android12)) ? null : _android12Icon(d, x), "dark Android 12+ icon", night: true);

  p.write("$androidRes/values-v31/styles.xml", _v31Styles(s, l, night: false), "Android 12+ splash");
  p.write("$androidRes/values-night-v31/styles.xml", _v31Styles(s, d ?? l, night: true), "Android 12+ dark splash");
  for (final String rel in <String>["$androidRes/values/styles.xml", "$androidRes/values-night/styles.xml"]) {
    p.edit(rel, (String t) => _launchThemeItem(t, "android:windowFullscreen", s.fullscreen ? "true" : null), s.fullscreen ? "fullscreen launch" : "launch keeps the status bar", optional: true);
  }
  for (final String dir in <String>["drawable-night", ...androidDensities.keys.map((String k) => "drawable-night-$k")]) {
    p.pruneEmptyDirs("$androidRes/$dir", androidRes);
  }
  if (l.background != null) {
    Out.note("Android 12+ shows only the color and icon (the system splash has no background image).");
  }
}

// ---------------------------------------------------------------------------------------------
// iOS

Map<String, dynamic> _imageEntry(String file, String scale, {bool dark = false}) => <String, dynamic>{
  "idiom": "universal",
  "filename": file,
  "scale": scale,
  if (dark)
    "appearances": <Map<String, String>>[
      <String, String>{"appearance": "luminosity", "value": "dark"},
    ],
};

/// Writes an image set with @1x/@2x/@3x (and dark variants), removing PNGs it no longer uses.
void _imageSet(Project p, String dir, String name, Bitmap Function(double scale) light, Bitmap Function(double scale)? dark, {List<String> scales = const <String>["1x", "2x", "3x"]}) {
  final List<Map<String, dynamic>> images = <Map<String, dynamic>>[];
  final Set<String> files = <String>{};
  for (final (String prefix, Bitmap Function(double)? render) in <(String, Bitmap Function(double)?)>[(name, light), ("${name}Dark", dark)]) {
    if (render == null) {
      continue;
    }
    for (final String scale in scales) {
      final String file = "$prefix${scale == "1x" ? "" : "@$scale"}.png";
      final Bitmap img = render(double.parse(scale.replaceAll("x", "")));
      p.writeBytes("$dir/$file", img.png(), "$file (${img.width}×${img.height})");
      files.add(file);
      images.add(_imageEntry(file, scale, dark: prefix != name));
    }
  }
  p.write("$dir/Contents.json", xcodeJson(<String, dynamic>{"images": images, "info": xcodeInfo}), "Contents.json");
  if (p.exists(dir)) {
    for (final String old in p.dirFiles(dir)) {
      if (old.endsWith(".png") && !files.contains(old)) {
        p.delete("$dir/$old", "removed");
      }
    }
  }
}

String _srgb(Rgba c) => "red=\"${(c.r / 255).toStringAsFixed(3)}\" green=\"${(c.g / 255).toStringAsFixed(3)}\" blue=\"${(c.b / 255).toStringAsFixed(3)}\" alpha=\"1\"";

String _storyboardFor(_Splash s) {
  final Bitmap? img = s.image;
  final Bitmap? brand = s.light.branding;
  final StringBuffer views = StringBuffer()
    ..write(
      "                            <imageView clipsSubviews=\"YES\" userInteractionEnabled=\"NO\" contentMode=\"scaleAspectFill\" image=\"LaunchBackground\" translatesAutoresizingMaskIntoConstraints=\"NO\" id=\"uBg-Vw-001\"/>\n",
    );
  final StringBuffer constraints = StringBuffer()
    ..write("                            <constraint firstItem=\"uBg-Vw-001\" firstAttribute=\"leading\" secondItem=\"Ze5-6b-2t3\" secondAttribute=\"leading\" id=\"uBg-Cn-001\"/>\n")
    ..write("                            <constraint firstItem=\"uBg-Vw-001\" firstAttribute=\"trailing\" secondItem=\"Ze5-6b-2t3\" secondAttribute=\"trailing\" id=\"uBg-Cn-002\"/>\n")
    ..write("                            <constraint firstItem=\"uBg-Vw-001\" firstAttribute=\"top\" secondItem=\"Ze5-6b-2t3\" secondAttribute=\"top\" id=\"uBg-Cn-003\"/>\n")
    ..write("                            <constraint firstItem=\"uBg-Vw-001\" firstAttribute=\"bottom\" secondItem=\"Ze5-6b-2t3\" secondAttribute=\"bottom\" id=\"uBg-Cn-004\"/>\n");
  final StringBuffer resources = StringBuffer()..write("        <image name=\"LaunchBackground\" width=\"1\" height=\"1\"/>\n");
  if (img != null) {
    views.write(
      "                            <imageView clipsSubviews=\"YES\" userInteractionEnabled=\"NO\" contentMode=\"center\" image=\"LaunchImage\" translatesAutoresizingMaskIntoConstraints=\"NO\" id=\"YRO-k0-Ey4\"/>\n",
    );
    constraints
      ..write("                            <constraint firstItem=\"YRO-k0-Ey4\" firstAttribute=\"centerX\" secondItem=\"Ze5-6b-2t3\" secondAttribute=\"centerX\" id=\"1a2-6s-vTC\"/>\n")
      ..write("                            <constraint firstItem=\"YRO-k0-Ey4\" firstAttribute=\"centerY\" secondItem=\"Ze5-6b-2t3\" secondAttribute=\"centerY\" id=\"4X2-HB-R7a\"/>\n");
    resources.write("        <image name=\"LaunchImage\" width=\"${s.size.round()}\" height=\"${s.heightOf(img, s.size).round()}\"/>\n");
  }
  if (brand != null) {
    views.write(
      "                            <imageView clipsSubviews=\"YES\" userInteractionEnabled=\"NO\" contentMode=\"bottom\" image=\"BrandingImage\" translatesAutoresizingMaskIntoConstraints=\"NO\" id=\"uBr-Vw-001\"/>\n",
    );
    constraints
      ..write("                            <constraint firstItem=\"uBr-Vw-001\" firstAttribute=\"centerX\" secondItem=\"Ze5-6b-2t3\" secondAttribute=\"centerX\" id=\"uBr-Cn-001\"/>\n")
      ..write("                            <constraint firstItem=\"xbc-2k-c8Z\" firstAttribute=\"top\" secondItem=\"uBr-Vw-001\" secondAttribute=\"bottom\" constant=\"24\" id=\"uBr-Cn-002\"/>\n");
    resources.write("        <image name=\"BrandingImage\" width=\"${s.brandingSize.round()}\" height=\"${s.heightOf(brand, s.brandingSize).round()}\"/>\n");
  }
  return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n"
      "<document type=\"com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB\" version=\"3.0\" toolsVersion=\"12121\" systemVersion=\"16G29\" targetRuntime=\"iOS.CocoaTouch\" propertyAccessControl=\"none\" useAutolayout=\"YES\" launchScreen=\"YES\" colorMatched=\"YES\" initialViewController=\"01J-lp-oVM\">\n"
      "    <dependencies>\n"
      "        <deployment identifier=\"iOS\"/>\n"
      "        <plugIn identifier=\"com.apple.InterfaceBuilder.IBCocoaTouchPlugin\" version=\"12089\"/>\n"
      "    </dependencies>\n"
      "    <scenes>\n"
      "        <!--View Controller-->\n"
      "        <scene sceneID=\"EHf-IW-A2E\">\n"
      "            <objects>\n"
      "                <viewController id=\"01J-lp-oVM\" sceneMemberID=\"viewController\">\n"
      "                    <layoutGuides>\n"
      "                        <viewControllerLayoutGuide type=\"top\" id=\"Ydg-fD-yQy\"/>\n"
      "                        <viewControllerLayoutGuide type=\"bottom\" id=\"xbc-2k-c8Z\"/>\n"
      "                    </layoutGuides>\n"
      "                    <view key=\"view\" contentMode=\"scaleToFill\" id=\"Ze5-6b-2t3\">\n"
      "                        <autoresizingMask key=\"autoresizingMask\" widthSizable=\"YES\" heightSizable=\"YES\"/>\n"
      "                        <subviews>\n"
      "$views"
      "                        </subviews>\n"
      "                        <color key=\"backgroundColor\" ${_srgb(s.light.color)} colorSpace=\"custom\" customColorSpace=\"sRGB\"/>\n"
      "                        <constraints>\n"
      "$constraints"
      "                        </constraints>\n"
      "                    </view>\n"
      "                </viewController>\n"
      "                <placeholder placeholderIdentifier=\"IBFirstResponder\" id=\"iYj-Kq-Ea1\" userLabel=\"First Responder\" sceneMemberID=\"firstResponder\"/>\n"
      "            </objects>\n"
      "            <point key=\"canvasLocation\" x=\"53\" y=\"375\"/>\n"
      "        </scene>\n"
      "    </scenes>\n"
      "    <resources>\n"
      "$resources"
      "    </resources>\n"
      "</document>\n";
}

void _iosStatusBar(Project p, {required bool hidden}) {
  final Plist? info = readPlist(p, const AppleFiles(Target.ios).infoPlist);
  if (!hidden && info?.has("UIStatusBarHidden") != true) {
    return;
  }
  editPlist(p, const AppleFiles(Target.ios).infoPlist, (Plist pl) {
    if (hidden) {
      pl
        ..setBool("UIStatusBarHidden", value: true)
        ..setBool("UIViewControllerBasedStatusBarAppearance", value: false);
    } else {
      pl
        ..remove("UIStatusBarHidden")
        ..remove("UIViewControllerBasedStatusBarAppearance");
    }
  }, hidden ? "status bar hidden during launch" : "status bar shown");
}

void _ios(Project p, _Splash s) {
  final _Look l = s.light;
  final _Look? d = s.dark;
  Bitmap bg(_Look look) => look.background ?? Bitmap(1, 1, look.color);
  _imageSet(p, _launchBackground, "background", (double _) => bg(l), d == null ? null : (double _) => bg(d), scales: const <String>["1x"]);
  if (l.image != null) {
    _imageSet(p, _launchImages, "LaunchImage", (double x) => _atWidth(l.image!, s.size * x), d?.image == null || identical(d!.image, l.image) ? null : (double x) => _atWidth(d.image!, s.size * x));
  } else {
    _imageSet(p, _launchImages, "LaunchImage", (double _) => Bitmap(1, 1), null);
  }
  if (l.branding != null) {
    _imageSet(
      p,
      _brandingImages,
      "BrandingImage",
      (double x) => _atWidth(l.branding!, s.brandingSize * x),
      d?.branding == null || identical(d!.branding, l.branding) ? null : (double x) => _atWidth(d.branding!, s.brandingSize * x),
    );
  } else {
    p.delete(_brandingImages, "removed");
  }
  p.write(_storyboard, _storyboardFor(s), "LaunchScreen.storyboard");
  _iosStatusBar(p, hidden: s.fullscreen);
}

// ---------------------------------------------------------------------------------------------
// Web

String _webBlocks(String t) => t.replaceAll(RegExp("[ \\t]*${RegExp.escape(_webStart)}[\\s\\S]*?${RegExp.escape(_webEnd)}[ \\t]*\\n?"), "");

String _srcset(String prefix) => <int>[1, 2, 3, 4].map((int x) => "splash/$prefix-${x}x.png ${x}x").join(", ");

void _web(Project p, _Splash s) {
  final _Look l = s.light;
  final _Look? d = s.dark;
  final Set<String> files = <String>{};
  void images(String prefix, Bitmap? img, double width) {
    if (img == null) {
      return;
    }
    for (int x = 1; x <= 4; x++) {
      final String rel = "$_webImages/$prefix-${x}x.png";
      p.writeBytes(rel, _atWidth(img, width * x).png(), "$prefix @${x}x");
      files.add(rel);
    }
  }

  void single(String name, Bitmap? img) {
    if (img != null) {
      p.writeBytes("$_webImages/$name.png", img.png(), name);
      files.add("$_webImages/$name.png");
    }
  }

  images("light", l.image, s.size);
  images("branding", l.branding, s.brandingSize);
  single("background", l.background);
  if (d != null) {
    if (!identical(d.image, l.image)) {
      images("dark", d.image, s.size);
    }
    if (!identical(d.branding, l.branding)) {
      images("dark-branding", d.branding, s.brandingSize);
    }
    if (!identical(d.background, l.background)) {
      single("dark-background", d.background);
    }
  }
  if (p.exists(_webImages)) {
    for (final String old in p.dirFiles(_webImages)) {
      if (!files.contains("$_webImages/$old")) {
        p.delete("$_webImages/$old", "removed");
      }
    }
  }

  String bgCss(_Look look, String name) => look.background != null ? "background: ${look.color.hex} url(\"splash/$name.png\") center / cover no-repeat;" : "background: ${look.color.hex};";
  final StringBuffer css = StringBuffer()
    ..write("  $_webStart\n  <style>\n")
    ..write("    html, body { margin: 0; height: 100%; }\n")
    ..write("    body { ${bgCss(l, "background")} }\n")
    ..write("    .u-splash { position: fixed; left: 0; right: 0; display: flex; justify-content: center; pointer-events: none; }\n")
    ..write("    #u-splash-logo { top: 0; bottom: 0; align-items: center; }\n")
    ..write("    #u-splash-logo img { width: ${s.size.round()}px; height: auto; }\n")
    ..write("    #u-splash-branding { bottom: 24px; }\n")
    ..write("    #u-splash-branding img { width: ${s.brandingSize.round()}px; height: auto; }\n");
  if (d != null) {
    css.write("    @media (prefers-color-scheme: dark) { body { ${bgCss(d, identical(d.background, l.background) ? "background" : "dark-background")} } }\n");
  }
  css.write("  </style>\n  $_webEnd\n");

  String picture(String id, String light, String? dark, String alt) =>
      "  <div class=\"u-splash\" id=\"$id\"><picture>"
      "${dark != null ? "<source srcset=\"${_srcset(dark)}\" media=\"(prefers-color-scheme: dark)\">" : ""}"
      "<img src=\"splash/$light-1x.png\" srcset=\"${_srcset(light)}\" alt=\"$alt\"></picture></div>\n";
  final StringBuffer body = StringBuffer()..write("  $_webStart\n");
  if (l.image != null) {
    body.write(picture("u-splash-logo", "light", d != null && !identical(d.image, l.image) ? "dark" : null, ""));
  }
  if (l.branding != null) {
    body.write(picture("u-splash-branding", "branding", d != null && !identical(d.branding, l.branding) ? "dark-branding" : null, ""));
  }
  body
    ..write("  <script>window.addEventListener(\"flutter-first-frame\", function () { document.querySelectorAll(\".u-splash\").forEach(function (e) { e.remove(); }); });</script>\n")
    ..write("  $_webEnd\n");

  p.edit(WebFiles.index, (String t) {
    String next = _webBlocks(t);
    final int head = next.indexOf("</head>");
    final Match? bodyTag = RegExp(r"<body[^>]*>\n?").firstMatch(next);
    if (head < 0 || bodyTag == null) {
      throw EditSkip("</head> or <body> not found");
    }
    next = next.replaceRange(bodyTag.end, bodyTag.end, body.toString());
    final int at = lineStart(next, head);
    return next.replaceRange(at, at, css.toString());
  }, "splash in index.html");
}

// ---------------------------------------------------------------------------------------------
// remove

const String _templateStoryboard =
    "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n"
    "<document type=\"com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB\" version=\"3.0\" toolsVersion=\"12121\" systemVersion=\"16G29\" targetRuntime=\"iOS.CocoaTouch\" propertyAccessControl=\"none\" useAutolayout=\"YES\" launchScreen=\"YES\" colorMatched=\"YES\" initialViewController=\"01J-lp-oVM\">\n"
    "    <dependencies>\n"
    "        <deployment identifier=\"iOS\"/>\n"
    "        <plugIn identifier=\"com.apple.InterfaceBuilder.IBCocoaTouchPlugin\" version=\"12089\"/>\n"
    "    </dependencies>\n"
    "    <scenes>\n"
    "        <!--View Controller-->\n"
    "        <scene sceneID=\"EHf-IW-A2E\">\n"
    "            <objects>\n"
    "                <viewController id=\"01J-lp-oVM\" sceneMemberID=\"viewController\">\n"
    "                    <layoutGuides>\n"
    "                        <viewControllerLayoutGuide type=\"top\" id=\"Ydg-fD-yQy\"/>\n"
    "                        <viewControllerLayoutGuide type=\"bottom\" id=\"xbc-2k-c8Z\"/>\n"
    "                    </layoutGuides>\n"
    "                    <view key=\"view\" contentMode=\"scaleToFill\" id=\"Ze5-6b-2t3\">\n"
    "                        <autoresizingMask key=\"autoresizingMask\" widthSizable=\"YES\" heightSizable=\"YES\"/>\n"
    "                        <subviews>\n"
    "                            <imageView opaque=\"NO\" clipsSubviews=\"YES\" multipleTouchEnabled=\"YES\" contentMode=\"center\" image=\"LaunchImage\" translatesAutoresizingMaskIntoConstraints=\"NO\" id=\"YRO-k0-Ey4\">\n"
    "                            </imageView>\n"
    "                        </subviews>\n"
    "                        <color key=\"backgroundColor\" red=\"1\" green=\"1\" blue=\"1\" alpha=\"1\" colorSpace=\"custom\" customColorSpace=\"sRGB\"/>\n"
    "                        <constraints>\n"
    "                            <constraint firstItem=\"YRO-k0-Ey4\" firstAttribute=\"centerX\" secondItem=\"Ze5-6b-2t3\" secondAttribute=\"centerX\" id=\"1a2-6s-vTC\"/>\n"
    "                            <constraint firstItem=\"YRO-k0-Ey4\" firstAttribute=\"centerY\" secondItem=\"Ze5-6b-2t3\" secondAttribute=\"centerY\" id=\"4X2-HB-R7a\"/>\n"
    "                        </constraints>\n"
    "                    </view>\n"
    "                </viewController>\n"
    "                <placeholder placeholderIdentifier=\"IBFirstResponder\" id=\"iYj-Kq-Ea1\" userLabel=\"First Responder\" sceneMemberID=\"firstResponder\"/>\n"
    "            </objects>\n"
    "            <point key=\"canvasLocation\" x=\"53\" y=\"375\"/>\n"
    "        </scene>\n"
    "    </scenes>\n"
    "    <resources>\n"
    "        <image name=\"LaunchImage\" width=\"168\" height=\"185\"/>\n"
    "    </resources>\n"
    "</document>\n";

void _remove(Project p) {
  p.section(Target.android, () {
    p.write("$androidRes/drawable/launch_background.xml", _templateDrawable, "launch_background.xml (Flutter default)");
    p.write("$androidRes/drawable-v21/launch_background.xml", _templateDrawableV21, "launch_background.xml (Flutter default)");
    for (final String rel in <String>["values/splash.xml", "values-night/splash.xml", "values-v31/styles.xml", "values-night-v31/styles.xml"]) {
      p.delete("$androidRes/$rel", "removed");
    }
    for (final String dpi in androidDensities.keys) {
      for (final String dir in <String>["drawable-$dpi", "drawable-night-$dpi"]) {
        for (final String name in <String>["splash", "splash_branding", "splash_icon"]) {
          p.delete("$androidRes/$dir/$name.png", "removed");
        }
        p.pruneEmptyDirs("$androidRes/$dir", androidRes);
      }
    }
    for (final String dir in <String>["drawable-nodpi", "drawable-night-nodpi"]) {
      p.delete("$androidRes/$dir/splash_background.png", "removed");
      p.pruneEmptyDirs("$androidRes/$dir", androidRes);
    }
    for (final String dir in <String>["values-v31", "values-night-v31"]) {
      p.pruneEmptyDirs("$androidRes/$dir", androidRes);
    }
    for (final String rel in <String>["$androidRes/values/styles.xml", "$androidRes/values-night/styles.xml"]) {
      p.edit(rel, (String t) => _launchThemeItem(t, "android:windowFullscreen", null), "launch keeps the status bar", optional: true, quiet: true);
    }
  });
  p.section(Target.ios, () {
    p.delete(_launchBackground, "removed");
    p.delete(_brandingImages, "removed");
    _imageSet(p, _launchImages, "LaunchImage", (double _) => Bitmap(1, 1), null);
    p.write(_storyboard, _templateStoryboard, "LaunchScreen.storyboard (Flutter default)");
    _iosStatusBar(p, hidden: false);
  });
  p.section(Target.web, () {
    p.edit(WebFiles.index, _webBlocks, "splash removed from index.html");
    p.delete(_webImages, "removed");
  });
}
