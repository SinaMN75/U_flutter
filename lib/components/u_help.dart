import "package:u/utilities.dart";

class UHelpItem {
  const UHelpItem(this.title, this.body);

  final String title;
  final String body;
}

abstract class UHelp {
  static const String _storageKey = "uHelpMode";
  static final URxBool enabled = URxBool(ULocalStorage.getBool(_storageKey) ?? false);
  static final Map<String, UHelpItem> items = <String, UHelpItem>{};
  static final Map<String, BuildContext> _targets = <String, BuildContext>{};
  static OverlayEntry? _entry;
  static const Color color = Color(0xFFFFB300);
  static const Color onColor = Color(0xFF3E2723);

  static void register(Map<String, UHelpItem> map) => items.addAll(map);

  static bool has(String prefix) => items.keys.any((String k) => k.startsWith(prefix));

  static void toggle() {
    enabled.toggle();
    ULocalStorage.set(_storageKey, enabled.value);
    if (enabled.isFalse) hide();
  }

  static void show(String key) => _open(<String>[key], spotlight: false);

  static void tour(String prefix) {
    final List<String> keys = items.keys.where((String k) => k.startsWith(prefix) && (_targets[k]?.mounted ?? false)).toList();
    if (keys.isNotEmpty) _open(keys, spotlight: true);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  static void _open(List<String> keys, {required bool spotlight}) {
    hide();
    final OverlayState? overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _entry = OverlayEntry(builder: (BuildContext context) => _UHelpOverlay(keys: keys, spotlight: spotlight));
    overlay.insert(_entry!);
  }
}

class UHelpTarget extends StatefulWidget {
  const UHelpTarget({required this.helpKey, required this.child, super.key, this.inline = false});

  final String helpKey;
  final Widget child;
  final bool inline;

  @override
  State<UHelpTarget> createState() => _UHelpTargetState();
}

class _UHelpTargetState extends State<UHelpTarget> {
  @override
  void dispose() {
    if (UHelp._targets[widget.helpKey] == context) UHelp._targets.remove(widget.helpKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UHelp._targets[widget.helpKey] = context;
    return UObx(() {
      if (!UHelp.enabled.value || !UHelp.items.containsKey(widget.helpKey)) return widget.child;
      final Widget badge = _UHelpBadge(onTap: () => UHelp.show(widget.helpKey));
      if (widget.inline) return URow(mainAxisSize: MainAxisSize.min, spacing: 6, children: <Widget>[Flexible(child: widget.child), badge]);
      return Stack(clipBehavior: Clip.none, children: <Widget>[widget.child, PositionedDirectional(top: -6, end: -6, child: badge)]);
    });
  }
}

extension UHelpWidget on Widget {
  Widget help(String key, {bool inline = false}) => UHelpTarget(helpKey: key, inline: inline, child: this);
}

class UHelpActions extends StatelessWidget {
  const UHelpActions(this.prefix, {super.key});

  final String prefix;

