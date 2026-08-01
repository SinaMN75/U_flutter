import "package:flutter/material.dart";
import "package:syncfusion_flutter_barcodes/barcodes.dart";

enum UBarcodeType {
  qrCode,
  dataMatrix,
  code128,
  code128A,
  code128B,
  code128C,
  code39,
  code39Extended,
  code93,
  codabar,
  ean8,
  ean13,
  upcA,
  upcE,
}

enum UErrorCorrectionLevel {
  low,
  medium,
  quartile,
  high,
}

class UBarcode extends StatefulWidget {
  const UBarcode({
    required this.value,
    this.type = UBarcodeType.qrCode,
    this.barColor,
    this.backgroundColor,
    this.showValue = false,
    this.textSpacing = 15.0,
    this.module,
    this.errorCorrectionLevel,
    this.qrCodeVersion,
    this.enableCheckSum,
    super.key,
  });

  /// The value to encode in the barcode.
  final String value;

  /// The type of barcode to generate.
  final UBarcodeType type;

  /// The color of the bars or modules in the barcode.
  final Color? barColor;

  /// The background color of the barcode.
  final Color? backgroundColor;

  /// Whether to display the encoded value below the barcode.
  final bool showValue;

  /// The spacing between the barcode and the text (if showValue is true).
  final double textSpacing;

  /// The size of the smallest line or dot in the barcode.
  final int? module;

  /// The error correction level for QR codes (applicable only for QRCode type).
  final UErrorCorrectionLevel? errorCorrectionLevel;

  /// The version for QR codes (1-40, or null/0 for auto).
  final int? qrCodeVersion;

  /// Whether to enable checksum for Code39, Code39Extended, and Code11.
  final bool? enableCheckSum;

  @override
  State<UBarcode> createState() => _UBarcodeState();
}

class _UBarcodeState extends State<UBarcode> {
  late Symbology symbology;

  @override
  void initState() {
    super.initState();
    _initializeSymbology();
  }

  @override
  void didUpdateWidget(covariant UBarcode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != oldWidget.type ||
        widget.errorCorrectionLevel != oldWidget.errorCorrectionLevel ||
        widget.qrCodeVersion != oldWidget.qrCodeVersion ||
        widget.enableCheckSum != oldWidget.enableCheckSum ||
        widget.module != oldWidget.module) {
      _initializeSymbology();
    }
  }

  void _initializeSymbology() {
    switch (widget.type) {
      case UBarcodeType.qrCode:
        symbology = QRCode(
          errorCorrectionLevel: widget.errorCorrectionLevel != null ? _mapErrorCorrectionLevel(widget.errorCorrectionLevel!) : ErrorCorrectionLevel.low,
          inputMode: QRInputMode.alphaNumeric,
          codeVersion: widget.qrCodeVersion != null && widget.qrCodeVersion! > 0 && widget.qrCodeVersion! <= 40 ? QRCodeVersion.values[widget.qrCodeVersion! - 1] : QRCodeVersion.auto,
          module: widget.module,
        );
        break;
      case UBarcodeType.dataMatrix:
        symbology = DataMatrix(module: widget.module);
        break;
      case UBarcodeType.code128:
        symbology = Code128(module: widget.module);
        break;
      case UBarcodeType.code128A:
        symbology = Code128A(module: widget.module);
        break;
      case UBarcodeType.code128B:
        symbology = Code128B(module: widget.module);
        break;
      case UBarcodeType.code128C:
        symbology = Code128C(module: widget.module);
        break;
      case UBarcodeType.code39:
        symbology = Code39(enableCheckSum: widget.enableCheckSum ?? false, module: widget.module);
        break;
      case UBarcodeType.code39Extended:
        symbology = Code39Extended(enableCheckSum: widget.enableCheckSum ?? false, module: widget.module);
        break;
      case UBarcodeType.code93:
        symbology = Code93(module: widget.module);
        break;
      case UBarcodeType.codabar:
        symbology = Codabar(module: widget.module);
        break;
      case UBarcodeType.ean8:
        symbology = EAN8(module: widget.module);
        break;
      case UBarcodeType.ean13:
        symbology = EAN13(module: widget.module);
        break;
      case UBarcodeType.upcA:
        symbology = UPCA(module: widget.module);
        break;
      case UBarcodeType.upcE:
        symbology = UPCE(module: widget.module);
        break;
    }
  }

  ErrorCorrectionLevel _mapErrorCorrectionLevel(UErrorCorrectionLevel level) {
    switch (level) {
      case UErrorCorrectionLevel.low:
        return ErrorCorrectionLevel.low;
      case UErrorCorrectionLevel.medium:
        return ErrorCorrectionLevel.medium;
      case UErrorCorrectionLevel.quartile:
        return ErrorCorrectionLevel.quartile;
      case UErrorCorrectionLevel.high:
        return ErrorCorrectionLevel.high;
    }
  }

  @override
  Widget build(BuildContext context) => SfBarcodeGenerator(
    value: widget.value,
    symbology: symbology,
    barColor: widget.barColor,
    backgroundColor: widget.backgroundColor,
    showValue: widget.showValue,
    textSpacing: widget.textSpacing,
  );
}

class DemoBarcodes extends StatelessWidget {
  const DemoBarcodes({super.key});

  @override
  Widget build(BuildContext context) {
    const String sampleValue = "123456789";
    const String qrSampleValue = "https://example.com";

    return Scaffold(
      appBar: AppBar(title: const Text("Barcode Demo")),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("QR Code", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: UBarcode(
                value: qrSampleValue,
                barColor: Colors.blue,
                backgroundColor: Colors.white,
                showValue: true,
                textSpacing: 10,
                module: 2,
                errorCorrectionLevel: UErrorCorrectionLevel.high,
                qrCodeVersion: 5,
              ),
            ),
            SizedBox(height: 20),
            Text("Data Matrix", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: UBarcode(value: sampleValue, type: UBarcodeType.dataMatrix, barColor: Colors.black, showValue: true, module: 3),
            ),
            SizedBox(height: 20),
            Text("Code 128", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: sampleValue, type: UBarcodeType.code128, barColor: Colors.green, showValue: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("Code 128A", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "ABC123", type: UBarcodeType.code128A, barColor: Colors.red, showValue: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("Code 128B", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "abc123", type: UBarcodeType.code128B, barColor: Colors.blue, showValue: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("Code 128C", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "123456", type: UBarcodeType.code128C, barColor: Colors.purple, showValue: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("Code 39", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "ABC123", type: UBarcodeType.code39, barColor: Colors.orange, showValue: true, enableCheckSum: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("Code 39 Extended", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "abc123", type: UBarcodeType.code39Extended, barColor: Colors.teal, showValue: true, enableCheckSum: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("Code 93", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "TEST93", type: UBarcodeType.code93, barColor: Colors.brown, showValue: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("Codabar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "A123456A", type: UBarcodeType.codabar, barColor: Colors.cyan, showValue: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("EAN-8", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "12345670", type: UBarcodeType.ean8, barColor: Colors.black, showValue: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("EAN-13", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "123456789012", type: UBarcodeType.ean13, barColor: Colors.green, showValue: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("UPC-A", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "123456789012", type: UBarcodeType.upcA, barColor: Colors.blue, showValue: true, module: 2),
            ),
            SizedBox(height: 20),
            Text("UPC-E", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: UBarcode(value: "0123456", type: UBarcodeType.upcE, barColor: Colors.red, showValue: true, module: 2),
            ),
          ],
        ),
      ),
    );
  }
}
