import "package:u/utilities.dart";

/// Screenshot and screen-recording protection.
///
/// Prevention itself is native and platform specific — Android FLAG_SECURE,
/// the iOS secure-layer canvas, macOS `sharingType`, Windows display affinity.
/// This layer adds the Flutter-side PrintScreen interception, the capture state
/// [UScreenGuard] paints over, and the enforcement that closes the app the
/// moment a capture is detected.
abstract class ScreenGuard {
  static const MethodChannel _channel = MethodChannel("u/screen_guard");

  static void Function()? onScreenshot;
  static void Function(bool active)? onScreenRecording;
  static void Function(String reason)? onViolation;

  static final RxBool isCapturing = false.obs;

  static bool exitOnCapture = true;
  static bool _enabled = false;
  static bool _handlerAttached = false;
  static bool _terminating = false;

  static bool get isEnabled => _enabled;

  static Future<void> enable({bool exitOnCapture = true}) async {
    ScreenGuard.exitOnCapture = exitOnCapture;
    _enabled = true;
    _attachHandler();
    HardwareKeyboard.instance.addHandler(_onKey);
    try {
      await _channel.invokeMethod<void>("enable", <String, dynamic>{"exitOnCapture": exitOnCapture});
    } catch (_) {}
  }

  static Future<void> disable() async {
    _enabled = false;
    isCapturing.value = false;
    HardwareKeyboard.instance.removeHandler(_onKey);
    try {
      await _channel.invokeMethod<void>("disable");
    } catch (_) {}
  }

  static Future<bool> isCaptured() async {
    try {
      return await _channel.invokeMethod<bool>("isCaptured") ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> terminate() async {
    if (_terminating) return;
    _terminating = true;
    try {
      await _channel.invokeMethod<void>("terminate");
    } catch (_) {}
    if (kIsWeb) return;
    await SystemNavigator.pop();
    exit(0);
  }

  static void _attachHandler() {
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case "onScreenshot":
          onScreenshot?.call();
        case "onScreenRecording":
          final bool active = call.arguments == true;
          isCapturing.value = active;
          onScreenRecording?.call(active);
        case "onViolation":
          _punish(call.arguments?.toString() ?? "capture");
      }
    });
  }

  // PrintScreen never reaches the platform channels on web and Linux, so the
  // key press itself is treated as a capture attempt.
  static bool _onKey(KeyEvent event) {
    if (!_enabled || event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.printScreen) return false;
    onScreenshot?.call();
    _punish("screenshot");
    return true;
  }

  static void _punish(String reason) {
    onViolation?.call(reason);
    if (exitOnCapture) unawaited(terminate());
  }
}

/// Enables [ScreenGuard] for the lifetime of [child] and covers it while a
/// capture is in progress.
class UScreenGuard extends StatefulWidget {
  const UScreenGuard({required this.child, this.exitOnCapture = true, this.message, super.key});

  final Widget child;
  final bool exitOnCapture;
  final String? message;

  @override
  State<UScreenGuard> createState() => _UScreenGuardState();
}

class _UScreenGuardState extends State<UScreenGuard> {
  @override
  void initState() {
    super.initState();
    unawaited(ScreenGuard.enable(exitOnCapture: widget.exitOnCapture));
  }

  @override
  void dispose() {
    unawaited(ScreenGuard.disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      widget.child,
      Positioned.fill(
        child: Obx(
          () => ScreenGuard.isCapturing.value
              ? ColoredBox(
                  color: Theme.of(context).colorScheme.scrim,
                  child: Center(
                    child: UTextTitleMedium(
                      widget.message ?? U.s.screenCaptureNotAllowed,
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      textAlign: TextAlign.center,
                    ).pSymmetric(horizontal: 24),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    ],
  );
}
