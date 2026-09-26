import "dart:ui" as ui;

import "package:flutter/scheduler.dart";
import "package:u/utilities.dart";

/// HOST PROJECT SETUP
///
/// The package declares no camera or location permission and bundles no AR
/// SDK, because its manifests are merged into every app that depends on it.
/// The 3D viewer ([U3DViewer], [UArConfig.viewer]) needs none of this; every
/// camera-based experience needs the entries for the platforms you ship.
///
/// ANDROID -- android/app/build.gradle(.kts), inside `dependencies`:
///
/// ```kotlin
/// implementation("com.google.ar:core:1.45.0")
/// ```
///
///   ARCore is the only native library AR needs; the renderer is part of this
///   package. Without it every AR mode reports [UArAvailabilityStatus.sdkMissing]
///   and only the viewer works. Then android/app/src/main/AndroidManifest.xml,
///   inside `<manifest>`:
///
/// ```xml
/// <uses-permission android:name="android.permission.CAMERA" />
/// <uses-feature android:name="android.hardware.camera.ar" android:required="false" />
/// <!-- location content (UArGeoView, addGeoAnchor): -->
/// <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
/// <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
/// <!-- recording with sound: -->
/// <uses-permission android:name="android.permission.RECORD_AUDIO" />
/// ```
///
///   Geospatial (street-level visual positioning) and Cloud Anchors call
///   Google Cloud: enable the "ARCore API" in a Google Cloud project and add,
///   inside `<application>`:
///
/// ```xml
/// <meta-data android:name="com.google.android.ar.API_KEY" android:value="YOUR_KEY" />
/// ```
///
///   Without the key those two features fail with notAuthorized; everything
///   else, including GPS + compass location content, keeps working.
///
/// IOS -- ios/Runner/Info.plist, inside the top-level `<dict>`:
///
/// ```xml
/// <key>NSCameraUsageDescription</key>
/// <string>Used to place products and information in your space.</string>
/// <key>NSLocationWhenInUseUsageDescription</key>
/// <string>Used to show places around you.</string>
/// <key>NSMicrophoneUsageDescription</key>
/// <string>Used to record video with sound.</string>
/// <key>NSPhotoLibraryAddUsageDescription</key>
/// <string>Used to save photos and videos.</string>
/// ```
///
///   AR needs iOS 15; room scanning iOS 16 and object capture iOS 17, both on
///   LiDAR devices. USDZ / Reality models load natively, GLB / glTF through the
///   built-in converter (static and node-animated; use USDZ for skinned rigs).
///
/// WEB:
///
///   Serve over https. Chrome on Android runs full WebXR AR after
///   [UArController.enterXr] is called from a tap; other mobile browsers,
///   including iOS Safari, get the camera + compass mode for location content
///   and AR Quick Look / Scene Viewer through [UAr.openNativeViewer]. Models on
///   another origin must send CORS headers.
///
/// MODELS: GLB is the portable format (Android, web, iOS). For AR Quick Look
/// on iOS, pass a USDZ as `iosSource`. Draco / meshopt compressed GLB files are
/// not supported; export them uncompressed.
/// -----------------------------------------------------------------------------

enum UArPlacementMode { tap, reticle }

enum UArSurface { any, horizontal, vertical, floor, wall, table, ceiling }

enum UArMeasureUnit { metric, imperial }

/// Optional label overrides; anything left null falls back to l10n.
class UArLabels {
  const UArLabels({
    this.unsupported,
    this.installRequired,
    this.install,
    this.permission,
    this.locationPermission,
    this.openSettings,
    this.startAr,
    this.viewInYourSpace,
    this.viewInAr,
    this.loadingModel,
    this.loadFailed,
    this.scanning,
    this.tooFast,
    this.moreDetail,
    this.tooDark,
    this.relocalizing,
    this.findSurface,
    this.tapToPlace,
    this.gestures,
    this.chooseItem,
    this.noPlaces,
    this.waitingForLocation,
    this.calibrateCompass,
    this.tapToAddPoint,
    this.lookAtCamera,
    this.pointAtImage,
    this.pointAtCode,
    this.recording,
  });

  final String? unsupported;
  final String? installRequired;
  final String? install;
  final String? permission;
  final String? locationPermission;
  final String? openSettings;
  final String? startAr;
  final String? viewInYourSpace;
  final String? viewInAr;
  final String? loadingModel;
  final String? loadFailed;
  final String? scanning;
  final String? tooFast;
  final String? moreDetail;
  final String? tooDark;
  final String? relocalizing;
  final String? findSurface;
  final String? tapToPlace;
  final String? gestures;
  final String? chooseItem;
  final String? noPlaces;
  final String? waitingForLocation;
  final String? calibrateCompass;
  final String? tapToAddPoint;
  final String? lookAtCamera;
  final String? pointAtImage;
  final String? pointAtCode;
  final String? recording;
}

/// Colours and shapes of the built-in chrome. Null values follow the app theme.
class UArStyle {
  const UArStyle({
    this.accentColor,
    this.onAccentColor,
    this.surfaceColor,
    this.onSurfaceColor,
    this.hintBackground,
    this.hintForeground,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.blur = true,
  });

  final Color? accentColor;

  /// Text and icons drawn on [accentColor].
  final Color? onAccentColor;
  final Color? surfaceColor;
  final Color? onSurfaceColor;
  final Color? hintBackground;
  final Color? hintForeground;
  final double borderRadius;
  final EdgeInsets padding;
  final bool blur;

  Color accent(BuildContext context) => accentColor ?? Theme.of(context).colorScheme.primary;

  Color onAccent(BuildContext context) {
    if (onAccentColor != null) return onAccentColor!;
    if (accentColor == null) return Theme.of(context).colorScheme.onPrimary;
    return ThemeData.estimateBrightnessForColor(accentColor!) == Brightness.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  }

  Color surface(BuildContext context) => surfaceColor ?? Theme.of(context).colorScheme.surface.withValues(alpha: 0.9);

  Color onSurface(BuildContext context) => onSurfaceColor ?? Theme.of(context).colorScheme.onSurface;

  Color hintBg(BuildContext context) => hintBackground ?? Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.72);

  Color hintFg(BuildContext context) => hintForeground ?? Theme.of(context).colorScheme.onInverseSurface;
}

/// Forces [color] on text and icons below, including `UText*` widgets, which
/// read their colour from the theme's text styles rather than [DefaultTextStyle].
class UArForeground extends StatelessWidget {
  const UArForeground({required this.color, required this.child, super.key});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(bodyColor: color, displayColor: color),
        iconTheme: theme.iconTheme.copyWith(color: color),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: color),
        child: IconTheme.merge(data: IconThemeData(color: color), child: child),
      ),
    );
  }
}

// =============================================================================
// Shared building blocks
// =============================================================================

/// A Flutter widget pinned to a node, an anchor or a world point.
class UArOverlay {
  const UArOverlay({
    required this.id,
    required this.builder,
    this.nodeId,
    this.anchorId,
    this.offset = UArVector3.zero,
    this.alignment = Alignment.bottomCenter,
    this.scaleWithDistance = true,
    this.referenceDistance = 1.5,
    this.minScale = 0.45,
    this.maxScale = 1.25,
    this.maxDistance,
    this.hideWhenOffscreen = true,
    this.onTap,
  });

  final String id;
  final Widget Function(BuildContext context, UArProjection projection) builder;
  final String? nodeId;
  final String? anchorId;

  /// Local to the node / anchor, or a world point when neither is set.
  final UArVector3 offset;

  /// Which point of the widget sits on the tracked point.
  final Alignment alignment;
  final bool scaleWithDistance;
  final double referenceDistance;
  final double minScale;
  final double maxScale;
  final double? maxDistance;
  final bool hideWhenOffscreen;
  final VoidCallback? onTap;
}

/// Lays [overlays] over an AR / 3D view and keeps them glued to the world.
class UArOverlayLayer extends StatefulWidget {
  const UArOverlayLayer({required this.controller, required this.overlays, super.key});

  final UArController controller;
  final List<UArOverlay> overlays;

  @override
  State<UArOverlayLayer> createState() => _UArOverlayLayerState();
}

class _UArOverlayLayerState extends State<UArOverlayLayer> {
  Set<String> _tracked = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_sync());
  }

  @override
  void didUpdateWidget(covariant UArOverlayLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_sync());
  }

  @override
  void dispose() {
    for (final String id in _tracked) {
      if (!widget.controller.isDisposed) unawaited(widget.controller.untrack(id).catchError((Object _) {}));
    }
    super.dispose();
  }

  Future<void> _sync() async {
    final Set<String> wanted = widget.overlays.map((UArOverlay o) => o.id).toSet();
    try {
      for (final String id in _tracked.difference(wanted)) {
        await widget.controller.untrack(id);
      }
      for (final UArOverlay overlay in widget.overlays) {
        await widget.controller.track(overlay.id, nodeId: overlay.nodeId, anchorId: overlay.anchorId, offset: overlay.offset);
      }
    } catch (_) {}
    _tracked = wanted;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) => ValueListenableBuilder<Map<String, UArProjection>>(
      valueListenable: widget.controller.projections,
      builder: (BuildContext context, Map<String, UArProjection> projections, Widget? _) {
        final Size size = constraints.biggest;
        final List<(UArOverlay, UArProjection)> visible = <(UArOverlay, UArProjection)>[];
        for (final UArOverlay overlay in widget.overlays) {
          final UArProjection? projection = projections[overlay.id];
          if (projection == null) continue;
          if (overlay.hideWhenOffscreen && !projection.isVisible) continue;
          if (overlay.maxDistance != null && projection.distance > overlay.maxDistance!) continue;
          visible.add((overlay, projection));
        }
        visible.sort(((UArOverlay, UArProjection) a, (UArOverlay, UArProjection) b) => b.$2.distance.compareTo(a.$2.distance));
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (final (UArOverlay, UArProjection) entry in visible) _positioned(context, size, entry.$1, entry.$2),
          ],
        );
      },
    ),
  );

  Widget _positioned(BuildContext context, Size size, UArOverlay overlay, UArProjection projection) {
    final Offset point = projection.toOffset(size);
    final double scale = overlay.scaleWithDistance ? (overlay.referenceDistance / max(projection.distance, 0.05)).clamp(overlay.minScale, overlay.maxScale) : 1;
    Widget child = overlay.builder(context, projection);
    if (overlay.onTap != null) child = GestureDetector(onTap: overlay.onTap, child: child);
    return Positioned(
      left: point.dx,
      top: point.dy,
      child: FractionalTranslation(
        translation: Offset(-(overlay.alignment.x + 1) / 2, -(overlay.alignment.y + 1) / 2),
        child: Transform.scale(scale: scale, alignment: overlay.alignment, child: child),
      ),
    );
  }
}

/// A rounded, translucent pill used for hints and chips.
class UArPill extends StatelessWidget {
  const UArPill({required this.child, this.style = const UArStyle(), this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10), super.key});

  final Widget child;
  final UArStyle style;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final Widget content = DecoratedBox(
      decoration: BoxDecoration(color: style.hintBg(context), borderRadius: BorderRadius.circular(style.borderRadius)),
      child: Padding(
        padding: padding,
        child: UArForeground(color: style.hintFg(context), child: child),
      ),
    );
    if (!style.blur) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(style.borderRadius),
      child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: content),
    );
  }
}

