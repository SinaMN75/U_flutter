import "package:u/utilities.dart";

class UPdfViewer extends StatelessWidget {
  const UPdfViewer({this.base64Pdf, this.bytes, this.url, this.filePath, super.key}) : assert(base64Pdf != null || bytes != null || url != null || filePath != null, "Provide one PDF source");

  final String? base64Pdf;
  final Uint8List? bytes;
  final String? url;
  final String? filePath;

  @override
  Widget build(BuildContext context) {
    if (bytes != null) return SfPdfViewer.memory(bytes!);
    if (base64Pdf != null) return SfPdfViewer.memory(base64Pdf!.toBytesFromBase64());
    if (url != null) return SfPdfViewer.network(url!);
    return SfPdfViewer.file(File(filePath!));
  }
}

abstract class UPdf {
  static Future<void> show({String? base64Pdf, Uint8List? bytes, String? url, String? filePath}) => UNavigator.bottomSheet(
    UScaffold(
      appBar: AppBar(),
      body: SizedBox(
        width: MediaQuery.sizeOf(navigatorKey.currentContext!).width,
        child: UPdfViewer(base64Pdf: base64Pdf, bytes: bytes, url: url, filePath: filePath),
      ),
    ),
  );
}