  @override
  Widget build(BuildContext context) {
    if (!UHelp.has(prefix)) return const SizedBox.shrink();
    return UObx(
      () => URow(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (UHelp.enabled.value) IconButton(icon: const Icon(Icons.tour_outlined), tooltip: U.s.pageTour, onPressed: () => UHelp.tour(prefix)),
          IconButton(
            icon: Icon(UHelp.enabled.value ? Icons.help_rounded : Icons.help_outline_rounded),
            color: UHelp.enabled.value ? Theme.of(context).colorScheme.primary : null,
            tooltip: U.s.helpMode,
            onPressed: UHelp.toggle,
          ),
        ],
      ),
    );
  }
}

class _UHelpBadge extends StatefulWidget {
  const _UHelpBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_UHelpBadge> createState() => _UHelpBadgeState();
}

class _UHelpBadgeState extends State<_UHelpBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color color = UHelp.color;
    final bool still = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox.square(
          dimension: 20,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (BuildContext context, Widget? child) => Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                if (!still)
                  Container(
                    width: 20 + 14 * _pulse.value,
                    height: 20 + 14 * _pulse.value,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.35 * (1 - _pulse.value))),
                  ),
                child!,
              ],
            ),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: Colors.white, width: 1.5)),
              alignment: Alignment.center,
              child: const Icon(Icons.question_mark_rounded, size: 13, color: UHelp.onColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _UHelpOverlay extends StatefulWidget {
  const _UHelpOverlay({required this.keys, required this.spotlight});

  final List<String> keys;
  final bool spotlight;

  @override
  State<_UHelpOverlay> createState() => _UHelpOverlayState();
}

class _UHelpOverlayState extends State<_UHelpOverlay> {
  int _index = 0;
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    _go(0);
  }

  Future<void> _go(int index) async {
    final BuildContext? target = UHelp._targets[widget.keys[index]];
    if (target == null || !target.mounted) return UHelp.hide();
    if (widget.spotlight) await Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 250), alignment: 0.3);
    if (!mounted || !target.mounted) return;
    final RenderBox box = target.findRenderObject()! as RenderBox;
    setState(() {
      _index = index;
      _rect = box.localToGlobal(Offset.zero) & box.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Rect? rect = _rect;
    if (rect == null) return const SizedBox.shrink();
    final Size screen = MediaQuery.sizeOf(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double width = (screen.width - 32).clamp(0, 320);
    final double left = (rect.center.dx - width / 2).clamp(16, screen.width - width - 16);
    final bool below = screen.height - rect.bottom > 220;
    final UHelpItem item = UHelp.items[widget.keys[_index]]!;
    final bool last = _index == widget.keys.length - 1;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTap: UHelp.hide,
            child: TweenAnimationBuilder<Rect?>(
              tween: RectTween(end: rect),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, Rect? hole, Widget? child) => CustomPaint(
                painter: _UHelpHolePainter(hole: hole, dim: widget.spotlight ? Colors.black.withValues(alpha: 0.55) : Colors.transparent, ring: UHelp.color),
              ),
            ),
          ),
        ),
        Positioned(
          left: left,
          width: width,
          top: below ? rect.bottom + 14 : null,
          bottom: below ? null : screen.height - rect.top + 14,
          child: TweenAnimationBuilder<double>(
            key: ValueKey<int>(_index),
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            builder: (BuildContext context, double t, Widget? child) => Opacity(
              opacity: t,
              child: Transform.translate(offset: Offset(0, (below ? -8 : 8) * (1 - t)), child: child),
            ),
            child: Material(
              elevation: 10,
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    URow(
                      children: <Widget>[
                        const Icon(Icons.lightbulb_outline_rounded, size: 20, color: UHelp.color),
                        const SizedBox(width: 8),
                        UTextTitleMedium(item.title, overflow: TextOverflow.visible, expanded: 1),
                        const InkWell(onTap: UHelp.hide, child: Icon(Icons.close_rounded, size: 18)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    UTextBodyMedium(item.body, color: scheme.onSurfaceVariant, overflow: TextOverflow.visible),
                    if (widget.spotlight) ...<Widget>[
                      const SizedBox(height: 12),
                      URow(
                        children: <Widget>[
                          UTextBodySmall("${_index + 1} / ${widget.keys.length}", color: scheme.onSurfaceVariant, expanded: 1),
                          if (_index > 0) TextButton(onPressed: () => _go(_index - 1), child: Text(U.s.previous)),
                          const SizedBox(width: 4),
                          FilledButton(onPressed: last ? UHelp.hide : () => _go(_index + 1), child: Text(last ? U.s.finish : U.s.next)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UHelpHolePainter extends CustomPainter {
  _UHelpHolePainter({required this.hole, required this.dim, required this.ring});

  final Rect? hole;
  final Color dim;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    if (hole == null) return;
    final RRect cut = RRect.fromRectAndRadius(hole!.inflate(6), const Radius.circular(10));
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(cut),
      Paint()..color = dim,
    );
    canvas.drawRRect(cut, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ring);
  }

  @override
  bool shouldRepaint(_UHelpHolePainter old) => old.hole != hole || old.dim != dim;
}
