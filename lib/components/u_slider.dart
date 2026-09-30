import "package:u/utilities.dart";

/// Auto-playing image slider (banners) with dots. `USlider(images: banners.map((b) => UImage(b)).toList())`
class USlider extends StatefulWidget {
  const USlider({
    required this.images,
    super.key,
    this.height = 200,
    this.indicatorHeight = 30,
    this.activeIndicatorColor = Colors.white,
    this.inactiveIndicatorColor = Colors.grey,
    this.indicatorActiveSize = 10,
    this.indicatorInactiveSize = 8,
    this.autoPlayDuration = 7,
    this.imageFit = BoxFit.cover,
    this.radius = 0,
    this.imagePlaceholderColor = Colors.grey,
    this.errorWidget,
    this.withIndicator = true,
    this.autoPlay = true,
    this.viewportFraction = 1.0,
    this.onPageChanged,
  });

  /// Slides.
  final List<Widget> images;

  /// Height in logical pixels (null = size to content).
  final double height;

  /// Dot row height.
  final double indicatorHeight;

  /// Current dot color.
  final Color activeIndicatorColor;

  /// Other dot color.
  final Color inactiveIndicatorColor;

  /// Current dot size.
  final double indicatorActiveSize;

  /// Other dot size.
  final double indicatorInactiveSize;

  /// Seconds per slide (0 = no auto play).
  final int autoPlayDuration;

  /// How images fill a slide.
  final BoxFit imageFit;

  /// Corner radius.
  final double radius;

  /// Color while loading.
  final Color imagePlaceholderColor;

  /// Shown when an image fails.
  final Widget? errorWidget;

  /// Shows the dots.
  final bool withIndicator;

  /// When false the slider never advances on its own.
  final bool autoPlay;

  /// < 1.0 lets neighbouring pages peek in from the sides.
  final double viewportFraction;

  /// Fired with the new page index whenever the visible page changes.
  final ValueChanged<int>? onPageChanged;

  @override
  State<USlider> createState() => _USliderState();
}

class _USliderState extends State<USlider> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant USlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoPlay != oldWidget.autoPlay) {
      widget.autoPlay ? _startAutoPlay() : _stopAutoPlay();
    }
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (!widget.autoPlay || widget.images.length <= 1) return;
    _stopAutoPlay();
    _autoPlayTimer = Timer.periodic(
      Duration(seconds: widget.autoPlayDuration),
      (Timer timer) {
        if (_currentPage < widget.images.length - 1) {
          _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        } else {
          _pageController.animateToPage(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      },
    );
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    widget.onPageChanged?.call(page);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      UContainer(
        height: widget.height,
        color: widget.imagePlaceholderColor,
        radius: widget.radius,
        clipBehavior: Clip.hardEdge,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: widget.images.length,
          itemBuilder: (BuildContext context, int index) => widget.images[index],
        ),
      ),
      if (widget.images.length > 1 && widget.withIndicator)
        SizedBox(
          height: widget.indicatorHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(
              widget.images.length,
              (int index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? widget.indicatorActiveSize : widget.indicatorInactiveSize,
                height: _currentPage == index ? widget.indicatorActiveSize : widget.indicatorInactiveSize,
                decoration: BoxDecoration(
                  color: _currentPage == index ? widget.activeIndicatorColor : widget.inactiveIndicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ).alignAtCenter(),
        ),
    ],
  );
}

/// Moves a UCarousel from code and controls auto play.
class UCarouselController {
  _UCarouselBinding? _binding;

  void _attach(_UCarouselBinding binding) => _binding = binding;

  void _detach(_UCarouselBinding binding) {
    if (identical(_binding, binding)) _binding = null;
  }

  /// Next page.
  void next() => _binding?.next();

  /// Previous page.
  void previous() => _binding?.previous();

  /// Goes to a page.
  void animateToPage(int page, {bool animate = true}) => _binding?.animateToPage(page, animate: animate);

  /// Starts auto play.
  void startAutoPlay() => _binding?.startAutoPlay();

  /// Stops auto play.
  void stopAutoPlay() => _binding?.stopAutoPlay();

  /// Starts/stops auto play.
  void toggleAutoPlay() => isAutoPlaying ? stopAutoPlay() : startAutoPlay();

  /// True while auto playing.
  bool get isAutoPlaying => _binding?.isAutoPlaying ?? false;

  /// Current page index.
  int get currentPage => _binding?.currentPage ?? 0;
}

abstract class _UCarouselBinding {
  void next();

  void previous();

  void animateToPage(int page, {bool animate});

  void startAutoPlay();

  void stopAutoPlay();

  bool get isAutoPlaying;

  int get currentPage;
}

