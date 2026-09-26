import "package:u/components/cached_image.dart";
import "package:u/utilities.dart";

class UImage extends StatelessWidget {
  const UImage(
    this.source, {
    super.key,
    this.fileData,
    this.color,
    this.width,
    this.height,
    this.placeholder,
    this.fit = BoxFit.contain,
    this.borderRadius = 0,
    this.package,
    this.shape = BoxShape.rectangle,
    this.border,
    this.boxShadow,
    this.gradient,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.splash = false,
    this.pressedScale,
    this.opacity,
    this.heroTag,
    this.tooltip,
    this.semanticsLabel,
    this.semanticsButton,
    this.visible = true,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.alignment,
    this.onPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTap,
    this.hitTestBehavior,
    this.splashColor,
    this.highlightColor,
    this.hoverColor,
    this.cursor,
    this.onHover,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  final String? package;
  final String source;
  final UFileData? fileData;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String? placeholder;
  final BoxShape shape;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final bool splash;
  final double? pressedScale;
  final double? opacity;
  final String? heroTag;
  final String? tooltip;
  final String? semanticsLabel;
  final bool? semanticsButton;
  final bool visible;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final AlignmentGeometry? alignment;
  final VoidCallback? onPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureTapCallback? onSecondaryTap;
  final HitTestBehavior? hitTestBehavior;
  final Color? splashColor;
  final Color? highlightColor;
  final Color? hoverColor;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  Widget _image(BuildContext context) {
    if (fileData != null) {
      if (fileData?.bytes != null) {
        return UImageMemory(fileData!.bytes!, width: width, height: height, color: color, fit: fit, placeholder: placeholder);
      }
      return UImageFile(File(fileData!.path!), width: width, height: height, color: color, fit: fit);
    }
    if (source.length <= 5) {
      if (placeholder == null) return SizedBox(width: width, height: height);
      return UImageAsset(placeholder!, width: width, height: height, placeholder: placeholder, color: color, fit: fit, package: package);
    }
    if (source.endsWith(".json")) {
      return source.startsWith("http") ? Lottie.network(source, width: width, height: height, fit: fit, repeat: true) : Lottie.asset(source, width: width, height: height, fit: fit, repeat: true);
    }
    if (source.startsWith("http")) {
      return UImageNetwork(source, width: width, height: height, fit: fit, color: color, placeholder: placeholder);
    }
    final UBase64Image? base64Image = UBase64Image.tryParse(source);
    if (base64Image != null) {
      return switch (base64Image.kind) {
        UBase64ImageKind.svg => SvgPicture.memory(
          base64Image.bytes,
          width: width,
          height: height,
          fit: fit,
          colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
        ),
        UBase64ImageKind.lottie => Lottie.memory(base64Image.bytes, width: width, height: height, fit: fit, repeat: true),
        UBase64ImageKind.raster => UImageMemory(base64Image.bytes, width: width, height: height, color: color, fit: fit, placeholder: placeholder),
      };
    }
    return UImageAsset(source, width: width, height: height, fit: fit, placeholder: placeholder, color: color, package: package);
  }

  @override
  Widget build(BuildContext context) => UContainer(
    radius: borderRadius,
    shape: shape,
    border: border,
    boxShadow: boxShadow,
    gradient: gradient,
    color: backgroundColor,
    padding: padding,
    margin: margin,
    clipBehavior: Clip.antiAlias,
    onTap: onTap,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    splash: splash,
    pressedScale: pressedScale,
    opacity: opacity,
    heroTag: heroTag,
    tooltip: tooltip,
    semanticsLabel: semanticsLabel,
    semanticsButton: semanticsButton,
    visible: visible,
    minWidth: minWidth,
    maxWidth: maxWidth,
    minHeight: minHeight,
    maxHeight: maxHeight,
    alignment: alignment,
    onPress: onPress,
    onTapDown: onTapDown,
    onTapUp: onTapUp,
    onTapCancel: onTapCancel,
    onSecondaryTap: onSecondaryTap,
    hitTestBehavior: hitTestBehavior,
    splashColor: splashColor,
    highlightColor: highlightColor,
    hoverColor: hoverColor,
    cursor: cursor,
    onHover: onHover,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
    child: _image(context),
  );
}

class UIconPrimary extends StatelessWidget {
  const UIconPrimary(
    this.source, {
    super.key,
    this.color,
    this.width,
    this.height,
    this.placeholder,
    this.fit = BoxFit.contain,
    this.package,
    this.onTap,
    this.onPress,
    this.onLongPress,
    this.onDoubleTap,
    this.splash = false,
    this.pressedScale,
    this.cursor,
    this.onHover,
    this.margin,
    this.opacity,
    this.tooltip,
    this.heroTag,
    this.visible = true,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  final String? package;
  final String source;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? placeholder;
  final GestureTapCallback? onTap;
  final VoidCallback? onPress;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final bool splash;
  final double? pressedScale;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final EdgeInsetsGeometry? margin;
  final double? opacity;
  final String? tooltip;
  final String? heroTag;
  final bool visible;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => UImage(
    source,
    color: color ?? Theme.of(navigatorKey.currentContext!).colorScheme.primary,
    width: width,
    height: height,
    fit: fit,
    placeholder: placeholder,
    package: package,
    onTap: onTap,
    onPress: onPress,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    splash: splash,
    pressedScale: pressedScale,
    cursor: cursor,
    onHover: onHover,
    margin: margin,
    opacity: opacity,
    tooltip: tooltip,
    heroTag: heroTag,
    visible: visible,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
  );
}

class UImageAsset extends StatelessWidget {
  const UImageAsset(
    this.path, {
    this.color,
    this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.clipBehavior = Clip.hardEdge,
    this.package,
    this.onTap,
    this.onPress,
    this.onLongPress,
    this.onDoubleTap,
    this.splash = false,
    this.pressedScale,
    this.cursor,
    this.onHover,
    this.margin,
    this.opacity,
    this.tooltip,
    this.heroTag,
    this.visible = true,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
    super.key,
  });

  final String? package;
  final String path;
  final String? placeholder;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Clip clipBehavior;
  final GestureTapCallback? onTap;
  final VoidCallback? onPress;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final bool splash;
  final double? pressedScale;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final EdgeInsetsGeometry? margin;
  final double? opacity;
  final String? tooltip;
  final String? heroTag;
  final bool visible;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => uWrap(
    path.endsWith("svg")
        ? SvgPicture.asset(
            path,
            width: width,
            height: height,
            fit: fit,
            colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
            package: package,
            placeholderBuilder: (BuildContext context) => placeholder == null
                ? SizedBox(width: width, height: height)
                : UImageAsset(
                    placeholder!,
                    color: color,
                    width: width,
                    height: height,
                    fit: fit,
                    clipBehavior: clipBehavior,
                    package: package,
                  ),
          )
        : Image.asset(
            path,
            color: color,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: width == null ? null : (width! * (MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0)).round(),
            cacheHeight: height == null ? null : (height! * (MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0)).round(),
            package: package,
            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => placeholder == null
                ? SizedBox(width: width, height: height)
                : UImageAsset(
                    placeholder!,
                    color: color,
                    width: width,
                    height: height,
                    fit: fit,
                    clipBehavior: clipBehavior,
                    package: package,
                  ),
          ),
    onTap: onTap,
    onPress: onPress,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    splash: splash,
    pressedScale: pressedScale,
    cursor: cursor,
    onHover: onHover,
    margin: margin,
    opacity: opacity,
    tooltip: tooltip,
    heroTag: heroTag,
    visible: visible,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
  );
}

class UImageNetwork extends StatelessWidget {
  const UImageNetwork(
    this.url, {
    this.color,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.clipBehavior = Clip.hardEdge,
    this.placeholder,
    this.package,
    this.onTap,
    this.onPress,
    this.onLongPress,
    this.onDoubleTap,
    this.splash = false,
    this.pressedScale,
    this.cursor,
    this.onHover,
    this.margin,
    this.opacity,
    this.tooltip,
    this.heroTag,
    this.visible = true,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
    super.key,
  });

  final String? package;
  final String url;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Clip clipBehavior;
  final String? placeholder;
  final GestureTapCallback? onTap;
  final VoidCallback? onPress;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final bool splash;
  final double? pressedScale;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final EdgeInsetsGeometry? margin;
  final double? opacity;
  final String? tooltip;
  final String? heroTag;
  final bool visible;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) => uWrap(
    url.length <= 10
        ? placeholder == null
              ? SizedBox(width: width, height: height)
              : UImageAsset(
                  placeholder!,
                  width: width,
                  height: height,
                  color: color,
                  fit: fit,
                  clipBehavior: clipBehavior,
                  package: package,
                )
        : url.substring(url.length - 3) == "svg"
        ? SvgPicture.network(
            url,
            width: width,
            height: height,
            fit: fit,
            placeholderBuilder: placeholder == null
                ? null
                : (_) => UImageAsset(
                    placeholder!,
                    width: width,
                    height: height,
                    fit: fit,
                    clipBehavior: clipBehavior,
                    package: package,
                  ),
          )
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            errorWidget: placeholder == null
                ? null
                : UImage(
                    placeholder!,
                    color: color,
                    width: width,
                    height: height,
                    fit: fit,
                    package: package,
                  ),
            placeholder: placeholder == null
                ? null
                : UImage(
                    placeholder!,
                    color: color,
                    width: width,
                    height: height,
                    fit: fit,
                    package: package,
                  ),
          ),
    onTap: onTap,
    onPress: onPress,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    splash: splash,
    pressedScale: pressedScale,
    cursor: cursor,
    onHover: onHover,
    margin: margin,
    opacity: opacity,
    tooltip: tooltip,
    heroTag: heroTag,
    visible: visible,
    scale: scale,
    rotate: rotate,
    translate: translate,
    center: center,
    safeArea: safeArea,
    expanded: expanded,
    flexible: flexible,
    positioned: positioned,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    positionedWidth: positionedWidth,
    positionedHeight: positionedHeight,
  );
}

class UImageFile extends StatelessWidget {
  const UImageFile(
    this.file, {
    this.color,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.onTap,
    this.onPress,
    this.onLongPress,
    this.onDoubleTap,
    this.splash = false,
    this.pressedScale,
    this.cursor,
    this.onHover,
    this.margin,
    this.opacity,
    this.tooltip,
    this.heroTag,
    this.visible = true,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
    super.key,
  });

  final File file;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final GestureTapCallback? onTap;
  final VoidCallback? onPress;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final bool splash;
  final double? pressedScale;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final EdgeInsetsGeometry? margin;
  final double? opacity;
  final String? tooltip;
  final String? heroTag;
  final bool visible;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final Widget img = Image.file(
      file,
      color: color,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width == null ? null : (width! * dpr).round(),
      cacheHeight: height == null ? null : (height! * dpr).round(),
    );
    return uWrap(
      img,
      onTap: onTap,
      onPress: onPress,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      splash: splash,
      pressedScale: pressedScale,
      cursor: cursor,
      onHover: onHover,
      margin: margin,
      opacity: opacity,
      tooltip: tooltip,
      heroTag: heroTag,
      visible: visible,
      scale: scale,
      rotate: rotate,
      translate: translate,
      center: center,
      safeArea: safeArea,
      expanded: expanded,
      flexible: flexible,
      positioned: positioned,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      positionedWidth: positionedWidth,
      positionedHeight: positionedHeight,
    );
  }
}

class UImageMemory extends StatelessWidget {
  const UImageMemory(
    this.file, {
    this.color,
    this.width,
    this.height,
    this.placeholder,
    this.fit = BoxFit.contain,
    this.onTap,
    this.onPress,
    this.onLongPress,
    this.onDoubleTap,
    this.splash = false,
    this.pressedScale,
    this.cursor,
    this.onHover,
    this.margin,
    this.opacity,
    this.tooltip,
    this.heroTag,
    this.visible = true,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
    super.key,
  });

