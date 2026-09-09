import "package:u/utilities.dart";

class UVideoView extends StatelessWidget {
  const UVideoView({
    required this.controller,
    super.key,
    this.fit = UMediaFit.contain,
    this.zoom = 1,
    this.pan = Offset.zero,
    this.rotationDegrees = 0,
    this.mirrored = false,
    this.backgroundColor,
    this.placeholder,
    this.errorBuilder,
  });

  final UMediaController controller;
  final UMediaFit fit;
  final double zoom;
  final Offset pan;
  final int rotationDegrees;
  final bool mirrored;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget Function(BuildContext context, UMediaError error)? errorBuilder;

  static double? ratioOf(UMediaFit fit) {
    switch (fit) {
      case UMediaFit.ratio16x9:
        return 16 / 9;
      case UMediaFit.ratio4x3:
        return 4 / 3;
      case UMediaFit.ratio21x9:
        return 21 / 9;
      case UMediaFit.ratio1x1:
        return 1;
      case UMediaFit.contain:
      case UMediaFit.cover:
      case UMediaFit.fill:
      case UMediaFit.fitWidth:
      case UMediaFit.fitHeight:
      case UMediaFit.none:
      case UMediaFit.original:
        return null;
    }
  }

  static BoxFit boxFitOf(UMediaFit fit) {
    switch (fit) {
      case UMediaFit.cover:
        return BoxFit.cover;
      case UMediaFit.fill:
        return BoxFit.fill;
      case UMediaFit.fitWidth:
        return BoxFit.fitWidth;
      case UMediaFit.fitHeight:
        return BoxFit.fitHeight;
      case UMediaFit.none:
      case UMediaFit.original:
        return BoxFit.none;
      case UMediaFit.contain:
      case UMediaFit.ratio16x9:
      case UMediaFit.ratio4x3:
      case UMediaFit.ratio21x9:
      case UMediaFit.ratio1x1:
        return BoxFit.contain;
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) => ColoredBox(
      color: backgroundColor ?? const Color(0xFF000000),
      child: _buildContent(context, value),
    ),
  );

  Widget _buildContent(BuildContext context, UMediaValue value) {
    final UMediaError? error = value.error;
    if (error != null) return errorBuilder?.call(context, error) ?? const SizedBox.shrink();
    if (!value.hasVideo && value.state == UMediaState.idle) return placeholder ?? const SizedBox.shrink();

    final Widget surface = _surface();
    if (surface is SizedBox) return placeholder ?? const SizedBox.shrink();

    final double ratio = ratioOf(fit) ?? value.aspectRatio;
    final int rotation = rotationDegrees == 0 ? value.rotationDegrees : rotationDegrees;

    Widget content = FittedBox(
      fit: boxFitOf(fit),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: value.width > 0 ? value.width.toDouble() : 1920,
        height: value.height > 0 ? value.height.toDouble() : 1080,
        child: surface,
      ),
    );

    if (rotation != 0) content = RotatedBox(quarterTurns: (rotation ~/ 90) % 4, child: content);
    if (mirrored) content = Transform(alignment: Alignment.center, transform: Matrix4.identity()..scale(-1.0, 1, 1), child: content);
    if (zoom != 1 || pan != Offset.zero) {
      content = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(pan.dx, pan.dy, 0, 1)
          ..scaleByDouble(zoom, zoom, 1, 1),
        child: content,
      );
    }

    return ClipRect(child: Center(child: AspectRatio(aspectRatio: ratio <= 0 ? 16 / 9 : ratio, child: content)));
  }

  Widget _surface() {
    if (kIsWeb) {
      final int? id = controller.playerId;
      return id == null ? const SizedBox.shrink() : HtmlElementView(viewType: "u-media-$id");
    }
    final int? texture = controller.textureId;
    return texture == null ? const SizedBox.shrink() : Texture(textureId: texture);
  }
}
