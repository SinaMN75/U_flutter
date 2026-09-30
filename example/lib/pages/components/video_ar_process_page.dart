import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// Video player building blocks, AR widgets, process (KYC) screens, content page and download helpers.
class VideoArProcessPage extends StatefulWidget {
  const VideoArProcessPage({super.key});

  @override
  State<VideoArProcessPage> createState() => _VideoArProcessPageState();
}

class _VideoArProcessPageState extends State<VideoArProcessPage> {
  static const String _video = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8";
  static const String _glb = "https://modelviewer.dev/shared-assets/models/Astronaut.glb";

  late final UMediaController _player = UMedia.video()..open(UMedia.network(_video));
  final UVideoSettings _settings = UVideoSettings();
  final UArController _ar = UArController();
  late final UProcessStepSend _send = UProcessStepSend(stepId: "1", processId: "demo", fields: <UProcessField>[]);
  late final UProcessField _textField = UProcessField(label: "Full name", type: TagFieldType.text, required: true, key: "name");
  late final UProcessField _fileField = UProcessField(label: "ID card photo", type: TagFieldType.file, required: false, key: "card");

  @override
  void dispose() {
    _player.dispose();
    _ar.dispose();
    super.dispose();
  }

  Widget _box(Widget child, {double height = 200}) => SizedBox(height: height, child: child);

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Video, AR, process",
    children: <Widget>[
      DemoGroup("Video building blocks", <Widget>[
        Demo(
          'UVideoPlayer(url: …, resumeKey: …)',
          child: _box(const UVideoPlayer(url: _video, resumeKey: "demo-video", autoPlay: false), height: 220),
        ),
        Fn("UVideoSheet.show(url: …)", () => UVideoSheet.show(url: _video, title: "Sheet player")),
        Demo(
          "UVideoView(controller: …) + UVideoControls",
          child: _box(
            Stack(
              fit: StackFit.expand,
              children: <Widget>[
                UVideoView(controller: _player),
                UVideoControls(controller: _player),
              ],
            ),
          ),
        ),
        Demo(
          "UVideoGestures(controller: …, child: …)",
          child: _box(
            UVideoGestures(
              controller: _player,
              child: UVideoView(controller: _player),
            ),
          ),
        ),
        Demo("UVideoSeekBar(controller: …)", child: UVideoSeekBar(controller: _player)),
        Demo("USubtitleView(controller: …)", child: _box(USubtitleView(controller: _player), height: 60)),
        Demo("UVideoStatsOverlay(controller: …)", child: _box(UVideoStatsOverlay(controller: _player), height: 180)),
        Demo(
          "UVideoFilterLayer(settings: …, child: …)",
          child: _box(
            UVideoFilterLayer(
              settings: _settings..saturation = 0,
              child: UImage("https://picsum.photos/seed/v/400/200", fit: BoxFit.cover),
            ),
            height: 120,
          ),
        ),
        Fn("UMediaTrackSheet(controller: …, type: subtitle)", () => UNavigator.bottomSheet<void>(UMediaTrackSheet(controller: _player, type: UMediaTrackType.subtitle))),
        Fn("UVideoSettingsSheet(controller: …, settings: …)", () => UNavigator.bottomSheet<void>(UVideoSettingsSheet(controller: _player, settings: _settings))),
        Demo(
          "UFloatingMiniPlayer(controller: …)",
          child: _box(Stack(children: <Widget>[UFloatingMiniPlayer(controller: _player)]), height: 160),
        ),
        Fn("UVideoColorMatrix.identity() / multiply(a, b)", () => UVideoColorMatrix.multiply(UVideoColorMatrix.identity(), UVideoColorMatrix.identity()).length, auto: true),
        Fn(
          "UVideoView.ratioOf / boxFitOf / UVideoPlayer.fitOf",
          () => <Object?>[UVideoView.ratioOf(UMediaFit.contain), UVideoView.boxFitOf(UMediaFit.cover), UVideoPlayer.fitOf(BoxFit.cover)],
          auto: true,
        ),
      ]),
      DemoGroup("AR widgets", <Widget>[
        Fn("uArFormatDistance(1250) / uArTrackingHint(value, labels)", () => <Object?>[uArFormatDistance(1250), uArTrackingHint(_ar.value, const UArLabels())], auto: true),
        Demo("U3DViewer(source: …) (all platforms)", child: _box(U3DViewer(source: UArSource.url(_glb)), height: 260)),
        Demo(
          "UArPill / UArRoundButton / UArForeground",
          child: URow(
            spacing: 12,
            children: <Widget>[
              const UArPill(child: Text("Find a surface")),
              UArRoundButton(icon: Icons.camera_alt, onTap: () {}),
              const UArForeground(color: Colors.black, child: Text("on camera")),
            ],
          ),
        ),
        Demo("UArGate(builder: (context, capabilities) => …)", child: _box(UArGate(builder: (BuildContext c, UArCapabilities caps) => Text("AR ready: $caps")), height: 80)),
        Demo(
          "UArWebStartButton(controller: …)",
          note: "Web only: starts WebXR",
          child: UArWebStartButton(controller: _ar),
        ),
        Fn(
          "UArPage(child: UArScene(items: …))",
          () => UNavigator.push<void>(
            UArPage(
              child: UArScene(
                items: <UArPlaceable>[UArPlaceable(id: "a", title: "Astronaut", source: UArSource.url(_glb))],
              ),
            ),
          ),
        ),
        Fn("UArPage(child: UArMeasure())", () => UNavigator.push<void>(const UArPage(child: UArMeasure()))),
        Fn(
          "UArPage(child: UArGeoView(places: …))",
          () => UNavigator.push<void>(
            const UArPage(
              child: UArGeoView(
                places: <UArPlace>[UArPlace(id: "azadi", latitude: 35.6997, longitude: 51.3380, title: "Azadi Tower")],
              ),
            ),
          ),
        ),
        Fn(
          "UArPage(child: UArFaceTryOn(items: …))",
          () => UNavigator.push<void>(
            UArPage(
              child: UArFaceTryOn(
                items: <UArTryOnItem>[UArTryOnItem(id: "a", title: "Helmet", source: UArSource.url(_glb))],
              ),
            ),
          ),
        ),
        Fn(
          "UArPage(child: UArImageTrigger(targets: …))",
          () => UNavigator.push<void>(
            UArPage(
              child: UArImageTrigger(
                targets: <UArImageTarget>[UArImageTarget(name: "poster", source: UArSource.url("https://picsum.photos/400"))],
              ),
            ),
          ),
        ),
        Fn("UArPage(child: UArCodeView(cardBuilder: …))", () => UNavigator.push<void>(UArPage(child: UArCodeView(cardBuilder: (BuildContext c, String code, UArProjection p) => UPill(code))))),
        Fn(
          "UArNativeFallback(items: …) (no-AR fallback)",
          () => UNavigator.push<void>(
            UScaffold(
              appBar: AppBar(),
              body: UArNativeFallback(
                items: <UArPlaceable>[UArPlaceable(id: "a", title: "Astronaut", source: UArSource.url(_glb))],
              ),
            ),
          ),
        ),
        Demo(
          "UArOverlayLayer(controller: …, overlays: …)",
          child: _box(
            UArOverlayLayer(
              controller: _ar,
              overlays: <UArOverlay>[UArOverlay(id: "label", builder: (BuildContext c, UArProjection p) => const UPill("pinned to a 3D point"))],
            ),
            height: 60,
          ),
        ),
        const Demo("UArLifecycle mixin: override UArLifecycle.lifecycleController in your AR State", child: _LifecycleDemo()),
      ]),
      DemoGroup("Process (server-driven KYC)", <Widget>[
        Fn(
          'UProcessView.open("processId")',
          () => UProcessView.open("demo-process", onCompleted: () => UToast.success(message: "done")),
          note: "Loads steps from your backend",
        ),
        Demo('UProcessView(processId: …)', child: _box(const UProcessView(processId: "demo-process"), height: 160)),
        Demo(
          "UProcessStepsIndicator(steps: …)",
          child: UProcessStepsIndicator(
            steps: <UProcessStepStatus>[
              UProcessStepStatus(id: "1", title: "Info", status: TagProcessStepStatus.verified),
              UProcessStepStatus(id: "2", title: "Documents", status: TagProcessStepStatus.current),
              UProcessStepStatus(id: "3", title: "Selfie", status: TagProcessStepStatus.notStarted),
            ],
          ),
        ),
        Demo(
          "UProcessTextField(field: …, processStepSend: …)",
          child: UProcessTextField(field: _textField, processStepSend: _send),
        ),
        Demo(
          "UProcessImagePickerField(field: …, processStepSend: …)",
          child: UProcessImagePickerField(field: _fileField, processStepSend: _send),
        ),
        Demo(
          "UProcessESignField(onSubmit: …)",
          child: UProcessESignField(onSubmit: (String b64) => UToast.toast(message: "${b64.length} chars")),
        ),
        Demo(
          "UProcessVisualAuthField(field: …, processStepSend: …)",
          note: "Needs `permission add camera microphone`",
          child: UProcessVisualAuthField(
            field: UProcessField(label: "Video selfie", type: TagFieldType.file, required: false, key: "selfie"),
            processStepSend: _send,
          ),
        ),
        Demo(
          "UProcessFields(processStepGet: …, processStepSend: …)",
          child: UProcessFields(
            processStepGet: UProcessStepGet(id: "1", title: "Your info", description: "Fill the fields", fields: <UProcessField>[_textField]),
            processStepSend: _send,
          ),
        ),
      ]),
      DemoGroup("Pages & download helpers", <Widget>[
        Fn("UNavigator.push(UContentBentoPage(content: …))", () => UNavigator.push<void>(UScaffold(appBar: AppBar(), body: const UContentBentoPage(content: null)))),
        Fn("uDownloadStatusLabel / uDownloadErrorLabel / uDownloadCategoryIcon / uFormatBytes", () {
          final UDownloadTask? task = UDownloads.allTasks.firstOrNull;
          return <Object?>[task == null ? "no task yet" : uDownloadStatusLabel(task), uDownloadErrorLabel(null), uDownloadCategoryIcon(UDownloadCategory.video), uFormatBytes(1536000)];
        }, auto: true),
        Fn("UDownloadSettingsSheet.show()", UDownloadSettingsSheet.show),
        Fn("UNavigator.bottomSheet(UDownloadSettingsSheet())", () => UNavigator.bottomSheet<void>(const UDownloadSettingsSheet())),
      ]),
    ],
  );
}

class _LifecycleDemo extends StatefulWidget {
  const _LifecycleDemo();

  @override
  State<_LifecycleDemo> createState() => _LifecycleDemoState();
}

class _LifecycleDemoState extends State<_LifecycleDemo> with WidgetsBindingObserver, UArLifecycle<_LifecycleDemo> {
  final UArController _controller = UArController();

  @override
  UArController? get lifecycleController => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text("pauses AR when the app goes to the background (${lifecycleController.runtimeType})");
}
