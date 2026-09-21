import "package:u/components/u_barcode.dart" as bc;
import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";
import "camera_studio_page.dart";
import "scanner_studio_page.dart";

/// Exercises the whole native camera + scanning stack of the `u` plugin.
///
/// The decoder self-test at the top needs no camera at all, so it is the
/// fastest way to confirm the engine works on a machine with no webcam.
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _supported = false;
  UCameraPermissionState _permission = const UCameraPermissionState();
  List<UCameraDevice> _devices = <UCameraDevice>[];
  bool _loading = true;

  List<_DecoderCheck> _checks = <_DecoderCheck>[];
  bool _running = false;

  List<UCode> _imageCodes = <UCode>[];
  String? _imageName;

  String _generated = "U-PLUGIN-2026";
  UBarcodeType _generatedType = UBarcodeType.qrCode;

  @override
  void initState() {
    super.initState();
    unawaited(_probe());
  }

  Future<void> _probe() async {
    final bool supported = await UCameraController.isSupported();
    final UCameraPermissionState permission = await UCameraController.permissionStatus();
    final List<UCameraDevice> devices = supported ? await UCameraController.availableCameras() : <UCameraDevice>[];
    if (!mounted) return;
    setState(() {
      _supported = supported;
      _permission = permission;
      _devices = devices;
      _loading = false;
    });
  }

  Future<void> _requestPermission() async {
    final UCameraPermissionState permission = await UCameraController.requestPermission(audio: true);
    if (!mounted) return;
    setState(() => _permission = permission);
    if (permission.isGranted) {
      await _probe();
    } else if (permission.isPermanentlyDenied) {
      await UCameraController.openSettings();
    }
  }

  // ---------------------------------------------------------------------------
  // Decoder self-test: generate every symbology, then read it back.
  // ---------------------------------------------------------------------------

  Future<void> _runSelfTest() async {
    setState(() {
      _running = true;
      _checks = <_DecoderCheck>[];
    });

    final List<_DecoderCheck> results = <_DecoderCheck>[];
    for (final _SelfTestCase testCase in _selfTestCases) {
      final Stopwatch stopwatch = Stopwatch()..start();
      String? decoded;
      String? failure;
      try {
        final UBitMatrix bits = testCase.render();
        final List<UCode> codes = UCodeReader.decodeBits(bits, UCodeScanOptions(formats: <UCodeFormat>[testCase.format], multiple: true));
        decoded = codes.isEmpty ? null : codes.first.text;
      } catch (error) {
        failure = error.toString();
      }
      stopwatch.stop();
      results.add(
        _DecoderCheck(
          format: testCase.format,
          expected: testCase.payload,
          decoded: decoded,
          micros: stopwatch.elapsedMicroseconds,
          failure: failure,
        ),
      );
      if (!mounted) return;
      setState(() => _checks = List<_DecoderCheck>.from(results));
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    if (!mounted) return;
    setState(() => _running = false);
    final int passed = results.where((_DecoderCheck check) => check.passed).length;
    if (passed == results.length) {
      UToast.success(message: "All ${results.length} symbologies decoded");
    } else {
      UToast.error(message: "${results.length - passed} of ${results.length} failed");
    }
  }

  // ---------------------------------------------------------------------------
  // Decode an existing image
  // ---------------------------------------------------------------------------

  Future<void> _decodeFromFile() async {
    final UFileData? file = await UFile.pickFile(fileType: FileType.image);
    if (file == null) return;
    ULoading.show();
    final List<UCode> codes = await UCameraController.analyzeImage(
      path: file.path,
      bytes: file.bytes,
      options: const UCodeScanOptions(multiple: true, tryInvert: true),
    );
    ULoading.dismiss();
    if (!mounted) return;
    setState(() {
      _imageCodes = codes;
      _imageName = file.name ?? "image";
    });
    if (codes.isEmpty) UToast.warning(message: "Nothing decoded in that image");
  }

  // ---------------------------------------------------------------------------
  // One-call helpers
  // ---------------------------------------------------------------------------

  Future<void> _quickPhoto() async {
    final UFileData? file = await UCamera.takePhoto();
    if (file == null || !mounted) return;
    await UNavigator.dialog<void>(
      UColumn(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const UTextTitleMedium("UCamera.takePhoto()", fontWeight: FontWeight.w700),
          if (file.hasBytes) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(file.bytes!, height: 240)),
          UTextBodySmall("${file.extension} · ${UCameraUtils.formatBytes(file.sizeInBytes ?? 0)}"),
        ],
      ),
    );
  }

  Future<void> _quickVideo() async {
    final UFileData? file = await UCamera.recordVideo(
      options: const UCameraOptions(mode: UCameraMode.video, videoMaxDuration: Duration(seconds: 15)),
    );
    if (file == null || !mounted) return;
    UToast.success(message: "Recorded ${file.name ?? file.path ?? ""}");
  }

  Future<void> _quickMultiPhoto() async {
    final List<UFileData> files = await UCamera.takePhotos(maxCount: 3);
    if (files.isEmpty || !mounted) return;
    UToast.info(message: "Captured ${files.length} photo(s)");
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GalleryPage(
      title: "Camera & scanning",
      intro:
          "The native camera lives on the u/camera channel: Camera2 on Android, AVFoundation on "
          "iOS and macOS, Media Foundation on Windows, V4L2 on Linux and getUserMedia on the web. "
          "Barcode decoding is pure Dart, so there is no ML Kit, no downloaded model and no extra "
          "megabytes in the binary. Start with the self-test — it needs no camera.",
      sections: <Widget>[
        DemoSection(
          title: "1 · Platform support",
          description:
              "Whether this build can open a camera at all, the current permission state, and every "
              "capture device the OS reports. On desktop the list is your webcams; on a phone it is "
              "each physical and logical lens.",
          code: r'''
final bool ok = await UCameraController.isSupported();
final UCameraPermissionState p = await UCameraController.requestPermission(audio: true);
final List<UCameraDevice> devices = await UCameraController.availableCameras();''',
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : UColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    _fact("Camera available", _supported ? "yes" : "no", good: _supported),
                    _fact("Camera permission", _permission.camera.name, good: _permission.isGranted),
                    _fact("Microphone permission", _permission.microphone.name, good: _permission.microphone == UCameraPermission.granted),
                    _fact("Devices found", "${_devices.length}", good: _devices.isNotEmpty),
                    if (_devices.isNotEmpty) const SizedBox(height: 4),
                    ..._devices.map(
                      (UCameraDevice device) => UContainer(
                        color: scheme.surfaceContainerHighest,
                        radius: 10,
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        child: UColumn(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: <Widget>[
                            UTextLabelLarge("${device.name} · ${device.facing.name}", fontWeight: FontWeight.w700),
                            UTextBodySmall(
                              "lens ${device.lens.name} · sensor ${device.sensorOrientation}° · zoom "
                              "${device.minZoom.toStringAsFixed(1)}-${device.maxZoom.toStringAsFixed(1)}x"
                              "${device.hasFlash ? " · flash" : ""}${device.isLogical ? " · logical" : ""}",
                              color: scheme.onSurfaceVariant,
                            ),
                            if (device.largestFormat != null)
                              UTextBodySmall("max ${device.largestFormat}", color: scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    URow(
                      spacing: 8,
                      children: <Widget>[
                        UButton(title: "Request permission", icon: const Icon(Icons.lock_open, size: 18), onTap: () => unawaited(_requestPermission())),
                        UButton(type: UButtonType.outlined, title: "Refresh", icon: const Icon(Icons.refresh, size: 18), onTap: () => unawaited(_probe())),
                      ],
                    ),
                  ],
                ),
        ),

        DemoSection(
          title: "2 · Decoder self-test (no camera needed)",
          description:
              "Generates one symbol per supported symbology with the bundled generator, rasterises it, "
              "and reads it back with the Dart engine. Green means encode and decode agree exactly. "
              "This is the quickest proof the scanner works on a platform before you point it at anything.",
          code: r'''
final UBitMatrix bits = /* rasterised barcode */;
final List<UCode> codes = UCodeReader.decodeBits(
  bits,
  const UCodeScanOptions(formats: <UCodeFormat>[UCodeFormat.qr]),
);''',
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: <Widget>[
              URow(
                spacing: 8,
                children: <Widget>[
                  UButton(
                    title: _running ? "Running..." : "Run self-test",
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    onTap: _running ? null : () => unawaited(_runSelfTest()),
                  ),
                  if (_checks.isNotEmpty)
                    UTextLabelLarge(
                      "${_checks.where((_DecoderCheck c) => c.passed).length}/${_checks.length} passed",
                      fontWeight: FontWeight.w700,
                      color: _checks.every((_DecoderCheck c) => c.passed) ? scheme.primary : scheme.error,
                    ),
                ],
              ),
              ..._checks.map((_DecoderCheck check) => _checkRow(check, scheme)),
            ],
          ),
        ),

        DemoSection(
          title: "3 · Live camera studio",
          description:
              "A full preview with every control the device exposes: torch, zoom, exposure, tap-to-focus, "
              "manual ISO and shutter, white balance, stabilisation, HDR, orientation lock, photo, "
              "snapshot and video recording. Controls the hardware does not support are hidden.",
          code: r'''
final UCameraController controller = UCameraController(
  config: const UCameraConfig(resolution: UCameraResolution.veryHigh, imageStream: true),
);
await controller.initialize();
UCameraPreview(controller: controller);''',
          child: UButton(
            fullWidth: true,
            title: "Open camera studio",
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            onTap: () => UNavigator.push<void>(const CameraStudioPage()),
          ),
        ),

        DemoSection(
          title: "4 · Live scanner",
          description:
              "UScanner with the tracking overlay on: every detected symbol is outlined live and listed "
              "with its format, payload type and parsed fields. Try a QR code, a product barcode and a "
              "boarding-pass PDF417.",
          code: r'''
UScanner(
  formats: const <UCodeFormat>[UCodeFormat.qr, UCodeFormat.ean13],
  showTrackingBoxes: true,
  singleScan: false,
  onCodes: (List<UCode> codes) => print(codes.first.text),
);''',
          child: URow(
            spacing: 8,
            children: <Widget>[
              UButton(
                title: "Open scanner",
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                onTap: () => UNavigator.push<void>(const ScannerStudioPage()),
              ),
              UButton(
                type: UButtonType.outlined,
                title: "Quick scan",
                onTap: () async {
                  final String? value = await UScannerPage.open(showGalleryButton: true);
                  if (value != null) UToast.success(message: value);
                },
              ),
            ],
          ),
        ),

        DemoSection(
          title: "5 · Decode an image file",
          description:
              "Runs the same engine over a still image instead of a camera frame. Uses the free platform "
              "decoder where one exists (Vision on Apple, BarcodeDetector in Chrome) and falls back to the "
              "Dart engine everywhere else.",
          code: r'''
final List<UCode> codes = await UCameraController.analyzeImage(
  path: file.path,
  bytes: file.bytes,
  options: const UCodeScanOptions(multiple: true, tryInvert: true),
);''',
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: <Widget>[
              UButton(title: "Pick an image", icon: const Icon(Icons.image_search_rounded, size: 18), onTap: () => unawaited(_decodeFromFile())),
              if (_imageName != null) DemoLabel("$_imageName → ${_imageCodes.length} symbol(s)"),
              ..._imageCodes.map((UCode code) => _codeTile(code, scheme)),
            ],
          ),
        ),

        DemoSection(
          title: "6 · Generate, then scan it back",
          description:
              "Renders a symbol with UBarcode so you can point a second device at this screen — an "
              "end-to-end check of generator and scanner on real optics rather than a synthetic bitmap.",
          code: r'''UBarcode(value: "U-PLUGIN-2026", type: UBarcodeType.qrCode, width: 200, height: 200);''',
          child: UColumn(
            spacing: 12,
            children: <Widget>[
              UTextField(
                initialValue: _generated,
                labelText: "Payload",
                onChanged: (String value) => setState(() => _generated = value.isEmpty ? " " : value),
              ),
              UChipChoice<UBarcodeType>(
                options: const <UBarcodeType>[UBarcodeType.qrCode, UBarcodeType.code128, UBarcodeType.pdf417, UBarcodeType.dataMatrix, UBarcodeType.aztec],
                selected: _generatedType,
                chipBuilder: (UBarcodeType type, bool isSelected, int index) => Text(type.name),
                onChanged: (int index, bool isSelected, UBarcodeType item) => setState(() => _generatedType = item),
              ),
              UContainer(
                color: const Color(0xFFFFFFFF),
                radius: 12,
                padding: const EdgeInsets.all(16),
                child: UBarcode(value: _generated, type: _generatedType, width: 200, height: _generatedType == UBarcodeType.code128 ? 90 : 200, quietZone: 8),
              ),
            ],
          ),
        ),

        DemoSection(
          title: "7 · One-call helpers",
          description:
              "The shortcuts most screens actually use. Each opens the full camera page and returns "
              "FileData, so the result flows into uploads and pickers exactly like a picked file.",
          code: r'''
final UFileData? photo = await UCamera.takePhoto();
final List<UFileData> many = await UCamera.takePhotos(maxCount: 3);
final UFileData? clip = await UCamera.recordVideo();
final UFileData? viaFile = await UFile.takePhoto(selfie: true);''',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              UButton(title: "takePhoto", onTap: () => unawaited(_quickPhoto())),
              UButton(type: UButtonType.outlined, title: "takePhotos (3)", onTap: () => unawaited(_quickMultiPhoto())),
              UButton(type: UButtonType.outlined, title: "recordVideo", onTap: () => unawaited(_quickVideo())),
              UButton(
                type: UButtonType.text,
                title: "UFile.takePhoto(selfie)",
                onTap: () async {
                  final UFileData? file = await UFile.takePhoto(selfie: true);
                  if (file != null) UToast.success(message: "Got ${file.extension}");
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fact(String label, String value, {required bool good}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return URow(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        UTextBodyMedium(label),
        URow(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: <Widget>[
            Icon(good ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: good ? scheme.primary : scheme.error),
            UTextLabelLarge(value, fontWeight: FontWeight.w600),
          ],
        ),
      ],
    );
  }

  Widget _checkRow(_DecoderCheck check, ColorScheme scheme) => UContainer(
    color: check.passed ? scheme.primaryContainer : scheme.errorContainer,
    radius: 10,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: URow(
      spacing: 10,
      children: <Widget>[
        Icon(
          check.passed ? Icons.check_rounded : Icons.close_rounded,
          size: 18,
          color: check.passed ? scheme.onPrimaryContainer : scheme.onErrorContainer,
        ),
        Expanded(
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: <Widget>[
              UTextLabelLarge(check.format.label, fontWeight: FontWeight.w700),
              UTextBodySmall(
                check.passed ? check.expected : "expected ${check.expected} · got ${check.failure ?? check.decoded ?? "nothing"}",
                maxLines: 2,
              ),
            ],
          ),
        ),
        UTextLabelSmall("${(check.micros / 1000).toStringAsFixed(1)} ms"),
      ],
    ),
  );

  Widget _codeTile(UCode code, ColorScheme scheme) {
    final Map<String, String> parsed = code.parsed;
    return UContainer(
      color: scheme.surfaceContainerHighest,
      radius: 10,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(top: 4),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: <Widget>[
          URow(
            spacing: 8,
            children: <Widget>[
              UTextLabelLarge(code.format.label, fontWeight: FontWeight.w700),
              UTextLabelSmall(code.valueType.name, color: scheme.onSurfaceVariant),
              UTextLabelSmall(code.source.name, color: scheme.onSurfaceVariant),
            ],
          ),
          SelectableText(code.text, style: const TextStyle(fontFamily: "monospace", fontSize: 12.5)),
          if (code.version != null || code.errorCorrectionLevel != null)
            UTextBodySmall(
              <String>[
                if (code.version != null) "version ${code.version}",
                if (code.errorCorrectionLevel != null) "EC ${code.errorCorrectionLevel}",
                if (code.eci != null) "ECI ${code.eci}",
                if (code.corners.isNotEmpty) "${code.angle.toStringAsFixed(0)}°",
              ].join(" · "),
              color: scheme.onSurfaceVariant,
            ),
          ...parsed.entries
              .where((MapEntry<String, String> entry) => entry.key != "text")
              .map((MapEntry<String, String> entry) => UTextBodySmall("${entry.key}: ${entry.value}", color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// =============================================================================
// Self-test data
// =============================================================================

class _DecoderCheck {
  const _DecoderCheck({required this.format, required this.expected, required this.micros, this.decoded, this.failure});

  final UCodeFormat format;
  final String expected;
  final String? decoded;
  final String? failure;
  final int micros;

  bool get passed => failure == null && decoded == expected;
}

class _SelfTestCase {
  const _SelfTestCase({required this.format, required this.payload, required this.render});

  final UCodeFormat format;
  final String payload;
  final UBitMatrix Function() render;
}

/// Rasterises a 2D symbol into a bit matrix with a quiet zone, the way a camera
/// would see it printed on paper.
UBitMatrix _render2D(bc.Barcode2DMatrix matrix, {int scale = 6, int quiet = 4}) {
  final List<bool> pixels = matrix.pixels.toList();
  final int columns = matrix.width;
  final int rows = matrix.height;
  final UBitMatrix out = UBitMatrix((columns + quiet * 2) * scale, (rows + quiet * 2) * scale);
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < columns; x++) {
      if (!pixels[y * columns + x]) continue;
      for (int dy = 0; dy < scale; dy++) {
        for (int dx = 0; dx < scale; dx++) {
          out.set((x + quiet) * scale + dx, (y + quiet) * scale + dy);
        }
      }
    }
  }
  return out;
}

/// PDF417 rows are much taller than they are wide, so it gets its own scaling.
UBitMatrix _renderPdf417(bc.Barcode2DMatrix matrix, {int scale = 3, int rowHeight = 9, int quiet = 6}) {
  final List<bool> pixels = matrix.pixels.toList();
  final int columns = matrix.width;
  final int rows = matrix.height;
  final UBitMatrix out = UBitMatrix((columns + quiet * 2) * scale, rows * rowHeight + quiet * 2 * scale);
  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < columns; x++) {
      if (!pixels[y * columns + x]) continue;
      for (int dy = 0; dy < rowHeight; dy++) {
        for (int dx = 0; dx < scale; dx++) {
          out.set((x + quiet) * scale + dx, quiet * scale + y * rowHeight + dy);
        }
      }
    }
  }
  return out;
}

/// Linear symbols need a wide quiet zone on both sides to be readable.
UBitMatrix _render1D(bc.Barcode1D code, String data, {int scale = 3, int quiet = 220, int height = 60}) {
  final List<bc.BarcodeElement> elements = code.makeBytes(Uint8List.fromList(data.codeUnits), width: 1000, height: 1).toList();
  double maxRight = 0;
  for (final bc.BarcodeElement element in elements) {
    if (element.right > maxRight) maxRight = element.right;
  }
  final UBitMatrix out = UBitMatrix((maxRight * scale).ceil() + quiet * 2, height);
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

final List<_SelfTestCase> _selfTestCases = <_SelfTestCase>[
  _SelfTestCase(
    format: UCodeFormat.qr,
    payload: "https://sinamn75.com/checkout?id=123456",
    render: () => _render2D(
      const bc.BarcodeQR(null, bc.BarcodeQRCorrectionLevel.medium).convert(Uint8List.fromList(utf8.encode("https://sinamn75.com/checkout?id=123456"))),
      scale: 4,
    ),
  ),
  _SelfTestCase(
    format: UCodeFormat.qr,
    payload: "سلام دنیا",
    render: () => _render2D(
      const bc.BarcodeQR(null, bc.BarcodeQRCorrectionLevel.high).convert(Uint8List.fromList(utf8.encode("سلام دنیا"))),
      scale: 4,
    ),
  ),
  _SelfTestCase(
    format: UCodeFormat.dataMatrix,
    payload: "DM-TEST-123",
    render: () => _render2D(const bc.BarcodeDataMatrix().convert((bc.DataMatrixEncoder()..ascii("DM-TEST-123")).toBytes())),
  ),
  _SelfTestCase(
    format: UCodeFormat.aztec,
    payload: "AZTEC-TEST-123",
    render: () => _render2D(const bc.BarcodeAztec(33, 0).convert(Uint8List.fromList(utf8.encode("AZTEC-TEST-123")))),
  ),
  _SelfTestCase(
    format: UCodeFormat.pdf417,
    payload: "PDF417-TEST-123",
    render: () => _renderPdf417(const bc.BarcodePDF417(bc.Pdf417SecurityLevel.level2, 2, 3).convert(Uint8List.fromList(utf8.encode("PDF417-TEST-123")))),
  ),
  _SelfTestCase(format: UCodeFormat.code128, payload: "U-POS-2026", render: () => _render1D(bc.Barcode.code128() as bc.Barcode1D, "U-POS-2026")),
  _SelfTestCase(format: UCodeFormat.code39, payload: "HELLO-39", render: () => _render1D(bc.Barcode.code39() as bc.Barcode1D, "HELLO-39")),
  _SelfTestCase(format: UCodeFormat.code93, payload: "CODE93TEST", render: () => _render1D(bc.Barcode.code93() as bc.Barcode1D, "CODE93TEST")),
  _SelfTestCase(format: UCodeFormat.codabar, payload: "1234567", render: () => _render1D(bc.Barcode.codabar() as bc.Barcode1D, "1234567")),
  _SelfTestCase(format: UCodeFormat.itf, payload: "12345678", render: () => _render1D(bc.Barcode.itf() as bc.Barcode1D, "12345678")),
  _SelfTestCase(format: UCodeFormat.ean13, payload: "5901234123457", render: () => _render1D(bc.Barcode.ean13() as bc.Barcode1D, "5901234123457")),
  _SelfTestCase(format: UCodeFormat.ean8, payload: "96385074", render: () => _render1D(bc.Barcode.ean8() as bc.Barcode1D, "96385074")),
  _SelfTestCase(format: UCodeFormat.upcA, payload: "036000291452", render: () => _render1D(bc.Barcode.upcA() as bc.Barcode1D, "036000291452")),
];
