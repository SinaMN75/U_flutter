import "package:flutter_test/flutter_test.dart";
import "package:u/utilities.dart";

Widget _app(Widget child) => MaterialApp(
  navigatorKey: navigatorKey,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Future<void> _settle(WidgetTester tester, {int rounds = 8}) async {
  for (int i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 40));
  }
}

/// Stands in for the native player: accepts every call and reports a 60 s video.
void _fakeMediaChannel(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel("u/media"), (MethodCall call) async {
    if (call.method == "create") return 1;
    if (call.method == "enterPip") return false;
    return null;
  });
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel("u/media/events/1"), (MethodCall call) async => null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final Size size in <Size>[const Size(1300, 800), const Size(400, 820)]) {
    testWidgets("video with notes at ${size.width.round()}px", (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(size);
      _fakeMediaChannel(tester);
      final UMediaController controller = UMediaController();
      final UMediaNotesController notes = UMediaNotesController(initialData: '{"markers":[{"color":4294198070,"type":"text","text":"legacy","seconds":4}]}'.toBase64());
      await tester.pumpWidget(_app(UVideoWithNotes(controller: controller, notes: notes, title: "Test", watermark: const UDocWatermark(lines: <String>["u"]), resumeKey: "test")));
      await tester.runAsync(() => controller.open(UMediaSource.network("https://example.com/a.mp4")));
      await _settle(tester);
      expect(notes.length, 1);

      notes.add(position: const Duration(seconds: 10), text: "یادداشت دوم");
      await _settle(tester);
      expect(find.text("یادداشت دوم"), findsWidgets);

      // Tap a note → seek; toggle controls; open the settings sheet.
      await tester.tap(find.text("legacy").first);
      await _settle(tester);
      await tester.tap(find.byType(UVideoGestures).first, warnIfMissed: false);
      await _settle(tester);
      final Finder settings = find.byTooltip(U.s.settings);
      if (settings.evaluate().isNotEmpty) {
        await tester.tap(settings.first, warnIfMissed: false);
        await _settle(tester);
        await Navigator.of(navigatorKey.currentContext!).maybePop();
        await _settle(tester);
      }
      expect(tester.takeException(), isNull);
      expect(notes.toSrt(), contains("00:00:10,000"));

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      notes.dispose();
      await tester.pump(const Duration(seconds: 3));
    });
  }

  testWidgets("audio player with notes, seek buttons and speed sheet", (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 860));
    _fakeMediaChannel(tester);
    final UMediaController controller = UMediaController(kind: UMediaKind.audio, config: UMediaConfig.music);
    final UMediaNotesController notes = UMediaNotesController();
    await tester.pumpWidget(_app(UMusicPlayer(controller: controller, notes: notes, resumeKey: "audio-test")));
    await tester.runAsync(() => controller.open(UMediaSource.network("https://example.com/a.mp3", metadata: const UMediaMetadata(title: "Lecture 1"))));
    await _settle(tester);
    expect(find.byTooltip(U.s.seekBackward), findsOneWidget);
    expect(find.byTooltip(U.s.seekForward), findsOneWidget);
    notes.add(position: const Duration(seconds: 3), text: "note");
    await _settle(tester);
    await tester.tap(find.byTooltip(U.s.playbackSpeed));
    await _settle(tester);
    expect(find.text(U.s.fineSpeed), findsOneWidget);
    await Navigator.of(navigatorKey.currentContext!).maybePop();
    await _settle(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    notes.dispose();
    await tester.pump(const Duration(seconds: 3));
  });
}
