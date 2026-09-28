import "package:flutter_test/flutter_test.dart";
import "package:u/utilities.dart";

Widget _app(Widget child) => MaterialApp(
  navigatorKey: navigatorKey,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _drag(WidgetTester tester, Offset from, Offset to) async {
  final TestGesture gesture = await tester.startGesture(from);
  for (int i = 1; i <= 10; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / 10)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("adding, restyling and removing markups never breaks the text tree", (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final Uint8List bytes = File("example/assets/docs/sample_fa.epub").readAsBytesSync();
    final UEpubController controller = UEpubController();
    final UDocAnnotationController notes = UDocAnnotationController();
    await tester.pumpWidget(_app(UEpubReader(controller: controller, annotations: notes, bytes: bytes, persistAnnotations: false, restorePosition: false)));
    await _settle(tester);
    expect(controller.value.isReady, isTrue);
    expect(find.byType(UEpubBlockView), findsWidgets);

    final UEpubChapter chapter = await tester.runAsync(() => controller.chapter(0)) ?? (throw StateError("no chapter"));
    final int block = chapter.blocks.indexWhere((UEpubBlock b) => b.isText && b.text.length > 40 && b.kind == UEpubBlockKind.paragraph);
    final int listItem = chapter.blocks.indexWhere((UEpubBlock b) => b.kind == UEpubBlockKind.listItem);
    expect(block, greaterThanOrEqualTo(0));

    // First markup on a block: the block view gains a painter (previously re-registered its notifier and asserted).
    notes.add(UDocMarkup.create(kind: UDocMarkupKind.highlight, pageIndex: 0, blockIndex: block, start: 5, end: 30, text: chapter.blocks[block].text.substring(5, 30), color: const Color(0xFFFFEB3B)));
    await tester.pump();
    expect(tester.takeException(), isNull);

    notes.add(UDocMarkup.create(kind: UDocMarkupKind.squiggly, pageIndex: 0, blockIndex: listItem, end: 6, text: chapter.blocks[listItem].text.substring(0, 6), color: const Color(0xFFE53935), note: "یادداشت"));
    await tester.pump();
    expect(tester.takeException(), isNull);

    notes.updateGroup(notes.markups.first.groupKey, kind: UDocMarkupKind.border);
    await tester.pump();
    notes.clear();
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Paged mode and a bigger font re-lay out every block.
    controller.setScrollMode(UDocScrollMode.pagedHorizontal);
    controller.setTypography(controller.typography.copyWith(fontScale: 1.6));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(UEpubBlockView), findsWidgets);

    // Unmount and let the debounced progress save fire.
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets("drawing on paragraphs: no text selection, survives paging and reload", (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final Uint8List bytes = File("example/assets/docs/sample_fa.epub").readAsBytesSync();
    final UEpubController controller = UEpubController();
    final GlobalKey<UEpubReaderState> key = GlobalKey<UEpubReaderState>();
    String synced = "";
    await tester.pumpWidget(_app(UEpubReader(key: key, controller: controller, bytes: bytes, persistAnnotations: false, restorePosition: false, onAnnotationsChanged: (String data) => synced = data)));
    await _settle(tester);
    final UEpubReaderState reader = key.currentState!;
    final UEpubChapter chapter = await tester.runAsync(() => controller.chapter(0)) ?? (throw StateError("no chapter"));
    final int block = chapter.blocks.indexWhere((UEpubBlock b) => b.isText && b.text.length > 40 && b.kind == UEpubBlockKind.paragraph);

    await tester.tap(find.byTooltip(U.s.draw));
    await tester.pump();
    expect(reader.drawing.tool, UDocDrawTool.pen);
    expect(tester.takeException(), isNull, reason: "adding the drawing layers must not re-register selection listeners");

    reader.drawing.tool = UDocDrawTool.areaHighlight;
    await tester.pump();
    final Finder paragraph = find.byWidgetPredicate((Widget widget) => widget is UEpubBlockView && widget.blockIndex == block);
    final Rect box = tester.getRect(paragraph.first);
    await _drag(tester, box.topLeft + Offset(box.width * 0.2, 6), box.topLeft + Offset(box.width * 0.7, box.height - 4));
    await tester.pump(const Duration(milliseconds: 100));
    final UDocShape shape = reader.annotations.shapes.single;
    expect(shape.kind, UDocShapeKind.areaHighlight);
    expect(shape.pageIndex, 0);
    expect(shape.blockIndex, block);
    expect(find.byType(UDocSelectionMenu), findsNothing, reason: "drawing must not select text");
    expect(synced, isNotEmpty);

    // Text box typed on the page.
    reader.drawing.tool = UDocDrawTool.textBox;
    await tester.pump();
    await tester.tapAt(box.topLeft + Offset(box.width * 0.3, box.height / 2));
    await tester.pump();
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, "حاشیه");
    reader.toggleDrawing(false);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(reader.annotations.shapes.map((UDocShape shape) => shape.text), contains("حاشیه"));

    // Paged mode + bigger font: the paragraph may split, nothing may throw.
    controller.setScrollMode(UDocScrollMode.pagedHorizontal);
    controller.setTypography(controller.typography.copyWith(fontScale: 1.8));
    await _settle(tester);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    final UDocAnnotationController restored = UDocAnnotationController(initialData: synced);
    expect(restored.shapesOnBlock(0, block).length, 2);
    restored.dispose();
    controller.dispose();
    await tester.pump(const Duration(seconds: 3));
  });

  test("a continued paragraph maps its drawings through the slice origin", () {
    const UDocShapeGeometry whole = UDocShapeGeometry(Size(400, 900), UDocShapeSpace.width);
    const UDocShapeGeometry slice = UDocShapeGeometry(Size(400, 300), UDocShapeSpace.width, origin: Offset(0, 250));
    const Offset point = Offset(0.5, 0.75);
    expect(whole.toPixels(point), const Offset(200, 300));
    expect(slice.toPixels(point), const Offset(200, 50));
    expect(slice.toNormal(const Offset(200, 50)), point);
  });

  test("line rects are one trimmed box per visual line", () {
    const String text = "alpha beta gamma delta epsilon zeta eta theta iota kappa";
    final TextPainter painter = TextPainter(
      text: const TextSpan(text: text, style: TextStyle(fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 120, maxWidth: 120);
    final List<Rect> rects = UEpubTextStyler.lineRects(painter, text, 0, text.length, fontSize: 10);
    expect(rects.length, painter.computeLineMetrics().length);
    for (final Rect rect in rects) {
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(120.5));
      expect(rect.height, lessThanOrEqualTo(13.1));
    }
    painter.dispose();
  });
}
