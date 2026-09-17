import "package:flutter_test/flutter_test.dart";
import "package:u/components/u_barcode.dart" as bc;
import "package:u/utilities.dart";

const List<int> kTotalCodewords = <int>[
  26, 44, 70, 100, 134, 172, 196, 242, 292, 346,
  404, 466, 532, 581, 655, 733, 815, 901, 991, 1085,
  1156, 1258, 1364, 1474, 1588, 1706, 1828, 1921, 2051, 2185,
  2323, 2465, 2611, 2761, 2876, 3034, 3196, 3362, 3532, 3706,
];

UBitMatrix renderMatrix(bc.Barcode2DMatrix matrix, {int scale = 4, int quiet = 4}) {
  final List<bool> pixels = matrix.pixels.toList();
  final int size = matrix.width;
  final int dimension = (size + quiet * 2) * scale;
  final UBitMatrix out = UBitMatrix(dimension, dimension);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      if (!pixels[y * size + x]) continue;
      for (int dy = 0; dy < scale; dy++) {
        for (int dx = 0; dx < scale; dx++) {
          out.set((x + quiet) * scale + dx, (y + quiet) * scale + dy);
        }
      }
    }
  }
  return out;
}

UGrayImage toGray(UBitMatrix matrix) {
  final Uint8List data = Uint8List(matrix.width * matrix.height);
  for (int y = 0; y < matrix.height; y++) {
    for (int x = 0; x < matrix.width; x++) {
      data[y * matrix.width + x] = matrix.get(x, y) ? 0 : 255;
    }
  }
  return UGrayImage(data, matrix.width, matrix.height);
}

UBitMatrix render2D(bc.Barcode2DMatrix matrix, {int scale = 4, int quiet = 4}) {
  final List<bool> pixels = matrix.pixels.toList();
  final int cols = matrix.width;
  final int rows = matrix.height;
  final int width = (cols + quiet * 2) * scale;
  final int height = (rows + quiet * 2) * scale;
  final UBitMatrix out = UBitMatrix(width, height);
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      if (!pixels[y * cols + x]) continue;
      for (int dy = 0; dy < scale; dy++) {
        for (int dx = 0; dx < scale; dx++) {
          out.set((x + quiet) * scale + dx, (y + quiet) * scale + dy);
        }
      }
    }
  }
  return out;
}

UBitMatrix render1D(bc.Barcode1D code, String data, {int scale = 3, int quiet = 220, int height = 60}) {
  final List<bc.BarcodeElement> elements = code.makeBytes(Uint8List.fromList(data.codeUnits), width: 1000, height: 1).toList();
  double maxRight = 0;
  for (final bc.BarcodeElement element in elements) {
    if (element.right > maxRight) maxRight = element.right;
  }
  final int width = (maxRight * scale).ceil() + quiet * 2;
  final UBitMatrix out = UBitMatrix(width, height);
  for (final bc.BarcodeElement element in elements) {
    if (element is! bc.BarcodeBar || !element.black) continue;
    final int left = (element.left * scale).round() + quiet;
    final int right = (element.right * scale).round() + quiet;
    for (int x = left; x < right; x++) {
      for (int y = 0; y < height; y++) {
        out.set(x, y);
      }
    }
  }
  return out;
}

void check(String label, UBitMatrix bits, UCodeFormat format, String expected) {
  final List<UCode> codes = UCodeReader.decodeBits(bits, UCodeScanOptions(formats: <UCodeFormat>[format], multiple: true));
  expect(codes, isNotEmpty, reason: "$label produced nothing");
  expect(codes.first.text, expected, reason: "$label mismatch");
}