class UArRoundButton extends StatelessWidget {
  const UArRoundButton({required this.icon, required this.onTap, this.tooltip, this.size = 48, this.active = false, this.style = const UArStyle(), super.key});

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final bool active;
  final UArStyle style;

  @override
  Widget build(BuildContext context) {
    final Color background = active ? style.accent(context) : style.hintBg(context);
    final Color foreground = active ? style.onAccent(context) : style.hintFg(context);
    final Widget button = Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: foreground, size: size * 0.46),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// Human wording for the current tracking state, or null when all is well.
String? uArTrackingHint(UArValue value, UArLabels labels, {bool needsSurface = true}) {
  if (value.state != UArSessionState.running || value.config.isViewer) return null;
  switch (value.trackingReason) {
    case UArTrackingReason.excessiveMotion:
      return labels.tooFast ?? U.s.slowDownYouAreMovingTooFast;
    case UArTrackingReason.insufficientFeatures:
      return labels.moreDetail ?? U.s.pointAtASurfaceWithMoreDetail;
    case UArTrackingReason.insufficientLight:
      return labels.tooDark ?? U.s.itsTooDarkTurnOnMoreLights;
    case UArTrackingReason.relocalizing:
      return labels.relocalizing ?? U.s.holdSteadyWhileTheSessionIsRestored;
    default:
      break;
  }
  if (value.tracking != UArTrackingState.normal) return labels.scanning ?? U.s.moveYourPhoneSlowlyToScanTheArea;
  if (needsSurface && !value.hasPlanes && value.frame.centerHit == null) return labels.findSurface ?? U.s.lookAroundToFindASurface;
  return null;
}

String uArFormatDistance(double metres, {UArMeasureUnit unit = UArMeasureUnit.metric}) {
  if (unit == UArMeasureUnit.imperial) {
    final double inches = metres / 0.0254;
    if (inches < 12) return "${inches.toStringAsFixed(1)} in";
    final int feet = inches ~/ 12;
    return "$feet′ ${(inches - feet * 12).round()}″";
  }
  if (metres < 1) return "${(metres * 100).toStringAsFixed(metres < 0.1 ? 1 : 0)} cm";
  if (metres < 10) return "${metres.toStringAsFixed(2)} m";
  return UArGeo.formatDistance(metres);
}

/// Handles availability, installation and permissions before an AR view runs,
/// and shows a friendly screen for each failure.
class UArGate extends StatefulWidget {
  const UArGate({
    required this.builder,
    this.needsCamera = true,
    this.needsLocation = false,
    this.fallback,
    this.labels = const UArLabels(),
    this.style = const UArStyle(),
    this.showCloseButton = true,
    super.key,
  });

  final Widget Function(BuildContext context, UArCapabilities capabilities) builder;
  final bool needsCamera;
  final bool needsLocation;

  /// Shows a close button over the error screens, which otherwise cover the page.
  final bool showCloseButton;

  /// Shown instead of the error card when AR is unavailable, e.g. a 3D viewer.
  final Widget Function(BuildContext context, UArAvailability availability)? fallback;
  final UArLabels labels;
  final UArStyle style;

  @override
  State<UArGate> createState() => _UArGateState();
}

class _UArGateState extends State<UArGate> {
  UArAvailability? _availability;
  bool _permissionDenied = false;
  bool _locationDenied = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final UArAvailability availability = await UAr.availability();
    bool denied = false;
    bool locationDenied = false;
    if (availability.isSupported && widget.needsCamera && !kIsWeb) {
      final UArPermissionState permission = await UAr.requestPermission(location: widget.needsLocation);
      denied = !permission.cameraGranted;
      locationDenied = widget.needsLocation && !permission.locationGranted;
    }
    if (!mounted) return;
    setState(() {
      _availability = availability;
      _permissionDenied = denied;
      _locationDenied = locationDenied;
      _checking = false;
    });
  }

  Future<void> _install() async {
    await UAr.requestInstall();
    await Future<void>.delayed(const Duration(seconds: 1));
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    final UArAvailability? availability = _availability;
    if (_checking || availability == null) return const Center(child: CircularProgressIndicator());
    if (availability.status == UArAvailabilityStatus.needsInstall) {
      return _message(widget.labels.installRequired ?? U.s.googlePlayServicesForArIsRequired, widget.labels.install ?? U.s.install, _install);
    }
    if (!availability.isSupported) {
      final Widget Function(BuildContext context, UArAvailability availability)? fallback = widget.fallback;
      if (fallback != null) return fallback(context, availability);
      return _message(widget.labels.unsupported ?? U.s.arIsNotSupportedOnThisDevice, null, null);
    }
    if (_permissionDenied) {
      return _message(widget.labels.permission ?? U.s.cameraPermissionIsRequired, widget.labels.openSettings ?? U.s.openSettings, () async {
        await UAr.openSettings();
      });
    }
    if (_locationDenied) {
      return _message(widget.labels.locationPermission ?? U.s.locationPermissionIsRequired, widget.labels.openSettings ?? U.s.openSettings, () async {
        await UAr.openSettings();
      });
    }
    return widget.builder(context, availability.capabilities);
  }

  // Drawn on a card so it reads on the black AR page in light and dark themes.
  Widget _message(String text, String? action, Future<void> Function()? onAction) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      Center(
        child: Padding(
          padding: widget.style.padding,
          child: DecoratedBox(
            decoration: BoxDecoration(color: widget.style.surface(context), borderRadius: BorderRadius.circular(widget.style.borderRadius)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: UArForeground(
                color: widget.style.onSurface(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.view_in_ar_outlined, size: 56, color: widget.style.accent(context)),
                    const SizedBox(height: 16),
                    UTextBodyLarge(text, textAlign: TextAlign.center, maxLines: 6),
                    if (action != null && onAction != null) ...<Widget>[
                      const SizedBox(height: 16),
                      UButton(
                        title: action,
                        backgroundColor: widget.style.accent(context),
                        foregroundColor: widget.style.onAccent(context),
                        onTap: () => unawaited(onAction()),
                      ),
                    ],
                    const SizedBox(height: 8),
                    UButton(title: U.s.retry, type: UButtonType.text, foregroundColor: widget.style.accent(context), onTap: () => unawaited(_check())),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      if (widget.showCloseButton)
        PositionedDirectional(
          top: MediaQuery.paddingOf(context).top + 12,
          start: 12,
          child: UArRoundButton(icon: Icons.close, tooltip: U.s.close, style: widget.style, onTap: () => Navigator.of(context).maybePop()),
        ),
    ],
  );
}

/// Pauses the session with the app and resumes it after.
mixin UArLifecycle<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  UArController? get lifecycleController;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final UArController? controller = lifecycleController;
    if (controller == null || controller.sessionId == null || controller.isDisposed) return;
    if (state == AppLifecycleState.paused) unawaited(controller.pause().catchError((Object _) {}));
    if (state == AppLifecycleState.resumed) unawaited(controller.resume().catchError((Object _) {}));
  }
}

/// On the web the immersive session must start from a tap; this shows the button.
class UArWebStartButton extends StatelessWidget {
  const UArWebStartButton({required this.controller, this.label, this.onFailed, this.style = const UArStyle(), super.key});

  final UArController controller;
  final String? label;
  final VoidCallback? onFailed;
  final UArStyle style;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UArValue>(
    valueListenable: controller,
    builder: (BuildContext context, UArValue value, Widget? _) {
      if (!kIsWeb || value.isXrActive || value.config.isViewer || value.state != UArSessionState.running) return const SizedBox.shrink();
      return Center(
        child: UButton(
          title: label ?? U.s.startAr,
          icon: const Icon(Icons.view_in_ar),
          backgroundColor: style.accent(context),
          foregroundColor: style.onAccent(context),
          borderRadius: 24,
          onTap: () async {
            final bool ok = await controller.enterXr();
            if (!ok) onFailed?.call();
          },
        ),
      );
    },
  );
}

// =============================================================================
// Placement scene (products, furniture, wall art, signage, …)
// =============================================================================

/// Something the user can put into the world.
class UArPlaceable {
  const UArPlaceable({
    required this.id,
    required this.title,
    this.source,
    this.iosSource,
    this.thumbnail,
    this.fitSize,
    this.surface = UArSurface.any,
    this.maxCount = 0,
    this.builder,
    this.data = const <String, Object?>{},
  });

  final String id;
  final String title;
  final UArSource? source;
  final UArSource? iosSource;
  final Widget? thumbnail;

  /// Largest side in metres; null keeps the model's true (real-world) size.
  final double? fitSize;
  final UArSurface surface;

  /// How many copies can be placed; 0 is unlimited.
  final int maxCount;

  /// Builds a custom node instead of loading [source] (primitives, groups, widget cards).
  final UArNode Function(String nodeId)? builder;
  final Map<String, Object?> data;

  UArNode build(String nodeId) =>
      builder?.call(nodeId) ??
      UArNode.model(id: nodeId, source: source ?? UArSource.url(""), iosSource: iosSource, fitSize: fitSize, pivot: surface == UArSurface.wall ? UArPivot.center : UArPivot.bottom, data: data);
}

class UArPlacedItem {
  const UArPlacedItem({required this.nodeId, required this.anchorId, required this.item, required this.hit, this.info});

  final String nodeId;
  final String anchorId;
  final UArPlaceable item;
  final UArHitResult hit;
  final UArNodeInfo? info;
}

class UArSceneOptions {
  const UArSceneOptions({
    this.placementMode = UArPlacementMode.tap,
    this.maxPlacements = 0,
    this.replaceWhenFull = true,
    this.selectOnPlace = true,
    this.enableDrag = true,
    this.enableRotate = true,
    this.enableScale = true,
    this.minScale = 0.2,
    this.maxScale = 5,
    this.showHints = true,
    this.showGestureHint = true,
    this.showItemPicker = true,
    this.showToolbar = true,
    this.enableSnapshot = true,
    this.enableRecording = true,
    this.enableReset = true,
    this.enableDelete = true,
    this.showCloseButton = true,
    this.shareSnapshots = true,
    this.haptics = true,
  });

  final UArPlacementMode placementMode;
  final int maxPlacements;

  /// When [maxPlacements] is reached, the oldest is moved instead of refusing.
  final bool replaceWhenFull;
  final bool selectOnPlace;
  final bool enableDrag;
  final bool enableRotate;
  final bool enableScale;
  final double minScale;
  final double maxScale;
  final bool showHints;
  final bool showGestureHint;
  final bool showItemPicker;
  final bool showToolbar;
  final bool enableSnapshot;
  final bool enableRecording;
  final bool enableReset;
  final bool enableDelete;
  final bool showCloseButton;

