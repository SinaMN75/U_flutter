import "package:u/utilities.dart";

/// Ready-made AR screens and checks: ARCore (Android), ARKit (iOS), WebXR or camera+compass (web); desktops report unsupported. Needs `permission add camera`. `UArExperiences.place(items: [UArPlaceable(id: "sofa", title: "Sofa", source: UArSource.asset("assets/sofa.glb"))])`
abstract class UArExperiences {
  // --- Ready-made AR screens ------------------------------------------------------------------

  /// Lets the user place 3D products/furniture in the room and move, rotate, scale them. `UArExperiences.place(items: [UArPlaceable(id: "chair", title: "Chair", source: UArSource.url(glbUrl))])`
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

  /// Full-screen 3D viewer with a "View in AR" button (any platform shows 3D; AR where supported). `UArExperiences.viewProduct(source: UArSource.url(glbUrl))`
  static Future<void> viewProduct({required UArSource source, UArSource? iosSource, String? title, List<UArHotspot> hotspots = const <UArHotspot>[], UArLabels labels = const UArLabels()}) =>
      UNavigator.push<void>(
        Scaffold(
          appBar: AppBar(title: title == null ? null : UTextTitleMedium(title)),
          body: U3DViewer(source: source, iosSource: iosSource, title: title, hotspots: hotspots, labels: labels),
        ),
      );

  /// Measures lengths and areas with the camera (Android, iOS).
  static Future<void> measure({UArMeasureUnit unit = UArMeasureUnit.metric, bool closeShape = false}) => UNavigator.push<void>(
    UArPage(
      child: UArMeasure(unit: unit, closeShape: closeShape),
    ),
    fullscreenDialog: true,
  );

  /// Face try-on of glasses, hats, masks with the front camera (iOS Face ID devices, Android ARCore).
  static Future<void> tryOn({required List<UArTryOnItem> items, int initialIndex = 0}) => UNavigator.push<void>(
    UArPage(
      child: UArFaceTryOn(items: items, initialIndex: initialIndex),
    ),
    fullscreenDialog: true,
  );

  /// Shows content when the camera sees one of [targets] (posters, packaging).
  static Future<void> images({required List<UArImageTarget> targets}) => UNavigator.push<void>(UArPage(child: UArImageTrigger(targets: targets)), fullscreenDialog: true);

  /// Shows nearby places as floating labels (needs `permission add location`).
  static Future<void> places({required List<UArPlace> places, void Function(UArPlace place)? onPlaceTap, double maxDistance = 800}) => UNavigator.push<void>(
    UArPage(
      child: UArGeoView(places: places, onPlaceTap: onPlaceTap, maxDistance: maxDistance),
    ),
    fullscreenDialog: true,
  );

  /// Floats a card of your own over every QR code the camera sees.
  static Future<void> codes({required Widget Function(BuildContext context, String code, UArProjection projection) cardBuilder}) =>
      UNavigator.push<void>(UArPage(child: UArCodeView(cardBuilder: cardBuilder)), fullscreenDialog: true);

  /// Scans a room into a 3D floor plan (iPhone/iPad with LiDAR only); null elsewhere.
  static Future<UArRoomScanResult?> scanRoom() => UAr.scanRoom(
    options: UArRoomScanOptions(doneLabel: U.s.done, cancelLabel: U.s.cancel),
  );

  /// Photographs a real object into a 3D model (iOS 17+ with LiDAR); null elsewhere.
  static Future<UArObjectCaptureResult?> captureObject({UArObjectCaptureDetail detail = UArObjectCaptureDetail.reduced}) => UAr.captureObject(
    options: UArObjectCaptureOptions(
      detail: detail,
      labels: <String, String>{"continue": U.s.next, "start": U.s.startCapture, "finish": U.s.finish, "cancel": U.s.cancel, "processing": U.s.processing},
    ),
  );

  // --- AR engine (UAr) -------------------------------------------------------------------------

  /// Whether AR can run: supported, needs ARCore install, unsupported…
  static Future<UArAvailability> availability() => UAr.availability();

  /// Which AR features this device has (planes, faces, depth, geo, LiDAR…).
  static Future<UArCapabilities> capabilities() => UAr.capabilities();

  /// True when live AR can run right now. `if (await UArExperiences.isSupported()) …`
  static Future<bool> isSupported() async => (await UAr.availability()).isSupported;

  /// Android: asks to install/update ARCore from Play; returns the new availability.
  static Future<UArAvailability> requestInstall() => UAr.requestInstall();

  /// Camera (and location/microphone) permission for AR.
  static Future<UArPermissionState> permission() => UAr.permissionStatus();

  /// Asks for the camera, and optionally location/microphone.
  static Future<UArPermissionState> requestPermission({bool location = false, bool microphone = false}) => UAr.requestPermission(location: location, microphone: microphone);

  /// Opens the app's settings to grant a denied permission.
  static Future<bool> openSettings() => UAr.openSettings();

  /// Opens a model in the OS viewer: Quick Look (iOS), Scene Viewer (Android).
  static Future<bool> openNativeViewer(UArNativeViewerOptions options) => UAr.openNativeViewer(options);

  /// Renders a Flutter widget to PNG bytes (for labels/cards placed in AR).
  static Future<Uint8List?> renderWidget(Widget widget, {Size size = const Size(320, 200), double pixelRatio = 3, BuildContext? context}) =>
      UArWidgetRenderer.render(widget, size: size, pixelRatio: pixelRatio, context: context);
}
