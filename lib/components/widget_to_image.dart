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