  /// Opens the share sheet after a snapshot or recording when no callback is given.
  final bool shareSnapshots;
  final bool haptics;
}

/// Full interactive AR: find surfaces, place items, move / rotate / scale them,
/// take photos and videos. Everything is configurable and every piece of
/// chrome can be replaced through the builders.
class UArScene extends StatefulWidget {
  const UArScene({
    this.items = const <UArPlaceable>[],
    this.initialItem = 0,
    this.controller,
    this.config = const UArConfig(reticle: true),
    this.options = const UArSceneOptions(),
    this.overlays = const <UArOverlay>[],
    this.labels = const UArLabels(),
    this.style = const UArStyle(),
    this.onCreated,
    this.onPlaced,
    this.onNodeTap,
    this.onSurfaceTap,
    this.onSnapshot,
    this.onRecorded,
    this.onError,
    this.onClose,
    this.hintBuilder,
    this.toolbarBuilder,
    this.pickerBuilder,
    this.overlayBuilder,
    this.placeholder,
    this.gate = true,
    super.key,
  });

  final List<UArPlaceable> items;
  final int initialItem;

  /// Supply one to drive the session yourself; otherwise one is created.
  final UArController? controller;
  final UArConfig config;
  final UArSceneOptions options;
  final List<UArOverlay> overlays;
  final UArLabels labels;
  final UArStyle style;
  final void Function(UArController controller)? onCreated;
  final void Function(UArPlacedItem placed)? onPlaced;
  final void Function(UArNodeHit hit, UArNode? node)? onNodeTap;

  /// Called for taps on surfaces when nothing is being placed.
  final void Function(UArHitResult hit)? onSurfaceTap;
  final void Function(Uint8List image)? onSnapshot;
  final void Function(UArRecording recording)? onRecorded;
  final void Function(UArException error)? onError;
  final VoidCallback? onClose;
  final Widget Function(BuildContext context, String hint)? hintBuilder;
  final Widget Function(BuildContext context, UArSceneState state)? toolbarBuilder;
  final Widget Function(BuildContext context, UArSceneState state)? pickerBuilder;

  /// Anything else drawn over the view, below the built-in chrome.
  final Widget Function(BuildContext context, UArController controller)? overlayBuilder;
  final Widget? placeholder;

  /// Checks availability and asks for the camera before starting.
  final bool gate;

  @override
  State<UArScene> createState() => UArSceneState();
}

class UArSceneState extends State<UArScene> with WidgetsBindingObserver, UArLifecycle<UArScene> {
  late final UArController controller = widget.controller ?? UArController(config: widget.config);
  final List<UArPlacedItem> placed = <UArPlacedItem>[];
  late int selectedItem = widget.initialItem.clamp(0, max(0, widget.items.length - 1));
  String? selectedNode;
  bool busy = false;
  bool _dragging = false;
  UArHitResult? _dragHit;
  final Map<String, UArVector3> _offsets = <String, UArVector3>{};
  bool _gestureHintShown = false;
  bool _showGestureHint = false;
  UArVector3 _startScale = UArVector3.one;
  UArQuaternion _startRotation = UArQuaternion.identity;
  StreamSubscription<UArException>? _errors;
  String? _errorText;
  Timer? _errorTimer;

  UArSceneOptions get _o => widget.options;

  @override
  UArController? get lifecycleController => controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _errors = controller.errors.listen(_reportError);
    unawaited(controller.ready.then((_) => widget.onCreated?.call(controller)).catchError((Object _) {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_errors?.cancel());
    _errorTimer?.cancel();
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  /// Hands errors to [UArScene.onError], or shows them in the hint area so a
  /// model that fails to load never just silently does nothing.
  void _reportError(UArException error) {
    if (widget.onError != null) {
      widget.onError!(error);
      return;
    }
    if (!mounted) return;
    _errorTimer?.cancel();
    setState(() => _errorText = error.message.isEmpty ? (widget.labels.loadFailed ?? U.s.failedToLoadTheModel) : error.message);
    _errorTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _errorText = null);
    });
  }

  UArPlaceable? get currentItem => widget.items.isEmpty ? null : widget.items[selectedItem];

  void selectItem(int index) => setState(() => selectedItem = index);

  bool _matches(UArHitResult hit, UArSurface surface) {
    final double? floor = controller.floorHeight;
    final bool raised = floor != null && hit.pose.position.y - floor > 0.35;
    return switch (surface) {
      UArSurface.any => true,
      UArSurface.horizontal => hit.planeType != UArPlaneType.vertical,
      UArSurface.vertical || UArSurface.wall => hit.isWall,
      UArSurface.floor => !hit.isWall && !hit.isCeiling && (hit.classification == UArPlaneClassification.floor || !raised && hit.classification == UArPlaneClassification.none),
      UArSurface.table => !hit.isWall && (hit.isTable || raised && hit.classification == UArPlaneClassification.none),
      UArSurface.ceiling => hit.isCeiling,
    };
  }

  /// The best hit for [surface]: an exact match (a floor for floor items), else
  /// any surface with the right orientation, so a tap on a table still places a
  /// floor item instead of silently doing nothing.
  UArHitResult? _pick(List<UArHitResult> hits, UArSurface surface) {
    final UArHitResult? exact = hits.where((UArHitResult h) => _matches(h, surface)).firstOrNull;
    if (exact != null) return exact;
    final UArSurface loose = switch (surface) {
      UArSurface.floor || UArSurface.table => UArSurface.horizontal,
      UArSurface.wall => UArSurface.vertical,
      _ => surface,
    };
    return loose == surface ? null : hits.where((UArHitResult h) => _matches(h, loose) && !h.isCeiling).firstOrNull;
  }

  /// World pose for content placed on [hit]: upright and facing the camera on
  /// floors and tables, flat against walls.
  UArPose placementPose(UArHitResult hit) {
    final UArVector3 position = hit.pose.position;
    if (hit.isWall) {
      UArVector3 normal = hit.pose.up;
      final UArVector3 toCamera = controller.value.frame.camera.position - position;
      if (normal.dot(toCamera) < 0) normal = -normal;
      final UArVector3 flat = UArVector3(normal.x, 0, normal.z).normalized;
      final UArVector3 right = UArVector3.up.cross(flat).normalized;
      return UArPose(position: position, rotation: UArQuaternion.fromBasis(right, UArVector3.up, flat));
    }
    final UArVector3 toCamera = controller.value.frame.camera.position - position;
    return UArPose(position: position, rotation: UArQuaternion.yaw(atan2(toCamera.x, toCamera.z)));
  }