  final Uint8List file;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? placeholder;
  final GestureTapCallback? onTap;
  final VoidCallback? onPress;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onDoubleTap;
  final bool splash;
  final double? pressedScale;
  final MouseCursor? cursor;
  final ValueChanged<bool>? onHover;
  final EdgeInsetsGeometry? margin;
  final double? opacity;
  final String? tooltip;
  final String? heroTag;
  final bool visible;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final Widget img = Image.memory(
      file,
      color: color,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width == null ? null : (width! * dpr).round(),
      cacheHeight: height == null ? null : (height! * dpr).round(),
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => placeholder == null
          ? SizedBox(width: width, height: height)
          : UImageAsset(
              placeholder!,
              color: color,
              width: width,
              height: height,
              fit: fit,
            ),
    );
    return uWrap(
      img,
      onTap: onTap,
      onPress: onPress,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      splash: splash,
      pressedScale: pressedScale,
      cursor: cursor,
      onHover: onHover,
      margin: margin,
      opacity: opacity,
      tooltip: tooltip,
      heroTag: heroTag,
      visible: visible,
      scale: scale,
      rotate: rotate,
      translate: translate,
      center: center,
      safeArea: safeArea,
      expanded: expanded,
      flexible: flexible,
      positioned: positioned,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      positionedWidth: positionedWidth,
      positionedHeight: positionedHeight,
    );
  }
}

