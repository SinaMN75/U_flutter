import "package:flutter_test/flutter_test.dart";
import "package:u/utilities.dart";

Widget _app(Widget child) => MaterialApp(
  navigatorKey: navigatorKey,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Future<void> _settle(WidgetTester tester, {int rounds = 20}) async {
  for (int i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 40));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final Size size in <Size>[const Size(1300, 900), const Size(400, 820)]) {
    testWidgets("PDF viewer UI at ${size.width.round()}px: markups, sidebar, search, settings, reload", (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(size);
      final Uint8List bytes = File("example/assets/docs/sample_fa_en.pdf").readAsBytesSync();
      final GlobalKey<UPdfViewerState> key = GlobalKey<UPdfViewerState>();
      String synced = "";
      await tester.pumpWidget(_app(UPdfViewer(key: key, bytes: bytes, persistAnnotations: false, onAnnotationsChanged: (String data) => synced = data, watermark: const UDocWatermark(lines: <String>["test"]))));
      await _settle(tester);
      final UPdfViewerState viewer = key.currentState!;
      expect(viewer.controller.value.isReady, isTrue);

      // Markup of every kind from real page text, then restyle / note / delete.
      final UDocTextPage text = (await tester.runAsync(() => viewer.controller.textPage(0)))!;
      final (int, int) range = text.locate("هایلایت")!;
      final Size page = text.size;
      for (final UDocMarkupKind kind in UDocMarkupKind.values) {
        viewer.annotations.add(
          UDocMarkup.create(
            kind: kind,
            pageIndex: 0,
            start: range.$1,
            end: range.$2,
            text: "هایلایت",
            color: const Color(0xFF4FC3F7),
            note: kind == UDocMarkupKind.note ? "یادداشت" : "",
            rects: text.rectsForRange(range.$1, range.$2).map((Rect r) => Rect.fromLTRB(r.left / page.width, r.top / page.height, r.right / page.width, r.bottom / page.height)).toList(),
          ),
        );
        await tester.pump();
      }
      expect(synced, isNotEmpty);
      viewer.annotations.toggleBookmark(1);
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Every sidebar tab / panel.
      final Finder sidebar = find.byTooltip(U.s.thumbnails);
      if (sidebar.evaluate().isNotEmpty) {
        await tester.tap(sidebar.first);
        await _settle(tester, rounds: 4);
      }
      for (final String tab in <String>[U.s.outline, U.s.annotations, U.s.bookmarks, U.s.search, U.s.thumbnails]) {
        final Finder button = find.byTooltip(tab);
        if (button.evaluate().isEmpty) continue;
        await tester.tap(button.last);
        await _settle(tester, rounds: 4);
        expect(tester.takeException(), isNull, reason: "tab $tab");
      }

      // Search.
      await tester.runAsync(() => viewer.controller.search("یادداشت"));
      await _settle(tester, rounds: 4);
      expect(viewer.controller.value.searchHits, isNotEmpty);

      // Close the overlay sidebar on phones, then the settings sheet and layout modes.
      if (size.width < 900) {
        await tester.tap(find.byTooltip(U.s.thumbnails).first, warnIfMissed: false);
        await _settle(tester, rounds: 4);
      }
      await tester.tap(find.byTooltip(U.s.settings).first);
      await _settle(tester, rounds: 4);
      expect(tester.takeException(), isNull);
      await Navigator.of(navigatorKey.currentContext!).maybePop();
      await _settle(tester, rounds: 4);
      for (final UDocScrollMode mode in <UDocScrollMode>[UDocScrollMode.pagedHorizontal, UDocScrollMode.horizontalContinuous, UDocScrollMode.verticalContinuous]) {
        viewer.controller.updateSettings(viewer.controller.settings.copyWith(scrollMode: mode, spread: mode == UDocScrollMode.verticalContinuous ? UDocSpread.two : UDocSpread.none));
        await _settle(tester, rounds: 4);
        expect(tester.takeException(), isNull, reason: "mode $mode");
      }
      viewer.jumpToPage(3);
      viewer.setZoom(2);
      await _settle(tester, rounds: 4);
      expect(tester.takeException(), isNull);

      // "Reload": a new viewer fed the synced payload restores every markup and bookmark.
      await tester.pumpWidget(const SizedBox.shrink());
      final GlobalKey<UPdfViewerState> reloaded = GlobalKey<UPdfViewerState>();
      await tester.pumpWidget(_app(UPdfViewer(key: reloaded, bytes: bytes, persistAnnotations: false, annotationData: synced)));
      await _settle(tester);
      expect(reloaded.currentState!.annotations.markups.length, UDocMarkupKind.values.length);
      expect(reloaded.currentState!.annotations.isBookmarked(1), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });
  }
}
