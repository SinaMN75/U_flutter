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
  final FileData? fileData;
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
  final EdgeInsets? padding;
  final EdgeInsets? margin;
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
  final EdgeInsets? margin;
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