enum UBase64ImageKind { raster, svg, lottie }

/// A decoded base64 image source: either a `data:<mime>;base64,<payload>` URI
/// or a bare base64 payload whose bytes carry a known image signature.
class UBase64Image {
  const UBase64Image._(this.bytes, this.kind);

  final Uint8List bytes;
  final UBase64ImageKind kind;

  static const int _maxCacheEntries = 64;
  static const int _minBarePayloadLength = 64;
  static final Map<String, UBase64Image?> _cache = <String, UBase64Image?>{};
  static final RegExp _alphabet = RegExp(r"^[A-Za-z0-9+/\-_]+={0,2}$");
  static final RegExp _whitespace = RegExp(r"\s");

  static bool isBase64(String source) => tryParse(source) != null;

  static UBase64Image? tryParse(String source) {
    final bool isDataUri = source.startsWith("data:");
    if (!isDataUri && (source.length < _minBarePayloadLength || source.contains("."))) return null;

    if (_cache.containsKey(source)) {
      final UBase64Image? hit = _cache.remove(source);
      _cache[source] = hit;
      return hit;
    }
    final UBase64Image? parsed = _parse(source, isDataUri);
    if (_cache.length >= _maxCacheEntries) _cache.remove(_cache.keys.first);
    _cache[source] = parsed;
    return parsed;
  }