/// Carousel of any items with peeking neighbours, loop, auto play and dots. `UCarousel<Product>(items: products, itemBuilder: (c, p, i) => ProductCard(p))`
class UCarousel<T> extends StatefulWidget {
  const UCarousel({
    required this.items,
    required this.itemBuilder,
    super.key,
    this.controller,
    this.height = 200,
    this.viewportFraction = 0.9,
    this.initialPage = 0,
    this.itemSpacing = 0,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 450),
    this.autoPlayCurve = Curves.easeInOut,
    this.pauseAutoPlayOnTouch = true,
    this.loop = false,
    this.padEnds = true,
    this.scrollDirection = Axis.horizontal,
    this.physics,
    this.onPageChanged,
    this.withIndicator = false,
    this.indicatorHeight = 24,
    this.activeIndicatorColor,
    this.inactiveIndicatorColor,
    this.indicatorActiveSize = 9,
    this.indicatorInactiveSize = 7,
  });

  /// The items to show.
  final List<T> items;

  /// Builds one item.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Controller to read or change it from code.
  final UCarouselController? controller;

  /// Height in logical pixels (null = size to content).
  final double height;

  /// Part of the width each item takes (0.8 shows neighbours).
  final double viewportFraction;

  /// First page.
  final int initialPage;

  /// Gap between items.
  final double itemSpacing;

  /// Starts playing as soon as it is ready.
  final bool autoPlay;

  /// Time per page in auto play.
  final Duration autoPlayInterval;

  /// Page change animation length.
  final Duration autoPlayAnimationDuration;

  /// Page change curve.
  final Curve autoPlayCurve;

  /// Pauses while touched.
  final bool pauseAutoPlayOnTouch;

  /// Wraps around at the ends.
  final bool loop;

  /// Centers the first/last item.
  final bool padEnds;

  /// Scroll axis.
  final Axis scrollDirection;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Called with the new page index.
  final void Function(T item, int index)? onPageChanged;

  /// Shows dots.
  final bool withIndicator;

  /// Dot row height.
  final double indicatorHeight;

  /// Current dot color.
  final Color? activeIndicatorColor;

  /// Other dot color.
  final Color? inactiveIndicatorColor;

  /// Current dot size.
  final double indicatorActiveSize;

  /// Other dot size.
  final double indicatorInactiveSize;

  @override
  State<UCarousel<T>> createState() => _UCarouselState<T>();
}

class _UCarouselState<T> extends State<UCarousel<T>> implements _UCarouselBinding {
  static const int _loopMultiplier = 2000;

  late PageController _pageController;
  Timer? _timer;
  int _rawPage = 0;
  int _current = 0;

  int get _count => widget.items.length;

  bool get _loop => widget.loop && _count > 1;

  int get _itemCount => _loop ? _count * _loopMultiplier : _count;

  int get _initialRawPage => _loop ? (_count * (_loopMultiplier ~/ 2)) + widget.initialPage : widget.initialPage;

  @override
  void initState() {
    super.initState();
    _current = _count == 0 ? 0 : widget.initialPage % _count;
    _rawPage = _initialRawPage;
    _pageController = PageController(viewportFraction: widget.viewportFraction, initialPage: _rawPage);
    widget.controller?._attach(this);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant UCarousel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (widget.autoPlay != oldWidget.autoPlay || widget.items.length != oldWidget.items.length) {
      widget.autoPlay ? _startAutoPlay() : _stopAutoPlay();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void startAutoPlay() => _startAutoPlay();

  @override
  void stopAutoPlay() => _stopAutoPlay();

  void _startAutoPlay() {
    if (!widget.autoPlay || _count <= 1) return;
    _stopAutoPlay();
    _timer = Timer.periodic(widget.autoPlayInterval, (Timer _) => next());
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  bool get isAutoPlaying => _timer?.isActive ?? false;

  @override
  int get currentPage => _current;

  @override
  void next() {
    if (_count <= 1) return;
    if (_loop || _current < _count - 1) {
      _pageController.nextPage(duration: widget.autoPlayAnimationDuration, curve: widget.autoPlayCurve);
    } else {
      animateToPage(0);
    }
  }

  @override
  void previous() {
    if (_count <= 1) return;
    if (_loop || _current > 0) {
      _pageController.previousPage(duration: widget.autoPlayAnimationDuration, curve: widget.autoPlayCurve);
    } else {
      animateToPage(_count - 1);
    }
  }

  @override
  void animateToPage(int page, {bool animate = true}) {
    if (_count == 0) return;
    final int target = page % _count;
    final int rawTarget = _loop ? _rawPage + (target - _current) : target;
    if (animate) {
      _pageController.animateToPage(rawTarget, duration: widget.autoPlayAnimationDuration, curve: widget.autoPlayCurve);
    } else {
      _pageController.jumpToPage(rawTarget);
    }
  }

  void _handlePageChanged(int rawPage) {
    _rawPage = rawPage;
    final int index = _count == 0 ? 0 : rawPage % _count;
    setState(() => _current = index);
    if (_count > 0) widget.onPageChanged?.call(widget.items[index], index);
  }

  void _onPointerDown() {
    if (widget.pauseAutoPlayOnTouch) _stopAutoPlay();
  }

  void _onPointerUp() {
    if (widget.pauseAutoPlayOnTouch && widget.autoPlay) _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return SizedBox(height: widget.height);
    final ColorScheme scheme = context.colorScheme;
    final double pad = widget.itemSpacing / 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: widget.height,
          child: Listener(
            onPointerDown: (PointerDownEvent _) => _onPointerDown(),
            onPointerUp: (PointerUpEvent _) => _onPointerUp(),
            onPointerCancel: (PointerCancelEvent _) => _onPointerUp(),
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: widget.scrollDirection,
              physics: widget.physics,
              padEnds: widget.padEnds,
              onPageChanged: _handlePageChanged,
              itemCount: _itemCount,
              itemBuilder: (BuildContext context, int rawIndex) {
                final int index = rawIndex % _count;
                final Widget child = widget.itemBuilder(context, widget.items[index], index);
                return pad > 0 ? child.pSymmetric(horizontal: pad) : child;
              },
            ),
          ),
        ),
        if (widget.withIndicator && _count > 1)
          SizedBox(
            height: widget.indicatorHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                _count,
                (int index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == index ? widget.indicatorActiveSize : widget.indicatorInactiveSize,
                  height: _current == index ? widget.indicatorActiveSize : widget.indicatorInactiveSize,
                  decoration: BoxDecoration(
                    color: _current == index ? (widget.activeIndicatorColor ?? scheme.primary) : (widget.inactiveIndicatorColor ?? scheme.outlineVariant),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
