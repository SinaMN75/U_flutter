import "package:u/utilities.dart";

/// Flip axis: horizontal or vertical.
enum UFlipDirection { vertical, horizontal }

/// Which side shows first: front or back.
enum UCardSide { front, back }

/// Which side sets the size: none, fillFront, fillBack.
enum UFill { none, fillFront, fillBack }

/// One side of a UFlipCard during the flip.
class UAnimationCard extends StatelessWidget {
  const UAnimationCard({super.key, this.child, this.animation, this.direction});

  /// The widget inside.
  final Widget? child;

  /// The flip animation.
  final Animation<double>? animation;

  /// Layout direction.
  final UFlipDirection? direction;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation!,
    builder: (BuildContext context, Widget? child) {
      final Matrix4 transform = Matrix4.identity();
      transform.setEntry(3, 2, 0.001);
      if (direction == UFlipDirection.vertical) {
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

/// Called with true when the front is showing.
typedef UBoolCallback = void Function(bool isFront);

/// Card that flips to show its back on tap or from code. `UFlipCard(front: const Text("Q"), back: const Text("A"))`
class UFlipCard extends StatefulWidget {
  const UFlipCard({
    required this.front,
    required this.back,
    super.key,
    this.speed = 500,
    this.onFlip,
    this.onFlipDone,
    this.direction = UFlipDirection.horizontal,
    this.controller,
    this.flipOnTouch = true,
    this.alignment = Alignment.center,
    this.fill = UFill.none,
    this.side = UCardSide.front,
  });

  /// Front side.
  final Widget front;

  /// Back side.
  final Widget back;

  /// Speed.
  final int speed;

  /// Layout direction.
  final UFlipDirection direction;

  /// Called when a flip starts.
  final VoidCallback? onFlip;

  /// Called with isFront when a flip ends.
  final UBoolCallback? onFlipDone;

  /// Controller to read or change it from code.
  final UFlipCardController? controller;

  /// Which side sets the size.
  final UFill fill;

  /// Side shown first.
  final UCardSide side;

  /// Flips on tap.
  final bool flipOnTouch;

  /// Alignment of the content.
  final Alignment alignment;

  @override
  State<StatefulWidget> createState() => UFlipCardState();
}

/// State of UFlipCard.
class UFlipCardState extends State<UFlipCard> with SingleTickerProviderStateMixin {
  UFlipCardState();

  /// The flip animation.
  AnimationController? controller;
  Animation<double>? _frontRotation;
  Animation<double>? _backRotation;

  /// True while the front shows.
  bool isFront = true;

  @override
  void initState() {
    super.initState();
    isFront = widget.side == UCardSide.front;
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
  void didUpdateWidget(UFlipCard oldWidget) {
    widget.controller?.state ??= this;
    super.didUpdateWidget(oldWidget);
  }

  /// Flips with animation.
  Future<void> toggleCard() async {
    widget.onFlip?.call();

    final bool isFrontBefore = isFront;
    controller!.duration = Duration(milliseconds: widget.speed);

    final TickerFuture animation = isFront ? controller!.forward() : controller!.reverse();
    await animation.whenComplete(() {
      widget.onFlipDone?.call(isFront);
      if (!mounted) return;
      setState(() => isFront = !isFrontBefore);
    });
  }

  /// Flips instantly.
  void toggleCardWithoutAnimation() {
    controller!.stop();

    widget.onFlip?.call();

    widget.onFlipDone?.call(isFront);

    setState(() {
      isFront = !isFront;
      controller!.value = isFront ? 0.0 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget Function(Widget child) frontPositioning = widget.fill == UFill.fillFront ? _fill : _noop;
    final Widget Function(Widget child) backPositioning = widget.fill == UFill.fillBack ? _fill : _noop;

    final Stack child = Stack(
      alignment: widget.alignment,
      fit: StackFit.passthrough,
      children: <Widget>[
        frontPositioning(_buildContent(front: true)),
        backPositioning(_buildContent(front: false)),
      ],
    );

    if (widget.flipOnTouch) {
      return UContainer(
        onTap: toggleCard,
        hitTestBehavior: HitTestBehavior.translucent,
        child: child,
      );
    }
    return child;
  }

  Widget _buildContent({required bool front}) => IgnorePointer(
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

Widget _fill(Widget child) => Positioned.fill(child: child);

Widget _noop(Widget child) => child;

/// Flips a UFlipCard from code.
class UFlipCardController {
  /// The connected card.
  UFlipCardState? state;

  /// Its animation.
  AnimationController? get controller {
    assert(state != null, "Controller not attached to any FlipCard. Did you forget to pass the controller to the FlipCard?");
    return state!.controller;
  }

  /// Flips with animation.
  Future<void> toggleCard() async => await state?.toggleCard();

  /// Flips instantly.
  void toggleCardWithoutAnimation() => state?.toggleCardWithoutAnimation();

  /// Tilts the card part way (a teaser).
  Future<void> skew(double amount, {Duration? duration, Curve? curve}) async {
    assert(0 <= amount && amount <= 1);

    final double target = state!.isFront ? amount : 1 - amount;
    await controller?.animateTo(target, duration: duration, curve: curve ?? Curves.linear).asStream().first;
  }

  /// Tilts and returns to hint that it can flip.
  Future<void> hint({Duration? duration, Duration? total}) async {
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