void main() {
  test("QR version table is internally consistent", () {
    for (int v = 1; v <= 40; v++) {
      final UQrVersion version = UQrVersion.forNumber(v);
      expect(version.dimension, 17 + 4 * v, reason: "dimension v$v");
      for (int level = 0; level < 4; level++) {
        final UQrEcBlocks blocks = version.ecBlocks[level];
        int total = 0;
        for (final UQrEcb block in blocks.blocks) {
          total += block.count * (block.dataCodewords + blocks.ecCodewordsPerBlock);
        }
        expect(total, kTotalCodewords[v - 1], reason: "v$v level $level");
      }
    }
  });

  test("QR round trip across versions, levels and payloads", () {
    final List<String> payloads = <String>[
      "HELLO",
      "https://sinamn75.com/checkout?id=123456",
      "1234567890123456789012345678901234567890",
      "سلام دنیا",
      List<String>.filled(40, "ABCDEFGHIJ").join(),
    ];
    for (final bc.BarcodeQRCorrectionLevel level in bc.BarcodeQRCorrectionLevel.values) {
      for (final String payload in payloads) {
        final bc.Barcode2DMatrix matrix = bc.BarcodeQR(null, level).convert(Uint8List.fromList(utf8.encode(payload)));
        final UBitMatrix bits = renderMatrix(matrix);
        final List<UCode> codes = UCodeReader.decodeBits(bits, const UCodeScanOptions(formats: <UCodeFormat>[UCodeFormat.qr]));
        expect(codes, isNotEmpty, reason: "no decode for $payload @ $level");
        expect(codes.first.text, payload, reason: "mismatch for $payload @ $level");
      }
    }
  });

  test("QR decodes from a grayscale image with a quiet zone", () {
    final bc.Barcode2DMatrix matrix = const bc.BarcodeQR(null, bc.BarcodeQRCorrectionLevel.medium).convert(Uint8List.fromList(utf8.encode("U-PACKAGE-42")));
    final UGrayImage image = toGray(renderMatrix(matrix, scale: 6));
    final List<UCode> codes = UCodeReader.decode(image);
    expect(codes.single.text, "U-PACKAGE-42");
  });

  test("Code 128", () => check("code128", render1D(bc.Barcode.code128() as bc.Barcode1D, "U-POS-2026"), UCodeFormat.code128, "U-POS-2026"));

  test("Code 39", () => check("code39", render1D(bc.Barcode.code39() as bc.Barcode1D, "HELLO-39"), UCodeFormat.code39, "HELLO-39"));

  test("Code 93", () => check("code93", render1D(bc.Barcode.code93() as bc.Barcode1D, "CODE93TEST"), UCodeFormat.code93, "CODE93TEST"));

  test("Codabar", () => check("codabar", render1D(bc.Barcode.codabar() as bc.Barcode1D, "1234567"), UCodeFormat.codabar, "1234567"));

  test("ITF", () => check("itf", render1D(bc.Barcode.itf() as bc.Barcode1D, "12345678"), UCodeFormat.itf, "12345678"));

  test("EAN-13", () => check("ean13", render1D(bc.Barcode.ean13() as bc.Barcode1D, "5901234123457"), UCodeFormat.ean13, "5901234123457"));

  test("EAN-8", () => check("ean8", render1D(bc.Barcode.ean8() as bc.Barcode1D, "96385074"), UCodeFormat.ean8, "96385074"));

  test("UPC-A", () => check("upca", render1D(bc.Barcode.upcA() as bc.Barcode1D, "036000291452"), UCodeFormat.upcA, "036000291452"));

  test("Data Matrix", () {
    final bc.Barcode2DMatrix m = const bc.BarcodeDataMatrix().convert((bc.DataMatrixEncoder()..ascii("DM-TEST-123")).toBytes());
    check("datamatrix", render2D(m, scale: 6), UCodeFormat.dataMatrix, "DM-TEST-123");
  });

  test("Aztec", () {
    final bc.Barcode2DMatrix m = const bc.BarcodeAztec(33, 0).convert(Uint8List.fromList(utf8.encode("AZTEC-TEST-123")));
    check("aztec", render2D(m, scale: 6), UCodeFormat.aztec, "AZTEC-TEST-123");
  });

  test("PDF417", () {
    final bc.Barcode2DMatrix m = const bc.BarcodePDF417(bc.Pdf417SecurityLevel.level2, 2, 3).convert(Uint8List.fromList(utf8.encode("PDF417-TEST-123")));
    final List<bool> pixels = m.pixels.toList();
    final int cols = m.width;
    final int rows = m.height;
    const int scale = 3;
    const int rowHeight = 9;
    const int quiet = 6;
    final UBitMatrix out = UBitMatrix((cols + quiet * 2) * scale, rows * rowHeight + quiet * 2 * scale);
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (!pixels[y * cols + x]) continue;
        for (int dy = 0; dy < rowHeight; dy++) {
          for (int dx = 0; dx < scale; dx++) {
            out.set((x + quiet) * scale + dx, quiet * scale + y * rowHeight + dy);
          }
        }
      }
    }
    check("pdf417", out, UCodeFormat.pdf417, "PDF417-TEST-123");
  });
}
