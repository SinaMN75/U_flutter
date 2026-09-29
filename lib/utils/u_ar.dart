import "package:u/utilities.dart";

/// Augmented reality and 3D: ready-made AR screens plus the AR engine's checks and tools.
abstract class UArExperiences {
  // --- Ready-made AR screens ------------------------------------------------------------------

  /// Lets the user place products / furniture / art in their space.
  static Future<void> place({
    required List<UArPlaceable> items,
    int initialItem = 0,
    UArConfig config = const UArConfig(reticle: true),
    UArSceneOptions options = const UArSceneOptions(),
    List<UArOverlay> overlays = const <UArOverlay>[],
    UArLabels labels = const UArLabels(),
    UArStyle style = const UArStyle(),
    void Function(UArPlacedItem placed)? onPlaced,
  }) async {
    await UNavigator.push<void>(
      UArPage(
        child: UArGate(
          labels: labels,
          style: style,
          fallback: (BuildContext context, UArAvailability availability) => UArNativeFallback(items: items, labels: labels, style: style),
          builder: (BuildContext context, UArCapabilities capabilities) => UArScene(
            gate: false,
            items: items,
            initialItem: initialItem,
            config: config,
            options: options,
            overlays: overlays,
            labels: labels,
            style: style,
            onPlaced: onPlaced,
          ),
        ),
      ),
      fullscreenDialog: true,
    );
  }

  /// A full-screen 3D product viewer with a "View in AR" button.
  static Future<void> viewProduct({required UArSource source, UArSource? iosSource, String? title, List<UArHotspot> hotspots = const <UArHotspot>[], UArLabels labels = const UArLabels()}) =>
      UNavigator.push<void>(
        Scaffold(
          appBar: AppBar(title: title == null ? null : UTextTitleMedium(title)),
          body: U3DViewer(source: source, iosSource: iosSource, title: title, hotspots: hotspots, labels: labels),
        ),
      );

  /// Measures distances / areas in the real world with the camera.
  static Future<void> measure({UArMeasureUnit unit = UArMeasureUnit.metric, bool closeShape = false}) => UNavigator.push<void>(
    UArPage(
      child: UArMeasure(unit: unit, closeShape: closeShape),
    ),
    fullscreenDialog: true,
  );

  /// Face try-on (glasses, hats, masks) with the front camera.
  static Future<void> tryOn({required List<UArTryOnItem> items, int initialIndex = 0}) => UNavigator.push<void>(
    UArPage(
      child: UArFaceTryOn(items: items, initialIndex: initialIndex),
    ),
    fullscreenDialog: true,
  );

  /// Shows content when the camera sees one of [targets] (posters, packaging, …).
  static Future<void> images({required List<UArImageTarget> targets}) => UNavigator.push<void>(UArPage(child: UArImageTrigger(targets: targets)), fullscreenDialog: true);

  /// Shows nearby places as floating labels in the camera view.
  static Future<void> places({required List<UArPlace> places, void Function(UArPlace place)? onPlaceTap, double maxDistance = 800}) => UNavigator.push<void>(
    UArPage(
      child: UArGeoView(places: places, onPlaceTap: onPlaceTap, maxDistance: maxDistance),
    ),
    fullscreenDialog: true,
  );

  /// Shows a card floating over every QR code the camera sees.
  static Future<void> codes({required Widget Function(BuildContext context, String code, UArProjection projection) cardBuilder}) =>
      UNavigator.push<void>(UArPage(child: UArCodeView(cardBuilder: cardBuilder)), fullscreenDialog: true);

  /// Scans a room into a 3D floor plan (iOS LiDAR devices).
  static Future<UArRoomScanResult?> scanRoom() => UAr.scanRoom(
    options: UArRoomScanOptions(doneLabel: U.s.done, cancelLabel: U.s.cancel),
  );

  /// Captures a real object into a 3D model (iOS object capture).
  static Future<UArObjectCaptureResult?> captureObject({UArObjectCaptureDetail detail = UArObjectCaptureDetail.reduced}) => UAr.captureObject(
    options: UArObjectCaptureOptions(
      detail: detail,
      labels: <String, String>{"continue": U.s.next, "start": U.s.startCapture, "finish": U.s.finish, "cancel": U.s.cancel, "processing": U.s.processing},
    ),
  );

  // --- AR engine (UAr) -------------------------------------------------------------------------

  /// Whether AR works here (supported, needs install, unsupported, …).
  static Future<UArAvailability> availability() => UAr.availability();

  /// What AR features this device has (planes, faces, depth, geo, LiDAR, …).
  static Future<UArCapabilities> capabilities() => UAr.capabilities();

  /// True when live AR can run right now.
  static Future<bool> isSupported() async => (await UAr.availability()).isSupported;

  /// Asks the user to install / update ARCore (Android).
  static Future<UArAvailability> requestInstall() => UAr.requestInstall();

  /// Current camera (and location / microphone) permission for AR.
  static Future<UArPermissionState> permission() => UAr.permissionStatus();

  /// Asks for the camera (and optionally location / microphone) permission.
  static Future<UArPermissionState> requestPermission({bool location = false, bool microphone = false}) => UAr.requestPermission(location: location, microphone: microphone);

  /// Opens the app's settings page so the user can grant permission.
  static Future<bool> openSettings() => UAr.openSettings();

  /// Opens a 3D model in the OS viewer (Quick Look on iOS, Scene Viewer on Android).
  static Future<bool> openNativeViewer(UArNativeViewerOptions options) => UAr.openNativeViewer(options);

  /// Renders a Flutter widget to PNG bytes (for labels and cards placed in AR).
  static Future<Uint8List?> renderWidget(Widget widget, {Size size = const Size(320, 200), double pixelRatio = 3, BuildContext? context}) =>
      UArWidgetRenderer.render(widget, size: size, pixelRatio: pixelRatio, context: context);
}
