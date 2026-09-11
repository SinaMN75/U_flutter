import "dart:ui" as ui;

import "package:u/utilities.dart";

class UAgreementViewer extends StatefulWidget {
  const UAgreementViewer({
    required this.html,
    super.key,
    this.title,
    this.fileName = "agreement.pdf",
    this.acceptTitle,
    this.submitTitle,
    this.onAccept,
  });

  final String html;
  final String? title;
  final String fileName;
  final String? acceptTitle;
  final String? submitTitle;
  final VoidCallback? onAccept;

  @override
  State<UAgreementViewer> createState() => _UAgreementViewerState();
}

class _UAgreementViewerState extends State<UAgreementViewer> {
  final WidgetToImageController capture = WidgetToImageController();
  bool accepted = false;

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(widget.title ?? U.s.agreement),
      actions: <Widget>[
        if (!kIsWeb) IconButton(icon: const Icon(Icons.download_rounded), tooltip: U.s.downloadPdf, onPressed: download),
      ],
    ),
    bottomNavigationBar: widget.onAccept == null ? null : acceptBar(),
    body: SingleChildScrollView(
      child: WidgetToImage(
        controller: capture,
        child: UContainer(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: UHtmlView(
            html: widget.html,
            selectable: true,
            textDirection: TextDirection.rtl,
            textStyle: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.9),
            onImageTap: (String url) {},
            imageBuilder: (BuildContext context, String url, String? alt, double? width) => UImage(url, width: width ?? 140),
          ),
        ),
      ),
    ),
  );

  Widget acceptBar() => UColumn(
    mainAxisSize: MainAxisSize.min,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    children: <Widget>[
      CheckboxListTile(
        value: accepted,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: UTextBodyMedium(widget.acceptTitle ?? U.s.iHaveReadAndAcceptTheAgreement),
        onChanged: (bool? value) => setState(() => accepted = value ?? false),
      ),
      UButton(
        title: widget.submitTitle ?? U.s.submitRequest,
        fullWidth: true,
        onTap: () {
          if (!accepted) {
            UToast.error(message: U.s.youHaveToAcceptTheAgreementToContinue);
            return;
          }
          widget.onAccept!();
        },
      ),
    ],
  );

  Future<void> download() async {
    ULoading.show();
    final Uint8List? image = await capture.capture(pixelRatio: 2);
    if (image == null) {
      ULoading.dismiss();
      UToast.error(message: U.s.somethingWentWrong);
      return;
    }
    final Uint8List? pdf = await UPdfOps.fromImages(await paginate(image));
    ULoading.dismiss();
    if (pdf == null) {
      UToast.error(message: U.s.somethingWentWrong);
      return;
    }
    await UShare.bytes(bytes: pdf, fileName: widget.fileName, mimeType: "application/pdf");
  }

  Future<List<Uint8List>> paginate(Uint8List png) async {
    final ui.Codec codec = await ui.instantiateImageCodec(png);
    final ui.Image source = (await codec.getNextFrame()).image;
    final int pageHeight = (source.width * 1.4142).round();
    if (source.height <= pageHeight) {
      source.dispose();
      return <Uint8List>[png];
    }

    final List<Uint8List> pages = <Uint8List>[];
    for (int top = 0; top < source.height; top += pageHeight) {
      final int height = min(pageHeight, source.height - top);
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas(recorder)
        ..drawRect(Rect.fromLTWH(0, 0, source.width.toDouble(), height.toDouble()), Paint()..color = Colors.white)
        ..drawImageRect(
          source,
          Rect.fromLTWH(0, top.toDouble(), source.width.toDouble(), height.toDouble()),
          Rect.fromLTWH(0, 0, source.width.toDouble(), height.toDouble()),
          Paint(),
        );
      final ui.Image page = await recorder.endRecording().toImage(source.width, height);
      final ByteData? data = await page.toByteData(format: ui.ImageByteFormat.png);
      page.dispose();
      if (data != null) pages.add(data.buffer.asUint8List());
    }
    source.dispose();
    return pages;
  }
}