  /// Places [item] (or the selected one) on [hit].
  Future<UArPlacedItem?> place(UArHitResult hit, {UArPlaceable? item}) async {
    final UArPlaceable? placeable = item ?? currentItem;
    if (placeable == null || busy) return null;
    if (_pick(<UArHitResult>[hit], placeable.surface) == null) return null;
    final int count = placed.where((UArPlacedItem p) => p.item.id == placeable.id).length;
    if (placeable.maxCount > 0 && count >= placeable.maxCount) {
      final UArPlacedItem existing = placed.firstWhere((UArPlacedItem p) => p.item.id == placeable.id);
      await controller.updateAnchor(existing.anchorId, placementPose(hit));
      return existing;
    }
    if (_o.maxPlacements > 0 && placed.length >= _o.maxPlacements) {
      if (!_o.replaceWhenFull) return null;
      await remove(placed.first.nodeId);
    }
    setState(() => busy = true);
    try {
      final UArAnchor anchor = await controller.addAnchor(placementPose(hit), trackableId: hit.trackableId);
      final String nodeId = controller.newId("item");
      final UArNode node = placeable.build(nodeId).copyWith(anchorId: anchor.id);
      final UArNodeInfo info = await controller.addNode(node);
      if (hit.isWall && node.type == UArNodeType.model) {
        final UArVector3 offset = UArVector3(0, 0, max(0.005, (info.size.x.abs() + info.size.z.abs()) / 4));
        _offsets[nodeId] = offset;
        await controller.transformNode(nodeId, position: offset);
      }
      final UArPlacedItem result = UArPlacedItem(nodeId: nodeId, anchorId: anchor.id, item: placeable, hit: hit, info: info);
      placed.add(result);
      if (_o.haptics) unawaited(HapticFeedback.lightImpact());
      if (_o.selectOnPlace) selectedNode = nodeId;
      if (_o.showGestureHint && !_gestureHintShown) {
        _gestureHintShown = true;
        _showGestureHint = true;
        Future<void>.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showGestureHint = false);
        });
      }
      widget.onPlaced?.call(result);
      return result;
    } on UArException catch (error) {
      _reportError(error);
      return null;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove(String nodeId) async {
    final UArPlacedItem? item = placed.where((UArPlacedItem p) => p.nodeId == nodeId).firstOrNull;
    placed.removeWhere((UArPlacedItem p) => p.nodeId == nodeId);
    if (selectedNode == nodeId) selectedNode = null;
    if (item != null) {
      await controller.removeAnchor(item.anchorId);
    } else {
      await controller.removeNode(nodeId);
    }
    if (mounted) setState(() {});
  }

  Future<void> reset() async {
    placed.clear();
    selectedNode = null;
    await controller.reset();
    if (mounted) setState(() {});
  }

  Future<void> snapshot() async {
    final Uint8List? image = await controller.takeSnapshot();
    if (image == null) return;
    if (_o.haptics) unawaited(HapticFeedback.mediumImpact());
    if (widget.onSnapshot != null) {
      widget.onSnapshot!(image);
    } else if (_o.shareSnapshots) {
      await UShare.bytes(bytes: image, fileName: "ar_${DateTime.now().millisecondsSinceEpoch}.jpg", mimeType: "image/jpeg");
    }
  }

  Future<void> toggleRecording() async {
    if (controller.value.isRecording) {
      final UArRecording? recording = await controller.stopRecording();
      if (recording == null) return;
      if (widget.onRecorded != null) {
        widget.onRecorded!(recording);
      } else if (_o.shareSnapshots) {
        final String? path = recording.path;
        final Uint8List? bytes = recording.bytes;
        if (path != null) {
          await UShare.file(path: path);
        } else if (bytes != null) {
          await UShare.bytes(bytes: bytes, fileName: "ar_${DateTime.now().millisecondsSinceEpoch}.webm", mimeType: recording.mimeType);
        }
      }
    } else {
      await controller.startRecording(audio: !kIsWeb);
    }
  }

  // ---------------------------------------------------------------------------
  // Gestures
  // ---------------------------------------------------------------------------

  Future<void> _onTap(Offset point) async {
    if (busy) return;
    try {
      final UArNodeHit? nodeHit = await controller.hitTestNodes(point);
      final String? nodeId = nodeHit == null ? null : _rootOf(nodeHit.nodeId);
      if (nodeHit != null && nodeId != null) {
        setState(() => selectedNode = nodeId);
        widget.onNodeTap?.call(nodeHit, controller.value.nodes[nodeId]);
        return;
      }
      UArHitResult? hit;
      if (_o.placementMode == UArPlacementMode.reticle) {
        hit = controller.value.frame.centerHit;
      } else {
        final List<UArHitResult> hits = await controller.hitTest(point);
        final UArSurface surface = currentItem?.surface ?? UArSurface.any;
        hit = _pick(hits, surface);
      }
      if (hit == null) return;
      if (currentItem == null) {
        setState(() => selectedNode = null);
        widget.onSurfaceTap?.call(hit);
        return;
      }
      await place(hit);
    } on UArException catch (error) {
      _reportError(error);
    }
  }

  String? _rootOf(String nodeId) {
    String current = nodeId;
    for (int i = 0; i < 16; i++) {
      final String? parent = controller.value.nodes[current]?.parentId;
      if (parent == null) break;
      current = parent;
    }
    return placed.any((UArPlacedItem p) => p.nodeId == current) ? current : (controller.value.nodes.containsKey(current) ? current : null);
  }

  void _onScaleStart(ScaleStartDetails details) {
    final String? id = selectedNode;
    if (id == null) return;
    final UArNode? node = controller.value.nodes[id];
    _startScale = node?.scale ?? UArVector3.one;
    _startRotation = node?.rotation ?? UArQuaternion.identity;
    _dragging = details.pointerCount == 1;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final String? id = selectedNode;
    if (id == null || busy) return;
    busy = true;
    try {
      if (details.pointerCount == 1 && _dragging && _o.enableDrag) {
        final UArPlacedItem? item = placed.where((UArPlacedItem p) => p.nodeId == id).firstOrNull;
        final List<UArHitResult> hits = await controller.hitTest(details.localFocalPoint, types: const <UArHitType>[UArHitType.plane, UArHitType.depth, UArHitType.estimated]);
        final UArHitResult? hit = _pick(hits, item?.item.surface ?? UArSurface.any);
        if (hit != null && item != null) {
          _dragHit = hit;
          final UArPose pose = placementPose(hit);
          await controller.transformNode(
            id,
            position: pose.transformPoint(_offsets[id] ?? UArVector3.zero),
            rotation: hit.isWall ? pose.rotation.multiply(controller.value.nodes[id]?.rotation ?? UArQuaternion.identity) : null,
            world: true,
          );
        }
      } else if (details.pointerCount >= 2) {
        _dragging = false;
        final double factor = details.scale.clamp(0.05, 20).toDouble();
        await controller.transformNode(
          id,
          scale: _o.enableScale ? UArVector3.all((_startScale.x * factor).clamp(_o.minScale, _o.maxScale)) : null,
          rotation: _o.enableRotate ? _startRotation.multiply(UArQuaternion.yaw(-details.rotation)) : null,
        );
      }
    } catch (_) {
    } finally {
      busy = false;
    }
  }

  Future<void> _onScaleEnd() async {
    final String? id = selectedNode;
    final UArHitResult? hit = _dragHit;
    _dragHit = null;
    if (id == null || hit == null) return;
    final UArPlacedItem? item = placed.where((UArPlacedItem p) => p.nodeId == id).firstOrNull;
    if (item == null) return;
    try {
      final UArPose pose = placementPose(hit);
      final UArPose? current = await controller.nodePose(id);
      await controller.updateAnchor(item.anchorId, hit.isWall ? pose : pose.withRotation(controller.value.anchors[item.anchorId]?.pose.rotation ?? pose.rotation));
      final UArAnchor? anchor = controller.value.anchors[item.anchorId];
      final UArQuaternion? rotation = current == null || anchor == null ? null : anchor.pose.rotation.conjugate.multiply(current.rotation);
      await controller.transformNode(id, position: _offsets[id] ?? UArVector3.zero, rotation: rotation);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!widget.gate) return _scene(context);
    return UArGate(labels: widget.labels, style: widget.style, builder: (BuildContext context, UArCapabilities _) => _scene(context));
  }

  Widget _scene(BuildContext context) => ColoredBox(
    color: const Color(0xFF000000),
    child: UArView(
      controller: controller,
      placeholder: widget.placeholder ?? const Center(child: CircularProgressIndicator()),
      child: ValueListenableBuilder<UArValue>(
        valueListenable: controller,
        builder: (BuildContext context, UArValue value, Widget? _) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (TapUpDetails details) => unawaited(_onTap(details.localPosition)),
                onScaleStart: _onScaleStart,
                onScaleUpdate: (ScaleUpdateDetails details) => unawaited(_onScaleUpdate(details)),
                onScaleEnd: (ScaleEndDetails _) => unawaited(_onScaleEnd()),
              ),
            ),
            UArOverlayLayer(controller: controller, overlays: widget.overlays),
            ?widget.overlayBuilder?.call(context, controller),
            if (_o.showHints) _hints(context, value),
            if (_o.showCloseButton)
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + 12,
                start: 12,
                child: UArRoundButton(icon: Icons.close, tooltip: U.s.close, style: widget.style, onTap: widget.onClose ?? () => Navigator.of(context).maybePop()),
              ),
            if (value.isRecording)
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + 18,
                end: 16,
                child: UArPill(
                  style: widget.style,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.fiber_manual_record, size: 12, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 6),
                      UTextLabelMedium(widget.labels.recording ?? U.s.recording),
                    ],
                  ),
                ),
              ),
            UArWebStartButton(controller: controller, style: widget.style, label: widget.labels.startAr, onFailed: _nativeFallback),
            Positioned(left: 0, right: 0, bottom: 0, child: _bottom(context, value)),
          ],
        ),
      ),
    ),
  );

  Future<void> _nativeFallback() async {
    final UArPlaceable? item = currentItem;
    final UArSource? source = item?.source;
    if (source == null) return;
    await UAr.openNativeViewer(UArNativeViewerOptions(source: source, iosSource: item?.iosSource, title: item?.title));
  }

  Widget _hints(BuildContext context, UArValue value) {
    String? hint = _errorText ?? uArTrackingHint(value, widget.labels, needsSurface: widget.items.isNotEmpty);
    if (hint == null && widget.items.isNotEmpty && placed.isEmpty && value.isTracking) hint = widget.labels.tapToPlace ?? U.s.tapToPlace;
    if (hint == null && _showGestureHint) hint = widget.labels.gestures ?? U.s.dragToMovePinchToScaleTwistToRotate;
    if (kIsWeb && !value.isXrActive) hint = null;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 72,
      left: 24,
      right: 24,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: hint == null
            ? const SizedBox.shrink()
            : Center(
                key: ValueKey<String>(hint),
                child:
                    widget.hintBuilder?.call(context, hint) ??
                    UArPill(
                      style: widget.style,
                      child: UTextBodyMedium(hint, textAlign: TextAlign.center),
                    ),
              ),
      ),
    );
  }

  Widget _bottom(BuildContext context, UArValue value) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_o.showItemPicker && widget.items.length > 1) widget.pickerBuilder?.call(context, this) ?? _picker(context),
          if (_o.showToolbar) widget.toolbarBuilder?.call(context, this) ?? _toolbar(context, value),
        ],
      ),
    ),
  );

  Widget _picker(BuildContext context) => SizedBox(
    height: 92,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.items.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 10),
      itemBuilder: (BuildContext context, int index) {
        final UArPlaceable item = widget.items[index];
        final bool active = index == selectedItem;
        return GestureDetector(
          onTap: () => selectItem(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 76,
            decoration: BoxDecoration(
              color: widget.style.surface(context),
              borderRadius: BorderRadius.circular(widget.style.borderRadius),
              border: Border.all(color: active ? widget.style.accent(context) : const Color(0x00000000), width: 2),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              children: <Widget>[
                Expanded(child: item.thumbnail ?? Icon(Icons.view_in_ar, color: widget.style.onSurface(context))),
                UTextLabelSmall(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _toolbar(BuildContext context, UArValue value) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        if (_o.enableReset) UArRoundButton(icon: Icons.refresh, tooltip: U.s.reset, style: widget.style, onTap: () => unawaited(reset())),
        if (_o.enableDelete && selectedNode != null) UArRoundButton(icon: Icons.delete_outline, tooltip: U.s.delete, style: widget.style, onTap: () => unawaited(remove(selectedNode!))),
        if (_o.enableSnapshot && value.capabilities.snapshot)
          UArRoundButton(icon: Icons.camera_alt_outlined, size: 64, tooltip: U.s.takePhoto, style: widget.style, active: true, onTap: () => unawaited(snapshot())),
        if (_o.enableRecording && value.capabilities.recording)
          UArRoundButton(
            icon: value.isRecording ? Icons.stop : Icons.videocam_outlined,
            tooltip: value.isRecording ? U.s.stop : U.s.record,
            style: widget.style,
            active: value.isRecording,
            onTap: () => unawaited(toggleRecording()),
          ),
      ],
    ),
  );
}

// =============================================================================
// 3D product viewer
// =============================================================================

/// A point of interest on a model, placed in fractions of its bounding box:
/// (0, 0.5, 0) is the top centre, (-0.5, 0, 0.5) the middle of the front-left edge.
class UArHotspot {
  const UArHotspot({required this.id, required this.position, required this.builder, this.onTap});

  final String id;
  final UArVector3 position;
  final Widget Function(BuildContext context, UArProjection projection) builder;
  final VoidCallback? onTap;
}

class U3DViewer extends StatefulWidget {
  const U3DViewer({
    required this.source,
    this.iosSource,
    this.title,
    this.controller,
    this.background,
    this.transparent = false,
    this.autoRotate = true,
    this.autoRotateSpeed = 14,
    this.autoRotateDelay = const Duration(seconds: 3),
    this.enableRotate = true,
    this.enableZoom = true,
    this.enablePan = false,
    this.minZoom = 0.5,
    this.maxZoom = 3,
    this.minPitch = -15,
    this.maxPitch = 80,
    this.initialYaw = 25,
    this.initialPitch = 12,
    this.fov = 32,
    this.exposure = 1,
    this.environmentIntensity = 1,
    this.shadows = true,
    this.shadowOpacity = 0.35,
    this.animation = const UArAnimation(),
    this.hotspots = const <UArHotspot>[],
    this.showArButton = true,
    this.arSurface = UArSurface.floor,
    this.arButtonBuilder,
    this.onArPressed,
    this.onLoaded,
    this.onTap,
    this.placeholder,
    this.errorBuilder,
    this.labels = const UArLabels(),
    this.style = const UArStyle(),
    super.key,
  });

  final UArSource source;
  final UArSource? iosSource;
  final String? title;
  final UArController? controller;
  final Color? background;
  final bool transparent;
  final bool autoRotate;

  /// Degrees per second.
  final double autoRotateSpeed;
  final Duration autoRotateDelay;
  final bool enableRotate;
  final bool enableZoom;
  final bool enablePan;
  final double minZoom;
  final double maxZoom;
  final double minPitch;
  final double maxPitch;
  final double initialYaw;
  final double initialPitch;
  final double fov;
  final double exposure;
  final double environmentIntensity;
  final bool shadows;
  final double shadowOpacity;
  final UArAnimation? animation;
  final List<UArHotspot> hotspots;
  final bool showArButton;

  /// Where the model goes when opened in AR.
  final UArSurface arSurface;
  final Widget Function(BuildContext context, VoidCallback open)? arButtonBuilder;

  /// Replaces the default "View in AR" behaviour.
  final VoidCallback? onArPressed;
  final void Function(UArNodeInfo info)? onLoaded;
  final void Function(UArNodeHit? hit)? onTap;
  final Widget? placeholder;
  final Widget Function(BuildContext context, UArException error)? errorBuilder;
  final UArLabels labels;
  final UArStyle style;

  @override
  State<U3DViewer> createState() => U3DViewerState();
}

class U3DViewerState extends State<U3DViewer> with SingleTickerProviderStateMixin {
  static const String nodeId = "model";
  UArController? _controller;
  late final Ticker _ticker = createTicker(_tick);
  UArNodeInfo? info;
  UArException? error;
  late UArOrbit _orbit = UArOrbit(yaw: widget.initialYaw, pitch: widget.initialPitch, fov: widget.fov);
  UArOrbit _home = const UArOrbit();
  double _baseDistance = 1.5;
  double _startDistance = 1.5;
  DateTime _lastInteraction = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _lastTick = Duration.zero;
  UArOrbit? _animateFrom;
  double _animateT = 1;
  bool _pushing = false;
  UArOrbit? _pending;

  UArController get controller => _controller!;

  UArConfig get _config => UArConfig.viewer(
    background: widget.background ?? Theme.of(context).colorScheme.surfaceContainerHighest,
    transparentBackground: widget.transparent,
    shadows: widget.shadows,
    shadowOpacity: widget.shadowOpacity,
    exposure: widget.exposure,
    environmentIntensity: widget.environmentIntensity,
    orbit: _orbit,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    _controller = widget.controller ?? UArController(config: _config);
    unawaited(_load());
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (widget.controller == null) _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await controller.ready;
      final UArNodeInfo loaded = await controller.addNode(
        UArNode.model(id: nodeId, source: widget.source, iosSource: widget.iosSource, pivot: UArPivot.center, animation: widget.animation, castShadow: widget.shadows),
      );
      final double radius = max(loaded.radius, 0.01);
      _baseDistance = radius / sin(widget.fov * pi / 360) * 1.1;
      _home = UArOrbit(yaw: widget.initialYaw, pitch: widget.initialPitch, distance: _baseDistance, target: loaded.center, fov: widget.fov);
      _orbit = _home;
      await _push();
      if (!mounted) return;
      setState(() => info = loaded);
      widget.onLoaded?.call(loaded);
    } on UArException catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> _push() async {
    _pending = _orbit;
    if (_pushing || controller.sessionId == null) return;
    _pushing = true;
    try {
      while (_pending != null) {
        final UArOrbit next = _pending!;
        _pending = null;
        await controller.setOrbit(next);
      }
    } catch (_) {
    } finally {
      _pushing = false;
    }
  }

  void _tick(Duration elapsed) {
    final double dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (info == null) return;
    bool changed = false;
    if (_animateT < 1 && _animateFrom != null) {
      _animateT = min(1, _animateT + dt * 2.5);
      final double t = Curves.easeOutCubic.transform(_animateT);
      _orbit = _animateFrom!.lerp(_home, t);
      changed = true;
    } else if (widget.autoRotate && DateTime.now().difference(_lastInteraction) > widget.autoRotateDelay) {
      _orbit = _orbit.copyWith(yaw: _orbit.yaw + widget.autoRotateSpeed * dt);
      changed = true;
    }
    if (changed) unawaited(_push());
  }

  /// Animates the camera back to where it started.
  void resetView() {
    _animateFrom = _orbit;
    _animateT = 0;
    _lastInteraction = DateTime.now();
  }

  Future<void> openInAr() async {
    if (widget.onArPressed != null) {
      widget.onArPressed!();
      return;
    }
    final UArAvailability availability = await UAr.availability();
    final bool native = !availability.isSupported || kIsWeb && !availability.capabilities.webXr;
    if (native) {
      await UAr.openNativeViewer(UArNativeViewerOptions(source: widget.source, iosSource: widget.iosSource, title: widget.title));
      return;
    }
    await UArExperiences.place(
      items: <UArPlaceable>[UArPlaceable(id: "product", title: widget.title ?? "", source: widget.source, iosSource: widget.iosSource, surface: widget.arSurface, maxCount: 1)],
      labels: widget.labels,
      style: widget.style,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startDistance = _orbit.distance;
    _animateT = 1;
    _lastInteraction = DateTime.now();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _lastInteraction = DateTime.now();
    UArOrbit next = _orbit;
    if (details.pointerCount == 1 && widget.enableRotate) {
      next = next.copyWith(yaw: next.yaw - details.focalPointDelta.dx * 0.45, pitch: (next.pitch + details.focalPointDelta.dy * 0.35).clamp(widget.minPitch, widget.maxPitch));
    } else if (details.pointerCount >= 2) {
      if (widget.enableZoom) next = next.copyWith(distance: (_startDistance / details.scale).clamp(_baseDistance * widget.minZoom, _baseDistance * widget.maxZoom));
      if (widget.enablePan) {
        final double yaw = next.yaw * pi / 180;
        final double k = next.distance * 0.0015;
        final UArVector3 right = UArVector3(cos(yaw), 0, -sin(yaw));
        next = next.copyWith(target: next.target - right * (details.focalPointDelta.dx * k) + UArVector3.up * (details.focalPointDelta.dy * k));
      }
    }
    _orbit = next;
    unawaited(_push());
  }

  Future<void> _onTap(TapUpDetails details) async {
    if (widget.onTap == null) return;
    try {
      widget.onTap!(await controller.hitTestNodes(details.localPosition));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final UArException? failure = error;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        UArView(controller: controller),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onDoubleTap: resetView,
            onTapUp: (TapUpDetails details) => unawaited(_onTap(details)),
          ),
        ),
        if (info != null)
          UArOverlayLayer(
            controller: controller,
            overlays: <UArOverlay>[
              for (final UArHotspot hotspot in widget.hotspots)
                UArOverlay(
                  id: hotspot.id,
                  builder: hotspot.builder,
                  offset: info!.center + info!.size.multiply(hotspot.position),
                  alignment: Alignment.center,
                  scaleWithDistance: false,
                  onTap: hotspot.onTap,
                ),
            ],
          ),
        if (info == null && failure == null)
          widget.placeholder ??
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    UTextBodyMedium(widget.labels.loadingModel ?? U.s.loadingModel),
                  ],
                ),
              ),
        if (failure != null) widget.errorBuilder?.call(context, failure) ?? Center(child: UTextBodyMedium(widget.labels.loadFailed ?? U.s.failedToLoadTheModel)),
        if (widget.showArButton && info != null)
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child:
                widget.arButtonBuilder?.call(context, () => unawaited(openInAr())) ??
                UButton(
                  title: widget.labels.viewInAr ?? U.s.viewInAr,
                  icon: const Icon(Icons.view_in_ar),
                  borderRadius: 24,
                  backgroundColor: widget.style.accent(context),
                  foregroundColor: widget.style.onAccent(context),
                  onTap: () => unawaited(openInAr()),
                ),
          ),
      ],
    );
  }
}

