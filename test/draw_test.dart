import "package:flutter_test/flutter_test.dart";
import "package:u/utilities.dart";

Widget _app(Widget child) => MaterialApp(
  navigatorKey: navigatorKey,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Future<void> _drag(WidgetTester tester, Offset from, Offset to, {int steps = 12}) async {
  final TestGesture gesture = await tester.startGesture(from);
  for (int i = 1; i <= steps; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / steps)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump();
}

/// Hosts a layer bound to an annotation controller, like the viewers do.
class _Host extends StatelessWidget {
  const _Host({required this.markup, required this.tools});

  final UDocAnnotationController markup;
  final UDocDrawController tools;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 400,
      height: 500,
      child: ListenableBuilder(
        listenable: markup,
        builder: (BuildContext context, Widget? child) => UDocShapeLayer(
          shapes: markup.shapesOn(0),
          tools: tools,
          prepare: (UDocShape shape) => shape.placed(pageIndex: 0),
          onAdd: markup.addShape,
          onUpdate: markup.updateShape,
          onRemove: markup.removeShape,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("shapes survive export / import and undo", (WidgetTester tester) async {
    await tester.pumpWidget(_app(const SizedBox()));
    final UDocAnnotationController markup = UDocAnnotationController();
    for (final UDocShapeKind kind in UDocShapeKind.values) {
      markup.addShape(
        UDocShape.create(
          kind: kind,
          pageIndex: 2,
          points: const <Offset>[Offset(0.1, 0.2), Offset(0.3, 0.25), Offset(0.4, 0.5)],
          strokeColor: const Color(0xFF1E88E5),
          fillColor: kind == UDocShapeKind.ellipse ? const Color(0x401E88E5) : null,
          dashed: kind == UDocShapeKind.rectangle,
          text: kind == UDocShapeKind.textBox ? "سلام دنیا" : "",
          startMs: 1000,
          endMs: 6000,
        ),
      );
    }
    final String data = markup.export();
    final UDocAnnotationController restored = UDocAnnotationController(initialData: data);
    expect(restored.shapes.length, UDocShapeKind.values.length);
    final UDocShape box = restored.shapes.firstWhere((UDocShape shape) => shape.kind == UDocShapeKind.textBox);
    expect(box.text, "سلام دنیا");
    expect(box.pageIndex, 2);
    expect(box.points.length, 3);
    expect(box.visibleAt(const Duration(seconds: 3)), isTrue);
    expect(box.visibleAt(const Duration(seconds: 8)), isFalse);
    expect(restored.shapes.firstWhere((UDocShape shape) => shape.kind == UDocShapeKind.ellipse).fillColor, const Color(0x401E88E5));
    expect(restored.shapes.firstWhere((UDocShape shape) => shape.kind == UDocShapeKind.rectangle).dashed, isTrue);
    expect(restored.shapesOn(2).length, UDocShapeKind.values.length);
    expect(restored.toMarkdown(), contains("سلام دنیا"));

    // Rapid moves of one shape collapse into a single undo step.
    final UDocShape first = restored.shapes.first;
    for (int i = 1; i <= 5; i++) {
      restored.updateShape(first.translated(Offset(0.01 * i, 0)));
    }
    restored.undo();
    expect(restored.shapeById(first.id)!.points.first, first.points.first);
    restored.redo();
    expect(restored.shapeById(first.id)!.points.first.dx, closeTo(first.points.first.dx + 0.05, 1e-6));

    restored.clearShapes(pageIndex: 2);
    expect(restored.shapes, isEmpty);
    restored.undo();
    expect(restored.shapes.length, UDocShapeKind.values.length);
    markup.dispose();
    restored.dispose();
  });

  testWidgets("draw, fill, type, move, resize and erase on a shape layer", (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    final UDocAnnotationController markup = UDocAnnotationController();
    final UDocDrawController tools = UDocDrawController();
    await tester.pumpWidget(_app(_Host(markup: markup, tools: tools)));
    final Offset origin = tester.getTopLeft(find.byType(UDocShapeLayer));

    // Pen stroke.
    tools.tool = UDocDrawTool.pen;
    await tester.pump();
    await _drag(tester, origin + const Offset(20, 20), origin + const Offset(200, 90));
    expect(markup.shapes.single.kind, UDocShapeKind.pen);
    expect(markup.shapes.single.points.length, greaterThan(4));
    expect(markup.shapes.single.pageIndex, 0);

    // Filled ellipse with constrained proportions → a circle.
    tools
      ..tool = UDocDrawTool.ellipse
      ..fillColor = const Color(0x40FF0000)
      ..constrain = true;
    await tester.pump();
    await _drag(tester, origin + const Offset(50, 150), origin + const Offset(150, 190));
    final UDocShape circle = markup.shapes.last;
    expect(circle.kind, UDocShapeKind.ellipse);
    expect(circle.fillColor, const Color(0x40FF0000));
    final Rect bounds = circle.bounds;
    expect(bounds.width * 400, closeTo(bounds.height * 500, 1));

    // Area highlight and an unfilled rectangle.
    tools
      ..constrain = false
      ..fillColor = null
      ..tool = UDocDrawTool.areaHighlight;
    await tester.pump();
    await _drag(tester, origin + const Offset(20, 300), origin + const Offset(300, 330));
    expect(markup.shapes.last.kind, UDocShapeKind.areaHighlight);
    tools.tool = UDocDrawTool.rectangle;
    await tester.pump();
    await _drag(tester, origin + const Offset(220, 380), origin + const Offset(360, 470));
    expect(markup.shapes.last.kind, UDocShapeKind.rectangle);
    expect(markup.shapes.last.fillColor, isNull);

    // Text box: tap, type inline, tap outside to commit.
    tools.tool = UDocDrawTool.textBox;
    await tester.pump();
    await tester.tapAt(origin + const Offset(30, 220));
    await tester.pump();
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), "متن روی صفحه");
    await tester.pump();
    tools.tool = UDocDrawTool.select;
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    final UDocShape text = markup.shapes.last;
    expect(text.kind, UDocShapeKind.textBox);
    expect(text.text, "متن روی صفحه");
    expect(find.byType(TextField), findsNothing);

    // Select + move the rectangle.
    final UDocShape rectangle = markup.shapes.firstWhere((UDocShape shape) => shape.kind == UDocShapeKind.rectangle);
    await tester.tapAt(origin + const Offset(220, 420));
    await tester.pump();
    expect(tools.selectedId, rectangle.id);
    await _drag(tester, origin + const Offset(221, 420), origin + const Offset(181, 400));
    final UDocShape moved = markup.shapeById(rectangle.id)!;
    expect(moved.bounds.left * 400, closeTo(180, 2));

    // Resize from the bottom-right handle.
    final Offset corner = origin + Offset(moved.bounds.right * 400, moved.bounds.bottom * 500);
    await _drag(tester, corner, corner + const Offset(30, 20));
    expect(markup.shapeById(rectangle.id)!.bounds.width * 400, closeTo(moved.bounds.width * 400 + 30, 3));

    // Erase the pen stroke.
    final int before = markup.shapes.length;
    tools.tool = UDocDrawTool.eraser;
    await tester.pump();
    await _drag(tester, origin + const Offset(100, 10), origin + const Offset(100, 110));
    expect(markup.shapes.length, before - 1);
    expect(markup.shapes.any((UDocShape shape) => shape.kind == UDocShapeKind.pen), isFalse);
    expect(tester.takeException(), isNull);

    // Everything is in the saved string.
    final UDocAnnotationController restored = UDocAnnotationController(initialData: markup.export());
    expect(restored.shapes.map((UDocShape shape) => shape.kind), markup.shapes.map((UDocShape shape) => shape.kind));
    await tester.pumpWidget(const SizedBox.shrink());
    markup.dispose();
    restored.dispose();
    tools.dispose();
  });

  testWidgets("PDF viewer: draw on a page, reload from the saved string", (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    final Uint8List bytes = File("example/assets/docs/sample_fa_en.pdf").readAsBytesSync();
    final GlobalKey<UPdfViewerState> key = GlobalKey<UPdfViewerState>();
    String synced = "";
    await tester.pumpWidget(_app(UPdfViewer(key: key, bytes: bytes, persistAnnotations: false, onAnnotationsChanged: (String data) => synced = data)));
    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 40));
    }
    final UPdfViewerState viewer = key.currentState!;
    expect(viewer.controller.value.isReady, isTrue);

    await tester.tap(find.byTooltip(U.s.draw).first);
    await tester.pump();
    expect(viewer.drawing.tool, UDocDrawTool.pen);
    expect(find.byType(UDocDrawToolbar), findsOneWidget);

    final Finder firstLayer = find.byKey(const ValueKey<String>("shapes0"));
    final Offset page = tester.getTopLeft(firstLayer);
    await _drag(tester, page + const Offset(60, 200), page + const Offset(260, 260));
    viewer.drawing.tool = UDocDrawTool.rectangle;
    await tester.pump();
    await _drag(tester, page + const Offset(80, 320), page + const Offset(280, 400));
    expect(viewer.annotations.shapesOn(0).length, 2);
    await tester.pump(const Duration(milliseconds: 500));
    expect(synced, isNotEmpty);

    // Close drawing → the page scrolls and selects text again, shapes stay visible.
    await tester.tap(find.byTooltip(U.s.done));
    await tester.pump();
    expect(viewer.drawing.isActive, isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    final GlobalKey<UPdfViewerState> reloaded = GlobalKey<UPdfViewerState>();
    await tester.pumpWidget(_app(UPdfViewer(key: reloaded, bytes: bytes, persistAnnotations: false, annotationData: synced)));
    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(reloaded.currentState!.annotations.shapesOn(0).map((UDocShape shape) => shape.kind), <UDocShapeKind>[UDocShapeKind.pen, UDocShapeKind.rectangle]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets("video: draw over the paused frame, time-stamped and saved with the notes", (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel("u/media"), (MethodCall call) async => call.method == "create" ? 1 : null);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel("u/media/events/1"), (MethodCall call) async => null);
    final UMediaController controller = UMediaController();
    final UMediaNotesController notes = UMediaNotesController();
    final UDocDrawController tools = UDocDrawController();
    await tester.pumpWidget(_app(UVideoWithNotes(controller: controller, notes: notes, title: "Draw", drawController: tools)));
    await tester.runAsync(() => controller.open(UMediaSource.network("https://example.com/a.mp4")));
    for (int i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 40));
    }

    await tester.tap(find.byTooltip(U.s.drawOnVideo).first);
    await tester.pump();
    expect(tools.tool, UDocDrawTool.pen);
    expect(find.byType(UDocDrawToolbar), findsOneWidget);
    expect(find.byTooltip(U.s.addTimestampNote), findsNothing, reason: "controls hide while drawing");

    tools
      ..videoDuration = const Duration(seconds: 5)
      ..tool = UDocDrawTool.arrow;
    await tester.pump();
    final Rect video = tester.getRect(find.byType(UDocShapeLayer));
    await _drag(tester, video.center, video.center + const Offset(120, -60));
    expect(notes.shapes.single.kind, UDocShapeKind.arrow);
    expect(notes.shapes.single.startMs, 0);
    expect(notes.shapes.single.endMs, 5000);
    expect(notes.shapesAt(const Duration(seconds: 2)), hasLength(1));
    expect(notes.shapesAt(const Duration(seconds: 9)), isEmpty);
    expect(notes.markers.length, 1);

    await tester.tap(find.byTooltip(U.s.done));
    await tester.pump();
    expect(tools.isActive, isFalse);
    expect(tester.takeException(), isNull);

    final UMediaNotesController restored = UMediaNotesController(initialData: notes.export());
    expect(restored.shapes.single.endMs, 5000);
    restored.undo();
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    notes.dispose();
    restored.dispose();
    tools.dispose();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets("toolbar: shapes button selects the last shape, then lists every shape", (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 300));
    final UDocDrawController tools = UDocDrawController();
    await tester.pumpWidget(_app(Column(children: <Widget>[SizedBox(height: 52, child: UDocDrawToolbar(tools: tools, onDone: () {}))])));
    final Finder shapes = find.byTooltip("${U.s.rectangle} · ${U.s.shapes}");
    expect(shapes, findsOneWidget);
    expect(tester.getRect(find.byTooltip(U.s.erase)).right, lessThanOrEqualTo(700), reason: "every tool fits a 700px bar");

    await tester.tap(shapes);
    await tester.pumpAndSettle();
    expect(tools.tool, UDocDrawTool.rectangle);
    await tester.tap(shapes);
    await tester.pumpAndSettle();
    expect(find.text(U.s.ellipse), findsOneWidget);
    await tester.tap(find.text(U.s.ellipse));
    await tester.pumpAndSettle();
    expect(tools.tool, UDocDrawTool.ellipse);
    expect(find.byTooltip("${U.s.ellipse} · ${U.s.shapes}"), findsOneWidget);

    // Fill menu: light fill, then none.
    await tester.tap(find.byTooltip(U.s.fill));
    await tester.pumpAndSettle();
    await tester.tap(find.text(U.s.lightFill));
    await tester.pumpAndSettle();
    expect(tools.fillColor, isNotNull);
    await tester.tap(find.byTooltip(U.s.fill));
    await tester.pumpAndSettle();
    await tester.tap(find.text(U.s.noFill));
    await tester.pumpAndSettle();
    expect(tools.fillColor, isNull);
    tools.dispose();
  });
}
