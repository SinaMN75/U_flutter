import "dart:ui" as ui;

import "package:u/utilities.dart";

class WidgetToImageController {
  GlobalKey? _globalKey;

  void bind(GlobalKey globalKey) => _globalKey = globalKey;

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

class WidgetToImage extends StatefulWidget {
  const WidgetToImage({required this.child, required this.controller, super.key});

  final Widget child;
  final WidgetToImageController controller;

  @override
  State<WidgetToImage> createState() => _WidgetToImageState();
}

class _WidgetToImageState extends State<WidgetToImage> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.bind(_globalKey);
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(key: _globalKey, child: widget.child);
}