// =============================================================================
// Location-based cards (shops, landmarks, events, …)
// =============================================================================

class UArPlace {
  const UArPlace({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.icon,
    this.heightAboveGround = 2,
    this.model,
    this.modelSize = 1.5,
    this.data = const <String, Object?>{},
  });

  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final IconData? icon;

  /// Where the card floats, in metres above the ground.
  final double heightAboveGround;

  /// Optional 3D pin or sign drawn at the place.
  final UArSource? model;
  final double modelSize;
  final Map<String, Object?> data;
}

class UArGeoView extends StatefulWidget {
  const UArGeoView({
    required this.places,
    this.config = const UArConfig(mode: UArMode.geo, planeDetection: UArPlaneDetection.horizontal, planeStyle: UArPlaneStyle.hidden, coachingGoal: UArCoachingGoal.tracking),
    this.maxDistance = 800,
    this.maxVisible = 20,
    this.cardBuilder,
    this.edgeIndicatorBuilder,
    this.showEdgeIndicators = true,
    this.showCompass = true,
    this.stackCards = true,
    this.cardSize = const Size(230, 86),
    this.refreshInterval = const Duration(seconds: 20),
    this.onPlaceTap,
    this.labels = const UArLabels(),
    this.style = const UArStyle(),
    this.showCloseButton = true,
    super.key,
  });

  final List<UArPlace> places;
  final UArConfig config;

  /// Places farther than this many metres are skipped.
  final double maxDistance;
  final int maxVisible;
  final Widget Function(BuildContext context, UArPlace place, double distance, UArProjection projection)? cardBuilder;
  final Widget Function(BuildContext context, UArPlace place, double distance, bool left)? edgeIndicatorBuilder;
  final bool showEdgeIndicators;
  final bool showCompass;

  /// Pushes overlapping cards apart vertically.
  final bool stackCards;

  /// Layout size of one card, used for stacking.
  final Size cardSize;

  /// How often GPS anchors are re-placed from the latest fix.
  final Duration refreshInterval;
  final void Function(UArPlace place)? onPlaceTap;
  final UArLabels labels;
  final UArStyle style;
  final bool showCloseButton;

  @override
  State<UArGeoView> createState() => UArGeoViewState();
}

class UArGeoViewState extends State<UArGeoView> with WidgetsBindingObserver, UArLifecycle<UArGeoView> {
  late final UArController controller = UArController(config: widget.config);
  final Map<String, String> _anchors = <String, String>{};
  Timer? _refresh;
  bool _placing = false;

