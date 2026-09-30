import "package:u/utilities.dart";

/// Camera on all 6 platforms: photos, videos, QR/barcode scanning (live and from images). Needs `dart run u:app permission add camera` (+ microphone for video). `final code = await UCamera.scan();`
abstract final class UCamera {
  /// Opens the full camera screen and returns everything captured. `await UCamera.open()`
  static Future<List<UFileData>> open({UCameraOptions options = const UCameraOptions(), Function(List<UFileData>)? action}) async {
    final List<UFileData>? result = await UNavigator.push<List<UFileData>>(UCameraPage(options: options), fullscreenDialog: true);
    final List<UFileData> files = result ?? <UFileData>[];
    action?.call(files);
    return files;
  }

  /// Takes one photo. `final UFileData? photo = await UCamera.takePhoto();`
  static Future<UFileData?> takePhoto({UCameraOptions options = const UCameraOptions(), Function(UFileData?)? action}) async {
    final List<UFileData> files = await open(options: options.copyWith(mode: UCameraMode.photo, allowMultiple: false));
    final UFileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  /// Takes several photos in one session; [maxCount] 0 = unlimited.
  static Future<List<UFileData>> takePhotos({int maxCount = 0, UCameraOptions options = const UCameraOptions(), Function(List<UFileData>)? action}) async {
    final List<UFileData> files = await open(
      options: options.copyWith(mode: UCameraMode.photo, allowMultiple: true, maxCount: maxCount),
    );
    action?.call(files);
    return files;
  }

  /// Records one video. Needs `permission add camera microphone`.
  static Future<UFileData?> recordVideo({UCameraOptions options = const UCameraOptions(), Function(UFileData?)? action}) async {
    final List<UFileData> files = await open(options: options.copyWith(mode: UCameraMode.video, allowMultiple: false));
    final UFileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  /// Opens the scanner and returns the first code's text, or null when closed. `final String? text = await UCamera.scan(formats: [UCodeFormat.qrCode])`
  static Future<String?> scan({String? title, List<UCodeFormat> formats = const <UCodeFormat>[], String? hintText, bool showGalleryButton = false, UScanSpeed speed = UScanSpeed.normal}) =>
      UScannerPage.open(title: title, formats: formats, hintText: hintText, showGalleryButton: showGalleryButton, speed: speed);

  /// Opens the scanner and returns the full result (format, corners, raw bytes).
  static Future<UCode?> scanCode({String? title, List<UCodeFormat> formats = const <UCodeFormat>[], String? hintText}) => UScannerPage.openForCode(title: title, formats: formats, hintText: hintText);

  /// Finds every QR/barcode in an image file or bytes (all platforms, no camera needed). `await UCamera.scanImage(bytes: imageBytes)`
  static Future<List<UCode>> scanImage({String? path, Uint8List? bytes, UCodeScanOptions options = const UCodeScanOptions(multiple: true), UScanEngine engine = UScanEngine.auto}) =>
      UCameraController.analyzeImage(path: path, bytes: bytes, options: options, engine: engine);

  /// Finds codes in raw RGBA/BGRA pixels, pure Dart (works in isolates and on the web).
  static List<UCode> decodePixels(Uint8List pixels, int width, int height, {bool bgra = true, int rowStride = 0, UCodeScanOptions options = const UCodeScanOptions()}) =>
      UCodeReader.decodePixels(pixels, width, height, bgra: bgra, rowStride: rowStride, options: options);

  /// Every camera (front, back, external) with its capabilities.
  static Future<List<UCameraDevice>> devices() => UCameraController.availableCameras();

  /// True when this platform/browser has a camera implementation.
  static Future<bool> isSupported() => UCameraController.isSupported();

  /// Camera (and microphone) permission right now.
  static Future<UCameraPermissionState> permission() => UCameraController.permissionStatus();

  /// Asks for camera permission; [audio] also asks for the microphone. `await UCamera.requestPermission()`
  static Future<UCameraPermissionState> requestPermission({bool audio = false}) => UCameraController.requestPermission(audio: audio);

  /// Opens the app's settings to grant a denied permission.
  static Future<bool> openSettings() => UCameraController.openSettings();

  /// A controller for your own camera screen; show it with UCameraPreview and dispose it. `final c = UCamera.controller(); await c.initialize();`
  static UCameraController controller({UCameraConfig config = const UCameraConfig()}) => UCameraController(config: config);
}
