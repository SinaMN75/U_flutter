import "dart:ui";

import "package:u/utilities.dart";

class ULoading {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;
  static WidgetBuilder? _customLoaderBuilder;
  static Color _overlayColor = Colors.black54;
  static Duration _animationDuration = const Duration(milliseconds: 300);
  static Curve _animationCurve = Curves.easeInOut;
  static double _blurAmount = 2;
  static bool _dismissible = false;
  static bool _useDefaultLoader = true;
  static String _defaultLoadingText = "Loading...";
  static Color _defaultSpinnerColor = Colors.white;
  static double _defaultSpinnerSize = 40;

  static void initialize({
    WidgetBuilder? customLoaderBuilder,
    Color overlayColor = Colors.black54,
    Duration animationDuration = const Duration(milliseconds: 300),
    Curve animationCurve = Curves.easeInOut,
    double blurAmount = 2.0,
    bool dismissible = false,
    bool useDefaultLoader = true,
    String defaultLoadingText = "",
    Color defaultSpinnerColor = Colors.white,
    double defaultSpinnerSize = 40.0,
    GlobalKey<NavigatorState>? key,
  }) {
    _customLoaderBuilder = customLoaderBuilder;
    _overlayColor = overlayColor;
    _animationDuration = animationDuration;
    _animationCurve = animationCurve;
    _blurAmount = blurAmount;
    _dismissible = dismissible;
    _useDefaultLoader = useDefaultLoader;
    _defaultLoadingText = defaultLoadingText;
    _defaultSpinnerColor = defaultSpinnerColor;
    _defaultSpinnerSize = defaultSpinnerSize;
    if (key != null) navigatorKey = key;
  }

  static void show({BuildContext? context, WidgetBuilder? customLoader}) {
    if (_isShowing) return;
    final OverlayState? overlayState = (context != null ? Overlay.of(context) : navigatorKey.currentState?.overlay);
    if (overlayState == null) return;
    _overlayEntry = OverlayEntry(
      builder: (BuildContext _) => _LoadingOverlay(customLoader: customLoader ?? _customLoaderBuilder),
    );
    overlayState.insert(_overlayEntry!);
    _isShowing = true;
  }

  static void dismiss() {
    if (!_isShowing) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  static bool isShowing() => _isShowing;
}

class _LoadingOverlay extends StatefulWidget {
  const _LoadingOverlay({this.customLoader});

  final WidgetBuilder? customLoader;

  @override
  State<_LoadingOverlay> createState() => __LoadingOverlayState();
}

class __LoadingOverlayState extends State<_LoadingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: ULoading._animationDuration, vsync: this);
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: ULoading._animationCurve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacityAnimation,
    child: Stack(
      children: <Widget>[
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: ULoading._blurAmount, sigmaY: ULoading._blurAmount),
            child: Container(color: ULoading._overlayColor),
          ),
        ),
        if (ULoading._dismissible)
          Positioned.fill(
            child: GestureDetector(
              onTap: ULoading.dismiss,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
        Center(
          child: widget.customLoader != null
              ? widget.customLoader!(context)
              : ULoading._useDefaultLoader
              ? _buildDefaultLoader()
              : const SizedBox(),
        ),
      ],
    ),
  );

  Widget _buildDefaultLoader() => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(
        width: ULoading._defaultSpinnerSize,
        height: ULoading._defaultSpinnerSize,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ULoading._defaultSpinnerColor),
          strokeWidth: 3,
        ),
      ),
      const SizedBox(height: 16),
      UTextBodyLarge(ULoading._defaultLoadingText, color: Colors.white),
    ],
  );
}