  static UBase64Image? _parse(String source, bool isDataUri) {
    String payload = source;
    String mime = "";
    if (isDataUri) {
      final int comma = source.indexOf(",");
      if (comma < 0) return null;
      final String header = source.substring(5, comma).toLowerCase();
      if (!header.contains(";base64")) return null;
      mime = header.split(";").first;
      payload = source.substring(comma + 1);
    }
    payload = payload.replaceAll(_whitespace, "");
    if (payload.isEmpty || !_alphabet.hasMatch(payload)) return null;

    final Uint8List bytes;
    try {
      bytes = base64.decode(base64.normalize(payload));
    } catch (_) {
      return null;
    }
    if (bytes.isEmpty) return null;

    final UBase64ImageKind? kind = _kindFromMime(mime) ?? _kindFromBytes(bytes);
    if (kind == null) return isDataUri ? UBase64Image._(bytes, UBase64ImageKind.raster) : null;
    return UBase64Image._(bytes, kind);
  }

  static UBase64ImageKind? _kindFromMime(String mime) {
    if (mime.contains("svg")) return UBase64ImageKind.svg;
    if (mime.contains("json")) return UBase64ImageKind.lottie;
    if (mime.startsWith("image/")) return UBase64ImageKind.raster;
    return null;
  }

  static UBase64ImageKind? _kindFromBytes(Uint8List b) {
    bool starts(List<int> sig, [int offset = 0]) {
      if (b.length < offset + sig.length) return false;
      for (int i = 0; i < sig.length; i++) {
        if (b[offset + i] != sig[i]) return false;
      }
      return true;
    }

    if (starts(<int>[0x89, 0x50, 0x4E, 0x47]) || // PNG
        starts(<int>[0xFF, 0xD8, 0xFF]) || // JPEG
        starts(<int>[0x47, 0x49, 0x46, 0x38]) || // GIF
        (starts(<int>[0x52, 0x49, 0x46, 0x46]) && starts(<int>[0x57, 0x45, 0x42, 0x50], 8)) || // WEBP
        starts(<int>[0x42, 0x4D]) || // BMP
        starts(<int>[0x00, 0x00, 0x01, 0x00]) || // ICO
        starts(<int>[0x66, 0x74, 0x79, 0x70], 4)) {
      return UBase64ImageKind.raster;
    }

    int i = starts(<int>[0xEF, 0xBB, 0xBF]) ? 3 : 0;
    while (i < b.length && (b[i] == 0x20 || b[i] == 0x09 || b[i] == 0x0A || b[i] == 0x0D)) {
      i++;
    }
    if (i >= b.length) return null;
    if (b[i] == 0x3C) {
      final String head = utf8.decode(b.sublist(i, (i + 512).clamp(0, b.length)), allowMalformed: true).toLowerCase();
      if (head.contains("<svg")) return UBase64ImageKind.svg;
    }
    if (b[i] == 0x7B) return UBase64ImageKind.lottie; // "{"
    return null;
  }
}