  @override
  UArController? get lifecycleController => controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void didUpdateWidget(covariant UArGeoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places) unawaited(_placeAll());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await controller.ready;
      await controller.startLocationUpdates();
    } catch (_) {
      if (controller.sessionId == null) return;
    }
    await _placeAll();
    _refresh = Timer.periodic(widget.refreshInterval, (Timer _) => unawaited(_refreshAnchors()));
  }

  Future<void> _refreshAnchors() async {
    await controller.refreshGeoAnchors();
    await _placeAll();
  }

  double _distanceTo(UArPlace place) {
    final Position? here = controller.lastPosition;
    final UArGeoPose? vps = controller.value.geo;
    if (vps != null && vps.source != "gps" && vps.isTracking) return UArGeo.distance(vps.latitude, vps.longitude, place.latitude, place.longitude);
    if (here == null) return double.infinity;
    return UArGeo.distance(here.latitude, here.longitude, place.latitude, place.longitude);
  }

  Future<void> _placeAll() async {
    if (_placing || controller.sessionId == null) return;
    _placing = true;
    try {
      final List<UArPlace> near = widget.places.where((UArPlace p) => _distanceTo(p) <= widget.maxDistance).toList()..sort((UArPlace a, UArPlace b) => _distanceTo(a).compareTo(_distanceTo(b)));
      final Set<String> wanted = near.take(widget.maxVisible).map((UArPlace p) => p.id).toSet();
      for (final String id in _anchors.keys.where((String id) => !wanted.contains(id)).toList()) {
        await controller.removeAnchor(_anchors.remove(id)!);
        await controller.untrack(id);
      }
      for (final UArPlace place in near.take(widget.maxVisible)) {
        if (_anchors.containsKey(place.id)) continue;
        final UArAnchor anchor = await controller.addGeoAnchor(latitude: place.latitude, longitude: place.longitude, altitude: place.heightAboveGround, id: "geo_${place.id}");
        _anchors[place.id] = anchor.id;
        await controller.track(place.id, anchorId: anchor.id);
        final UArSource? model = place.model;
        if (model != null) {
          await controller.addNode(
            UArNode.model(id: "geo_model_${place.id}", source: model, anchorId: anchor.id, fitSize: place.modelSize, billboard: UArBillboard.yAxis, position: UArVector3(0, -place.modelSize, 0)),
          );
        }
      }
    } catch (_) {
    } finally {
      _placing = false;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => UArGate(
    needsLocation: true,
    labels: widget.labels,
    style: widget.style,
    builder: (BuildContext context, UArCapabilities capabilities) => ColoredBox(
      color: const Color(0xFF000000),
      child: UArView(
        controller: controller,
        placeholder: const Center(child: CircularProgressIndicator()),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => ValueListenableBuilder<Map<String, UArProjection>>(
            valueListenable: controller.projections,
            builder: (BuildContext context, Map<String, UArProjection> projections, Widget? _) => Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ..._cards(context, constraints.biggest, projections),
                _status(context),
                if (widget.showCompass) _compass(context),
                if (widget.showCloseButton)
                  PositionedDirectional(
                    top: MediaQuery.paddingOf(context).top + 12,
                    start: 12,
                    child: UArRoundButton(icon: Icons.close, tooltip: U.s.close, style: widget.style, onTap: () => Navigator.of(context).maybePop()),
                  ),
                UArWebStartButton(controller: controller, style: widget.style, label: widget.labels.startAr),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _cards(BuildContext context, Size size, Map<String, UArProjection> projections) {
    final List<(UArPlace, UArProjection, double)> onScreen = <(UArPlace, UArProjection, double)>[];
    final List<(UArPlace, double, bool)> offScreen = <(UArPlace, double, bool)>[];
    final double? heading = controller.value.frame.heading;
    final Position? here = controller.lastPosition;
    for (final UArPlace place in widget.places) {
      final UArProjection? projection = projections[place.id];
      if (projection == null) continue;
      final double distance = _distanceTo(place).isFinite ? _distanceTo(place) : projection.distance;
      if (projection.isVisible) {
        onScreen.add((place, projection, distance));
      } else if (widget.showEdgeIndicators) {
        bool left = projection.x < 0.5;
        if (heading != null && here != null) {
          final double relative = (UArGeo.bearing(here.latitude, here.longitude, place.latitude, place.longitude) - heading + 540) % 360 - 180;
          left = relative < 0;
        }
        offScreen.add((place, distance, left));
      }
    }
    onScreen.sort(((UArPlace, UArProjection, double) a, (UArPlace, UArProjection, double) b) => a.$3.compareTo(b.$3));
    final List<Rect> taken = <Rect>[];
    final List<Widget> cards = <Widget>[];
    for (final (UArPlace, UArProjection, double) entry in onScreen) {
      final double scale = (40 / max(entry.$3, 1)).clamp(0.6, 1.0);
      final Size cardSize = widget.cardSize * scale;
      final Offset point = entry.$2.toOffset(size);
      Rect rect = Rect.fromLTWH(point.dx - cardSize.width / 2, point.dy - cardSize.height, cardSize.width, cardSize.height);
      if (widget.stackCards) {
        for (int i = 0; i < 12 && taken.any((Rect r) => r.overlaps(rect)); i++) {
          rect = rect.shift(Offset(0, -cardSize.height - 6));
        }
      }
      taken.add(rect);
      cards.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: GestureDetector(
            onTap: widget.onPlaceTap == null ? null : () => widget.onPlaceTap!(entry.$1),
            child: FittedBox(
              child: SizedBox(
                width: widget.cardSize.width,
                height: widget.cardSize.height,
                child: widget.cardBuilder?.call(context, entry.$1, entry.$3, entry.$2) ?? _defaultCard(context, entry.$1, entry.$3),
              ),
            ),
          ),
        ),
      );
    }
    final List<Widget> reversed = cards.reversed.toList();
    int leftIndex = 0;
    int rightIndex = 0;
    for (final (UArPlace, double, bool) entry in offScreen.take(8)) {
      final int index = entry.$3 ? leftIndex++ : rightIndex++;
      reversed.add(
        Positioned(
          left: entry.$3 ? 8 : null,
          right: entry.$3 ? null : 8,
          top: size.height * 0.35 + index * 52,
          child:
              widget.edgeIndicatorBuilder?.call(context, entry.$1, entry.$2, entry.$3) ??
              UArPill(
                style: widget.style,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (entry.$3) const Icon(Icons.chevron_left, size: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: UTextLabelMedium(entry.$1.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    UTextLabelSmall(UArGeo.formatDistance(entry.$2)),
                    if (!entry.$3) const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
        ),
      );
    }
    return reversed;
  }

  Widget _defaultCard(BuildContext context, UArPlace place, double distance) => DecoratedBox(
    decoration: BoxDecoration(
      color: widget.style.surface(context),
      borderRadius: BorderRadius.circular(widget.style.borderRadius),
      boxShadow: <BoxShadow>[BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: <Widget>[
          if (place.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(widget.style.borderRadius - 4),
              child: UImage(place.imageUrl!, width: 64, height: 64, fit: BoxFit.cover),
            )
          else
            CircleAvatar(
              radius: 28,
              backgroundColor: widget.style.accent(context),
              child: Icon(place.icon ?? Icons.storefront, color: widget.style.onAccent(context)),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                UTextTitleSmall(place.title, maxLines: 1, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.bold),
                if (place.subtitle != null) UTextBodySmall(place.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
                UTextLabelSmall(UArGeo.formatDistance(distance), color: widget.style.accent(context)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _status(BuildContext context) {
    final UArValue value = controller.value;
    String? hint = uArTrackingHint(value, widget.labels, needsSurface: false);
    final double? accuracy = value.frame.headingAccuracy;
    if (hint == null && controller.lastPosition == null && (value.geo == null || !value.geo!.isTracking)) hint = widget.labels.waitingForLocation ?? U.s.waitingForLocation;
    if (hint == null && accuracy != null && accuracy > 30) hint = widget.labels.calibrateCompass ?? U.s.calibrateYourCompassByMovingYourPhoneInAFigureEight;
    if (hint == null && controller.lastPosition != null && _anchors.isEmpty && widget.places.isNotEmpty && !_placing) hint = widget.labels.noPlaces ?? U.s.noPlacesNearby;
    if (kIsWeb && !value.isXrActive) hint = null;
    if (hint == null) return const SizedBox.shrink();
    return Positioned(
      bottom: MediaQuery.paddingOf(context).bottom + 24,
      left: 24,
      right: 24,
      child: Center(
        child: UArPill(
          style: widget.style,
          child: UTextBodyMedium(hint, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _compass(BuildContext context) {
    final double? heading = controller.value.frame.heading;
    if (heading == null) return const SizedBox.shrink();
    return PositionedDirectional(
      top: MediaQuery.paddingOf(context).top + 12,
      end: 12,
      child: UArPill(
        style: widget.style,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Transform.rotate(angle: -heading * pi / 180, child: const Icon(Icons.navigation, size: 26)),
            UTextLabelSmall("${heading.round()}°"),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Measuring tape
// =============================================================================

class UArMeasure extends StatefulWidget {
  const UArMeasure({
    this.unit = UArMeasureUnit.metric,
    this.closeShape = false,
    this.lineColor,
    this.pointColor,
    this.onChanged,
    this.labels = const UArLabels(),
    this.style = const UArStyle(),
    this.showCloseButton = true,
    super.key,
  });

  final UArMeasureUnit unit;

  /// Also measures the closing edge and the enclosed floor area.
  final bool closeShape;
  final Color? lineColor;
  final Color? pointColor;
  final void Function(List<UArVector3> points, double total, double area)? onChanged;
  final UArLabels labels;
  final UArStyle style;
  final bool showCloseButton;

  @override
  State<UArMeasure> createState() => UArMeasureState();
}

class UArMeasureState extends State<UArMeasure> with WidgetsBindingObserver, UArLifecycle<UArMeasure> {
  late final UArController controller = UArController(
    config: const UArConfig(reticle: true, planeStyle: UArPlaneStyle.dots, planeColor: Color(0x55FFFFFF)),
  );
  final List<UArVector3> points = <UArVector3>[];
  StreamSubscription<UArFrame>? _frames;
  bool _previewReady = false;
  bool _busy = false;

  @override
  UArController? get lifecycleController => controller;

  Color get _line => widget.lineColor ?? widget.style.accent(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _frames = controller.frames.listen(_onFrame);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_frames?.cancel());
    controller.dispose();
    super.dispose();
  }

  double get total {
    double sum = 0;
    for (int i = 1; i < points.length; i++) {
      sum += points[i - 1].distanceTo(points[i]);
    }
    if (widget.closeShape && points.length > 2) sum += points.last.distanceTo(points.first);
    return sum;
  }

  double get area {
    if (points.length < 3) return 0;
    double sum = 0;
    for (int i = 0; i < points.length; i++) {
      final UArVector3 a = points[i];
      final UArVector3 b = points[(i + 1) % points.length];
      sum += a.x * b.z - b.x * a.z;
    }
    return sum.abs() / 2;
  }

  Future<void> _onFrame(UArFrame frame) async {
    if (points.isEmpty || _busy) return;
    final UArHitResult? hit = frame.centerHit;
    if (hit == null) return;
    _busy = true;
    try {
      final UArVector3 from = points.last;
      final UArVector3 to = hit.pose.position;
      final UArNode line = UArNode.line(id: "preview", from: from, to: to, color: _line.withValues(alpha: 0.6), renderOnTop: true);
      if (!_previewReady) {
        await controller.addNode(UArNode.line(id: "preview", from: from, to: from + const UArVector3(0, 0, 0.001), color: _line.withValues(alpha: 0.6)).copyWith(depth: 1));
        _previewReady = true;
      }
      await controller.transformNode("preview", position: line.position, rotation: line.rotation, scale: UArVector3(1, 1, max(line.depth, 0.001)));
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  Future<void> addPoint() async {
    final Color pointColor = widget.pointColor ?? Theme.of(context).colorScheme.onPrimary;
    final UArHitResult? hit = controller.value.frame.centerHit ?? (await controller.hitTestCenter()).firstOrNull;
    if (hit == null) return;
    final UArVector3 point = hit.pose.position;
    final int index = points.length;
    points.add(point);
    unawaited(HapticFeedback.selectionClick());
    await controller.addNode(
      UArNode.sphere(
        id: "p$index",
        radius: 0.006,
        position: point,
        material: UArMaterial(color: pointColor, unlit: true),
      ),
    );
    if (index > 0) await _segment(index - 1, index);
    await _updateClosing();
    _notify();
  }

  Future<void> _segment(int a, int b) async {
    await controller.addLine("l$a", points[a], points[b], color: _line);
    await controller.track("m$a", offset: points[a].lerp(points[b], 0.5));
  }

  Future<void> _updateClosing() async {
    if (!widget.closeShape) return;
    await controller.removeNode("close").catchError((Object _) {});
    await controller.untrack("mclose");
    if (points.length > 2) {
      await controller.addLine("close", points.last, points.first, color: _line.withValues(alpha: 0.7));
      await controller.track("mclose", offset: points.last.lerp(points.first, 0.5));
    }
  }

  Future<void> undo() async {
    if (points.isEmpty) return;
    final int index = points.length - 1;
    points.removeLast();
    await controller.removeNode("p$index");
    if (index > 0) {
      await controller.removeNode("l${index - 1}");
      await controller.untrack("m${index - 1}");
    }
    if (points.isEmpty) {
      await controller.removeNode("preview");
      _previewReady = false;
    }
    await _updateClosing();
    _notify();
  }

  Future<void> clear() async {
    points.clear();
    _previewReady = false;
    await controller.clearNodes();
    await controller.clearTracks();
    _notify();
  }

  void _notify() {
    widget.onChanged?.call(List<UArVector3>.unmodifiable(points), total, area);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => UArGate(
    labels: widget.labels,
    style: widget.style,
    builder: (BuildContext context, UArCapabilities capabilities) => ColoredBox(
      color: const Color(0xFF000000),
      child: UArView(
        controller: controller,
        placeholder: const Center(child: CircularProgressIndicator()),
        child: ValueListenableBuilder<UArValue>(
          valueListenable: controller,
          builder: (BuildContext context, UArValue value, Widget? _) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => unawaited(addPoint())),
              ),
              UArOverlayLayer(
                controller: controller,
                overlays: <UArOverlay>[
                  for (int i = 0; i + 1 < points.length; i++) _label("m$i", points[i].distanceTo(points[i + 1])),
                  if (widget.closeShape && points.length > 2) _label("mclose", points.last.distanceTo(points.first)),
                ],
              ),
              Center(child: Icon(Icons.add, color: value.frame.centerHit == null ? const Color(0x88FFFFFF) : const Color(0xFFFFFFFF))),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 72,
                left: 24,
                right: 24,
                child: Center(
                  child: UArPill(
                    style: widget.style,
                    child: UTextBodyMedium(uArTrackingHint(value, widget.labels) ?? (points.isEmpty ? widget.labels.tapToAddPoint ?? U.s.tapToAddAPoint : _summary()), textAlign: TextAlign.center),
                  ),
                ),
              ),
              if (widget.showCloseButton)
                PositionedDirectional(
                  top: MediaQuery.paddingOf(context).top + 12,
                  start: 12,
                  child: UArRoundButton(icon: Icons.close, tooltip: U.s.close, style: widget.style, onTap: () => Navigator.of(context).maybePop()),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.paddingOf(context).bottom + 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    UArRoundButton(icon: Icons.undo, tooltip: U.s.undo, style: widget.style, onTap: points.isEmpty ? null : () => unawaited(undo())),
                    UArRoundButton(icon: Icons.add, size: 68, tooltip: U.s.addPoint, style: widget.style, active: true, onTap: () => unawaited(addPoint())),
                    UArRoundButton(icon: Icons.delete_sweep_outlined, tooltip: U.s.clear, style: widget.style, onTap: points.isEmpty ? null : () => unawaited(clear())),
                  ],
                ),
              ),
              UArWebStartButton(controller: controller, style: widget.style, label: widget.labels.startAr),
            ],
          ),
        ),
      ),
    ),
  );

  String _summary() {
    final String length = "${U.s.total}: ${uArFormatDistance(total, unit: widget.unit)}";
    if (!widget.closeShape || points.length < 3) return length;
    final double squareMetres = area;
    final String value = widget.unit == UArMeasureUnit.imperial ? "${(squareMetres * 10.7639).toStringAsFixed(1)} ft²" : "${squareMetres.toStringAsFixed(2)} m²";
    return "$length  •  ${U.s.area}: $value";
  }

  UArOverlay _label(String id, double metres) => UArOverlay(
    id: id,
    alignment: Alignment.center,
    scaleWithDistance: false,
    builder: (BuildContext context, UArProjection projection) => UArPill(
      style: widget.style,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: UTextLabelMedium(uArFormatDistance(metres, unit: widget.unit), fontWeight: FontWeight.bold),
    ),
  );
}

// =============================================================================
// Face try-on (glasses, hats, masks, makeup textures)
// =============================================================================

class UArTryOnItem {
  const UArTryOnItem({
    required this.id,
    required this.title,
    required this.source,
    this.iosSource,
    this.thumbnail,
    this.position = UArVector3.zero,
    this.rotation = UArQuaternion.identity,
    this.fitSize,
    this.scale = UArVector3.one,
  });

  final String id;
  final String title;
  final UArSource source;
  final UArSource? iosSource;
  final Widget? thumbnail;

  /// Offset from the centre of the head: +Y up, -Z out of the face on both platforms.
  final UArVector3 position;
  final UArQuaternion rotation;
  final double? fitSize;
  final UArVector3 scale;
}

class UArFaceTryOn extends StatefulWidget {
  const UArFaceTryOn({
    required this.items,
    this.initialIndex = 0,
    this.showFaceMesh = false,
    this.onSnapshot,
    this.labels = const UArLabels(),
    this.style = const UArStyle(),
    this.overlayBuilder,
    this.showCloseButton = true,
    super.key,
  });

  final List<UArTryOnItem> items;
  final int initialIndex;
  final bool showFaceMesh;
  final void Function(Uint8List image)? onSnapshot;
  final UArLabels labels;
  final UArStyle style;
  final Widget Function(BuildContext context, UArController controller)? overlayBuilder;
  final bool showCloseButton;

  @override
  State<UArFaceTryOn> createState() => UArFaceTryOnState();
}

class UArFaceTryOnState extends State<UArFaceTryOn> with WidgetsBindingObserver, UArLifecycle<UArFaceTryOn> {
  late final UArController controller = UArController(
    config: UArConfig(mode: UArMode.face, camera: UArCameraFacing.front, planeDetection: UArPlaneDetection.none, showFaceMesh: widget.showFaceMesh),
  );
  late int index = widget.initialIndex.clamp(0, max(0, widget.items.length - 1));
  bool _hasFace = false;

  @override
  UArController? get lifecycleController => controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(_onValue);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller
      ..removeListener(_onValue)
      ..dispose();
    super.dispose();
  }

  void _onValue() {
    final bool hasFace = controller.value.faces.isNotEmpty;
    if (hasFace == _hasFace) return;
    _hasFace = hasFace;
    if (hasFace) unawaited(select(index));
    if (mounted) setState(() {});
  }

  Future<void> select(int value) async {
    index = value;
    if (widget.items.isEmpty) return;
    final UArTryOnItem item = widget.items[index];
    try {
      await controller.removeNode("tryon");
      await controller.addNode(
        UArNode.model(
          id: "tryon",
          source: item.source,
          iosSource: item.iosSource,
          anchorId: "face",
          position: item.position,
          rotation: item.rotation,
          scale: item.scale,
          fitSize: item.fitSize,
          pivot: UArPivot.center,
          castShadow: false,
          hittable: false,
        ),
      );
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> snapshot() async {
    final Uint8List? image = await controller.takeSnapshot();
    if (image == null) return;
    if (widget.onSnapshot != null) {
      widget.onSnapshot!(image);
    } else {
      await UShare.bytes(bytes: image, fileName: "tryon_${DateTime.now().millisecondsSinceEpoch}.jpg", mimeType: "image/jpeg");
    }
  }

  @override
  Widget build(BuildContext context) => UArGate(
    labels: widget.labels,
    style: widget.style,
    builder: (BuildContext context, UArCapabilities capabilities) => ColoredBox(
      color: const Color(0xFF000000),
      child: UArView(
        controller: controller,
        placeholder: const Center(child: CircularProgressIndicator()),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ?widget.overlayBuilder?.call(context, controller),
            if (!_hasFace)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 72,
                left: 24,
                right: 24,
                child: Center(
                  child: UArPill(style: widget.style, child: UTextBodyMedium(widget.labels.lookAtCamera ?? U.s.lookAtTheCamera)),
                ),
              ),
            if (widget.showCloseButton)
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + 12,
                start: 12,
                child: UArRoundButton(icon: Icons.close, tooltip: U.s.close, style: widget.style, onTap: () => Navigator.of(context).maybePop()),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UArRoundButton(icon: Icons.camera_alt_outlined, size: 64, tooltip: U.s.takePhoto, style: widget.style, active: true, onTap: () => unawaited(snapshot())),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.items.length,
                      separatorBuilder: (BuildContext context, int i) => const SizedBox(width: 10),
                      itemBuilder: (BuildContext context, int i) => GestureDetector(
                        onTap: () => unawaited(select(i)),
                        child: Container(
                          width: 72,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.style.surface(context),
                            borderRadius: BorderRadius.circular(widget.style.borderRadius),
                            border: Border.all(color: i == index ? widget.style.accent(context) : const Color(0x00000000), width: 2),
                          ),
                          child: Column(
                            children: <Widget>[
                              Expanded(child: widget.items[i].thumbnail ?? Icon(Icons.face_retouching_natural, color: widget.style.onSurface(context))),
                              UTextLabelSmall(widget.items[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// =============================================================================
// Image triggers (posters, catalogues, packaging, menus, business cards)
// =============================================================================

class UArImageTarget {
  const UArImageTarget({
    required this.name,
    required this.source,
    this.physicalWidth = 0.2,
    this.video,
    this.model,
    this.modelSize,
    this.nodes,
    this.overlayBuilder,
    this.overlayOffset = const UArVector3(0, 0.02, 0),
  });

  final String name;
  final UArSource source;

  /// Printed width in metres; the closer to reality, the steadier the tracking.
  final double physicalWidth;

  /// Plays on top of the image, sized to it.
  final UArSource? video;

  /// Stands on the image.
  final UArSource? model;
  final double? modelSize;

  /// Anything else, attached to the image (use `anchorId: "image:$name"`).
  final List<UArNode> Function(UArTrackedImage image)? nodes;

  /// A Flutter card pinned to the image.
  final Widget Function(BuildContext context, UArTrackedImage image, UArProjection projection)? overlayBuilder;

  /// Local to the image: +Y out of the image.
  final UArVector3 overlayOffset;

  UArReferenceImage get reference => UArReferenceImage(name: name, source: source, physicalWidth: physicalWidth);
}

class UArImageTrigger extends StatefulWidget {
  const UArImageTrigger({
    required this.targets,
    this.imageOnly = false,
    this.maxTracked = 4,
    this.onDetected,
    this.onLost,
    this.labels = const UArLabels(),
    this.style = const UArStyle(),
    this.showCloseButton = true,
    super.key,
  });

  final List<UArImageTarget> targets;

  /// Tracks only images (cheaper; iOS) instead of the whole world.
  final bool imageOnly;
  final int maxTracked;
  final void Function(UArTrackedImage image)? onDetected;
  final void Function(UArTrackedImage image)? onLost;
  final UArLabels labels;
  final UArStyle style;
  final bool showCloseButton;

  @override
  State<UArImageTrigger> createState() => UArImageTriggerState();
}

class UArImageTriggerState extends State<UArImageTrigger> with WidgetsBindingObserver, UArLifecycle<UArImageTrigger> {
  late final UArController controller = UArController(
    config: UArConfig(
      mode: widget.imageOnly ? UArMode.image : UArMode.world,
      images: widget.targets.map((UArImageTarget t) => t.reference).toList(),
      maxTrackedImages: widget.maxTracked,
      planeStyle: UArPlaneStyle.hidden,
    ),
  );
  final Set<String> _built = <String>{};
  final Map<String, bool> _tracking = <String, bool>{};
  StreamSubscription<UArTrackedImage>? _images;

  @override
  UArController? get lifecycleController => controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _images = controller.imageEvents.listen((UArTrackedImage image) => unawaited(_onImage(image)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_images?.cancel());
    controller.dispose();
    super.dispose();
  }

  Future<void> _onImage(UArTrackedImage image) async {
    final bool was = _tracking[image.name] ?? false;
    _tracking[image.name] = image.isTracking;
    if (image.isTracking && !was) widget.onDetected?.call(image);
    if (!image.isTracking && was) widget.onLost?.call(image);
    if (_built.contains(image.name) || !image.isTracking) {
      if (mounted) setState(() {});
      return;
    }
    _built.add(image.name);
    final UArImageTarget? target = widget.targets.where((UArImageTarget t) => t.name == image.name).firstOrNull;
    if (target == null) return;
    final String anchor = image.anchorId;
    final double width = image.width > 0 ? image.width : target.physicalWidth;
    try {
      if (target.video != null) {
        await controller.addNode(
          UArNode.video(
            id: "video_${image.name}",
            source: target.video!,
            width: width,
            height: image.height > 0 ? image.height : width * 9 / 16,
            anchorId: anchor,
            rotation: UArQuaternion.pitch(-pi / 2),
          ),
        );
      }
      if (target.model != null) {
        await controller.addNode(UArNode.model(id: "model_${image.name}", source: target.model!, anchorId: anchor, fitSize: target.modelSize ?? width));
      }
      for (final UArNode node in target.nodes?.call(image) ?? const <UArNode>[]) {
        await controller.addNode(node.anchorId == null ? node.copyWith(anchorId: anchor) : node);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => UArGate(
    labels: widget.labels,
    style: widget.style,
    builder: (BuildContext context, UArCapabilities capabilities) => ColoredBox(
      color: const Color(0xFF000000),
      child: UArView(
        controller: controller,
        placeholder: const Center(child: CircularProgressIndicator()),
        child: ValueListenableBuilder<UArValue>(
          valueListenable: controller,
          builder: (BuildContext context, UArValue value, Widget? _) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              UArOverlayLayer(
                controller: controller,
                overlays: <UArOverlay>[
                  for (final UArImageTarget target in widget.targets)
                    if (target.overlayBuilder != null && value.images[target.name]?.isTracking == true)
                      UArOverlay(
                        id: "overlay_${target.name}",
                        anchorId: "image:${target.name}",
                        offset: target.overlayOffset,
                        builder: (BuildContext context, UArProjection projection) => target.overlayBuilder!(context, value.images[target.name]!, projection),
                      ),
                ],
              ),
              if (!value.images.values.any((UArTrackedImage i) => i.isTracking))
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 72,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: UArPill(
                      style: widget.style,
                      child: UTextBodyMedium(uArTrackingHint(value, widget.labels, needsSurface: false) ?? widget.labels.pointAtImage ?? U.s.pointYourCameraAtTheImage),
                    ),
                  ),
                ),
              if (widget.showCloseButton)
                PositionedDirectional(
                  top: MediaQuery.paddingOf(context).top + 12,
                  start: 12,
                  child: UArRoundButton(icon: Icons.close, tooltip: U.s.close, style: widget.style, onTap: () => Navigator.of(context).maybePop()),
                ),
              UArWebStartButton(controller: controller, style: widget.style, label: widget.labels.startAr),
            ],
          ),
        ),
      ),
    ),
  );
}

// =============================================================================
// QR / barcode anchored cards (store shelves, exhibition booths, machines)
// =============================================================================

class UArCodeView extends StatefulWidget {
  const UArCodeView({
    required this.cardBuilder,
    this.filter,
    this.onCode,
    this.scanInterval = const Duration(milliseconds: 700),
    this.maxCodes = 8,
    this.labels = const UArLabels(),
    this.style = const UArStyle(),
    this.showCloseButton = true,
    super.key,
  });

  final Widget Function(BuildContext context, String code, UArProjection projection) cardBuilder;

  /// Return false to ignore a code.
  final bool Function(String code)? filter;
  final void Function(String code)? onCode;
  final Duration scanInterval;
  final int maxCodes;
  final UArLabels labels;
  final UArStyle style;
  final bool showCloseButton;

  @override
  State<UArCodeView> createState() => UArCodeViewState();
}

class UArCodeViewState extends State<UArCodeView> with WidgetsBindingObserver, UArLifecycle<UArCodeView> {
  late final UArController controller = UArController(config: const UArConfig(planeStyle: UArPlaneStyle.hidden));
  final Map<String, String> anchors = <String, String>{};
  Timer? _timer;
  bool _scanning = false;

  @override
  UArController? get lifecycleController => controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_begin());
  }

  Future<void> _begin() async {
    try {
      await controller.ready;
    } catch (_) {
      return;
    }
    _timer = Timer.periodic(widget.scanInterval, (Timer _) => unawaited(_scan()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning || !controller.value.isTracking || anchors.length >= widget.maxCodes) return;
    _scanning = true;
    try {
      final List<UArCodeResult> codes = await controller.detectCodes();
      for (final UArCodeResult code in codes) {
        if (anchors.containsKey(code.text) || widget.filter?.call(code.text) == false) continue;
        final Size size = controller.viewSize;
        final Offset point = Offset(code.center.dx * size.width, code.center.dy * size.height);
        final UArHitResult? hit = (await controller.hitTest(point)).firstOrNull;
        if (hit == null) continue;
        final UArAnchor anchor = await controller.addAnchor(hit.pose);
        anchors[code.text] = anchor.id;
        widget.onCode?.call(code.text);
        unawaited(HapticFeedback.selectionClick());
        if (mounted) setState(() {});
      }
    } catch (_) {
    } finally {
      _scanning = false;
    }
  }

  @override
  Widget build(BuildContext context) => UArGate(
    labels: widget.labels,
    style: widget.style,
    builder: (BuildContext context, UArCapabilities capabilities) => ColoredBox(
      color: const Color(0xFF000000),
      child: UArView(
        controller: controller,
        placeholder: const Center(child: CircularProgressIndicator()),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            UArOverlayLayer(
              controller: controller,
              overlays: <UArOverlay>[
                for (final MapEntry<String, String> entry in anchors.entries)
                  UArOverlay(
                    id: "code_${entry.key}",
                    anchorId: entry.value,
                    offset: const UArVector3(0, 0.03, 0),
                    builder: (BuildContext context, UArProjection projection) => widget.cardBuilder(context, entry.key, projection),
                  ),
              ],
            ),
            if (anchors.isEmpty)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 72,
                left: 24,
                right: 24,
                child: Center(
                  child: UArPill(style: widget.style, child: UTextBodyMedium(widget.labels.pointAtCode ?? U.s.pointYourCameraAtAQrCode)),
                ),
              ),
            if (widget.showCloseButton)
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + 12,
                start: 12,
                child: UArRoundButton(icon: Icons.close, tooltip: U.s.close, style: widget.style, onTap: () => Navigator.of(context).maybePop()),
              ),
          ],
        ),
      ),
    ),
  );
}

// =============================================================================
// One-call experiences
// =============================================================================

/// Full-screen host for any AR widget.
class UArPage extends StatelessWidget {
  const UArPage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF000000), body: child);
}

abstract class UArExperiences {
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
          fallback: (BuildContext context, UArAvailability availability) => _NativeFallback(items: items, labels: labels, style: style),
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

  static Future<void> measure({UArMeasureUnit unit = UArMeasureUnit.metric, bool closeShape = false}) => UNavigator.push<void>(
    UArPage(
      child: UArMeasure(unit: unit, closeShape: closeShape),
    ),
    fullscreenDialog: true,
  );

  static Future<void> tryOn({required List<UArTryOnItem> items, int initialIndex = 0}) => UNavigator.push<void>(
    UArPage(
      child: UArFaceTryOn(items: items, initialIndex: initialIndex),
    ),
    fullscreenDialog: true,
  );

  static Future<void> images({required List<UArImageTarget> targets}) => UNavigator.push<void>(UArPage(child: UArImageTrigger(targets: targets)), fullscreenDialog: true);

  static Future<void> places({required List<UArPlace> places, void Function(UArPlace place)? onPlaceTap, double maxDistance = 800}) => UNavigator.push<void>(
    UArPage(
      child: UArGeoView(places: places, onPlaceTap: onPlaceTap, maxDistance: maxDistance),
    ),
    fullscreenDialog: true,
  );

  static Future<void> codes({required Widget Function(BuildContext context, String code, UArProjection projection) cardBuilder}) =>
      UNavigator.push<void>(UArPage(child: UArCodeView(cardBuilder: cardBuilder)), fullscreenDialog: true);

  static Future<UArRoomScanResult?> scanRoom() => UAr.scanRoom(
    options: UArRoomScanOptions(doneLabel: U.s.done, cancelLabel: U.s.cancel),
  );

  static Future<UArObjectCaptureResult?> captureObject({UArObjectCaptureDetail detail = UArObjectCaptureDetail.reduced}) => UAr.captureObject(
    options: UArObjectCaptureOptions(
      detail: detail,
      labels: <String, String>{"continue": U.s.next, "start": U.s.startCapture, "finish": U.s.finish, "cancel": U.s.cancel, "processing": U.s.processing},
    ),
  );
}

class _NativeFallback extends StatelessWidget {
  const _NativeFallback({required this.items, required this.labels, required this.style});

  final List<UArPlaceable> items;
  final UArLabels labels;
  final UArStyle style;

  @override
  Widget build(BuildContext context) {
    final UArPlaceable? item = items.where((UArPlaceable i) => i.source != null).firstOrNull;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (item != null) U3DViewer(source: item.source!, iosSource: item.iosSource, title: item.title, showArButton: false, labels: labels, style: style),
        Positioned(
          left: 24,
          right: 24,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UArPill(
                style: style,
                child: UTextBodyMedium(labels.unsupported ?? U.s.arIsNotSupportedOnThisDevice, textAlign: TextAlign.center),
              ),
              if (item != null) ...<Widget>[
                const SizedBox(height: 12),
                UButton(
                  title: labels.viewInYourSpace ?? U.s.viewInYourSpace,
                  icon: const Icon(Icons.view_in_ar),
                  borderRadius: 24,
                  backgroundColor: style.accent(context),
                  foregroundColor: style.onAccent(context),
                  onTap: () => unawaited(UAr.openNativeViewer(UArNativeViewerOptions(source: item.source!, iosSource: item.iosSource, title: item.title))),
                ),
              ],
            ],
          ),
        ),
        PositionedDirectional(
          top: MediaQuery.paddingOf(context).top + 12,
          start: 12,
          child: UArRoundButton(icon: Icons.close, tooltip: U.s.close, style: style, onTap: () => Navigator.of(context).maybePop()),
        ),
      ],
    );
  }
}
