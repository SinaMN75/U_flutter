import "package:u/utilities.dart";

enum FlipDirection { VERTICAL, HORIZONTAL }

enum CardSide { FRONT, BACK }

enum Fill { none, fillFront, fillBack }

class UAnimationCard extends StatelessWidget {
  const UAnimationCard({super.key, this.child, this.animation, this.direction});

  final Widget? child;
  final Animation<double>? animation;
  final FlipDirection? direction;

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
    animation: animation!,
    builder: (final BuildContext context, final Widget? child) {
      final Matrix4 transform = Matrix4.identity();
      transform.setEntry(3, 2, 0.001);
      if (direction == FlipDirection.VERTICAL) {
        transform.rotateX(animation!.value);
      } else {
        transform.rotateY(animation!.value);
      }
      return Transform(
        transform: transform,
        alignment: Alignment.center,
        child: child,
      );
    },
    child: child,
  );
}

typedef BoolCallback = void Function(bool isFront);

class FlipCard extends StatefulWidget {
  const FlipCard({
    required this.front,
    required this.back,
    super.key,
    this.speed = 500,
    this.onFlip,
    this.onFlipDone,
    this.direction = FlipDirection.HORIZONTAL,
    this.controller,
    this.flipOnTouch = true,
    this.alignment = Alignment.center,
    this.fill = Fill.none,
    this.side = CardSide.FRONT,
  });

  final Widget front;
  final Widget back;
  final int speed;
  final FlipDirection direction;
  final VoidCallback? onFlip;
  final BoolCallback? onFlipDone;
  final FlipCardController? controller;
  final Fill fill;
  final CardSide side;
  final bool flipOnTouch;
  final Alignment alignment;

  @override
  State<StatefulWidget> createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  FlipCardState();

  AnimationController? controller;
  Animation<double>? _frontRotation;
  Animation<double>? _backRotation;

  bool isFront = true;

  @override
  void initState() {
    super.initState();
    isFront = widget.side == CardSide.FRONT;
    controller = AnimationController(
      value: isFront ? 0.0 : 1.0,
      duration: Duration(milliseconds: widget.speed),
      vsync: this,
    );
    _frontRotation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: pi / 2).chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(pi / 2),
          weight: 50,
        ),
      ],
    ).animate(controller!);
    _backRotation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(tween: ConstantTween<double>(pi / 2), weight: 50),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: -pi / 2, end: 0).chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
      ],
    ).animate(controller!);

    widget.controller?.state = this;
  }

  @override
  void didUpdateWidget(final FlipCard oldWidget) {
    widget.controller?.state ??= this;
    super.didUpdateWidget(oldWidget);
  }

  Future<void> toggleCard() async {
    widget.onFlip?.call();

    final bool isFrontBefore = isFront;
    controller!.duration = Duration(milliseconds: widget.speed);

    final TickerFuture animation = isFront ? controller!.forward() : controller!.reverse();
    await animation.whenComplete(() {
      if (widget.onFlipDone != null) widget.onFlipDone!(isFront);
      if (!mounted) return;
      setState(() => isFront = !isFrontBefore);
    });
  }

  void toggleCardWithoutAnimation() {
    controller!.stop();

    widget.onFlip?.call();

    if (widget.onFlipDone != null) widget.onFlipDone!(isFront);

    setState(() {
      isFront = !isFront;
      controller!.value = isFront ? 0.0 : 1.0;
    });
  }

  @override
  Widget build(final BuildContext context) {
    final Widget Function(Widget child) frontPositioning = widget.fill == Fill.fillFront ? _fill : _noop;
    final Widget Function(Widget child) backPositioning = widget.fill == Fill.fillBack ? _fill : _noop;

    final Stack child = Stack(
      alignment: widget.alignment,
      fit: StackFit.passthrough,
      children: <Widget>[
        frontPositioning(_buildContent(front: true)),
        backPositioning(_buildContent(front: false)),
      ],
    );

    if (widget.flipOnTouch) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: toggleCard,
        child: child,
      );
    }
    return child;
  }

  Widget _buildContent({required final bool front}) => IgnorePointer(
    ignoring: front ? !isFront : isFront,
    child: UAnimationCard(
      animation: front ? _frontRotation : _backRotation,
      direction: widget.direction,
      child: front ? widget.front : widget.back,
    ),
  );

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }
}

Widget _fill(final Widget child) => Positioned.fill(child: child);

Widget _noop(final Widget child) => child;

class FlipCardController {
  FlipCardState? state;

  AnimationController? get controller {
    assert(state != null, "Controller not attached to any FlipCard. Did you forget to pass the controller to the FlipCard?");
    return state!.controller;
  }

  Future<void> toggleCard() async => await state?.toggleCard();

  void toggleCardWithoutAnimation() => state?.toggleCardWithoutAnimation();

  Future<void> skew(final double amount, {final Duration? duration, final Curve? curve}) async {
    assert(0 <= amount && amount <= 1);

    final double target = state!.isFront ? amount : 1 - amount;
    await controller?.animateTo(target, duration: duration, curve: curve ?? Curves.linear).asStream().first;
  }

  Future<void> hint({final Duration? duration, final Duration? total}) async {
    assert(controller is AnimationController);
    if (controller is! AnimationController) return;

    if (controller!.isAnimating || controller!.value != 0) return;

    final Duration? durationTotal = total ?? controller!.duration;

    final Completer<void> completer = Completer<void>();

    final Duration? original = controller!.duration;
    controller!.duration = durationTotal;
    await controller!.forward();

    final Duration durationFlipBack = duration ?? const Duration(milliseconds: 150);

    Timer(durationFlipBack, () {
      controller!.reverse().whenComplete(completer.complete);
      controller!.duration = original;
    });

    await completer.future;
  }
}
