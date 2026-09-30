import "package:u/utilities.dart";

/// Shimmering grey placeholder shown while content loads. `USkeleton(width: 120, height: 16)`, `USkeleton.circle(48)`
class USkeleton extends StatefulWidget {
  /// A rounded box; leave [width] null to fill the row.
  const USkeleton({super.key, this.width, this.height = 16, this.radius = 8}) : child = null, _circle = false;

  /// A circle of [size], e.g. an avatar.
  const USkeleton.circle(double size, {super.key}) : width = size, height = size, radius = 0, child = null, _circle = true;

  /// Paints the shimmer in the exact shape of [child] (text glyphs, icons, images). `Text("Loading").skeleton(true)`
  const USkeleton.wrap({required Widget this.child, super.key}) : width = null, height = null, radius = 0, _circle = false;

  /// Box width (null = full width).
  final double? width;

  /// Box height.
  final double? height;

  /// Corner radius of the box.
  final double radius;

  /// Widget whose shape is used by [USkeleton.wrap].
  final Widget? child;
  final bool _circle;

  /// A block of [lines] text-like bars; the last one is shorter. `USkeleton.lines(3)`
  static Widget lines(int lines, {double height = 12, double spacing = 8}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: spacing,
    children: List<Widget>.generate(
      lines,
      (int i) => FractionallySizedBox(
        widthFactor: i == lines - 1 && lines > 1 ? 0.6 : 1,
        child: USkeleton(height: height),
      ),
    ),
  );

  /// A list-tile placeholder: circle + two lines. `USkeleton.listTile()`
  static Widget listTile({double avatar = 44}) => Row(
    spacing: 12,
    children: <Widget>[
      USkeleton.circle(avatar),
      Expanded(child: lines(2)),
    ],
  ).pSymmetric(horizontal: 16, vertical: 8);

  /// [count] list-tile placeholders, e.g. the first load of a list. `USkeleton.list(count: 6)`
  static Widget list({int count = 6, double avatar = 44}) => ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    itemCount: count,
    itemBuilder: (BuildContext context, int index) => listTile(avatar: avatar),
  );

  @override
  State<USkeleton> createState() => _USkeletonState();
}

class _USkeletonState extends State<USkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color base = dark ? const Color(0xFF2C2C2E) : const Color(0xFFE3E3E6);
    final Color light = dark ? const Color(0xFF3A3A3D) : const Color(0xFFF4F4F6);
    final Widget shape = widget.child != null
        ? widget.child!
        : Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(color: base, shape: widget._circle ? BoxShape.circle : BoxShape.rectangle, borderRadius: widget._circle ? null : BorderRadius.circular(widget.radius)),
          );
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        child: shape,
        builder: (BuildContext context, Widget? child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) => LinearGradient(
            colors: <Color>[base, light, base],
            stops: const <double>[0.35, 0.5, 0.65],
            begin: Alignment(-2 + _controller.value * 4, -0.3),
            end: Alignment(-1 + _controller.value * 4, 0.3),
          ).createShader(bounds),
          child: child,
        ),
      ),
    );
  }
}
