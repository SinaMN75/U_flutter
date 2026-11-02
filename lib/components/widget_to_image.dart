import "dart:ui" as ui;

import "package:u/utilities.dart";

/// Captures a UWidgetToImage as PNG bytes.
class UWidgetToImageController {
  GlobalKey? _globalKey;

  /// Connects the controller (done by the widget).
  void bind(GlobalKey globalKey) => _globalKey = globalKey;

  /// PNG bytes of the widget. `final png = await controller.capture();`
  Future<Uint8List?> capture() async {
    if (_globalKey?.currentContext == null) return null;

    try {
      final RenderRepaintBoundary boundary = _globalKey!.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing widget: $e");
      return null;
    }
  }
}

/// Wraps a widget so it can be saved/shared as an image (receipts, cards). `UWidgetToImage(controller: c, child: receipt)`
class UWidgetToImage extends StatefulWidget {
  const UWidgetToImage({required this.child, required this.controller, super.key});

  /// PNG bytes of [child] drawn at [size], without showing it on screen; for print-sized output. [context] passes on its theme and text direction. Images must be loaded first (`precacheImage`). `await UWidgetToImage.render(poster, size: const Size(595, 842), context: context)`
  static Future<Uint8List?> render(Widget child, {required Size size, required BuildContext context, double pixelRatio = 3}) async {
    final RenderRepaintBoundary boundary = RenderRepaintBoundary();
    final RenderView view = RenderView(
      view: View.of(context),
      configuration: ViewConfiguration(logicalConstraints: BoxConstraints.tight(size), physicalConstraints: BoxConstraints.tight(size)),
      child: RenderPositionedBox(child: boundary),
    );
    final PipelineOwner pipeline = PipelineOwner()..rootNode = view;
    view.prepareInitialFrame();
    final FocusManager focus = FocusManager();
    final BuildOwner build = BuildOwner(focusManager: focus);
    final Element root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size, devicePixelRatio: 1),
        child: Directionality(textDirection: Directionality.of(context), child: InheritedTheme.captureAll(context, SizedBox.fromSize(size: size, child: Material(type: MaterialType.transparency, child: child)))),
      ),
    ).attachToRenderTree(build);

    void draw() {
      build
        ..buildScope(root)
        ..finalizeTree();
      pipeline
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
    }

    try {
      draw();
      // Whatever finishes on the next frames, such as an image from the cache, appears in a second pass.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      draw();
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return bytes?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error rendering widget: $e");
      return null;
    } finally {
      build
        ..lockState(root.unmount)
        ..finalizeTree();
      focus.dispose();
      pipeline.dispose();
    }
  }

  /// The widget inside.
  final Widget child;

  /// Controller to read or change it from code.
  final UWidgetToImageController controller;

  @override
  State<UWidgetToImage> createState() => _WidgetToImageState();
}

class _WidgetToImageState extends State<UWidgetToImage> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.bind(_globalKey);
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(key: _globalKey, child: widget.child);
}
