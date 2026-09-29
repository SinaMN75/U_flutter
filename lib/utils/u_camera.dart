import "package:u/utilities.dart";

/// Camera: take photos / videos, scan barcodes and QR codes, read codes from images.
/// Wraps the camera engine in lib/plugins/camera and the camera / scanner pages.
abstract final class UCamera {
  /// Opens the full camera page and returns everything captured.
  static Future<List<UFileData>> open({UCameraOptions options = const UCameraOptions(), Function(List<UFileData>)? action}) async {
    final List<UFileData>? result = await UNavigator.push<List<UFileData>>(UCameraPage(options: options), fullscreenDialog: true);
    final List<UFileData> files = result ?? <UFileData>[];
    action?.call(files);
    return files;
  }

  /// Takes one photo.
  static Future<UFileData?> takePhoto({UCameraOptions options = const UCameraOptions(), Function(UFileData?)? action}) async {
    final List<UFileData> files = await open(options: options.copyWith(mode: UCameraMode.photo, allowMultiple: false));
    final UFileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  /// Takes several photos in one session; [maxCount] 0 means unlimited.
  static Future<List<UFileData>> takePhotos({int maxCount = 0, UCameraOptions options = const UCameraOptions(), Function(List<UFileData>)? action}) async {
    final List<UFileData> files = await open(options: options.copyWith(mode: UCameraMode.photo, allowMultiple: true, maxCount: maxCount));
    action?.call(files);
    return files;
  }

  /// Records one video.
  static Future<UFileData?> recordVideo({UCameraOptions options = const UCameraOptions(), Function(UFileData?)? action}) async {
    final List<UFileData> files = await open(options: options.copyWith(mode: UCameraMode.video, allowMultiple: false));
    final UFileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  /// Opens the scanner and returns the first code's text (null if closed).
  static Future<String?> scan({String? title, List<UCodeFormat> formats = const <UCodeFormat>[], String? hintText, bool showGalleryButton = false, UScanSpeed speed = UScanSpeed.normal}) =>
      UScannerPage.open(title: title, formats: formats, hintText: hintText, showGalleryButton: showGalleryButton, speed: speed);

  /// Opens the scanner and returns the full result (format, corners, raw bytes).
  static Future<UCode?> scanCode({String? title, List<UCodeFormat> formats = const <UCodeFormat>[], String? hintText}) =>
      UScannerPage.openForCode(title: title, formats: formats, hintText: hintText);

  /// Finds every barcode / QR code in an image file or image bytes.
  static Future<List<UCode>> scanImage({String? path, Uint8List? bytes, UCodeScanOptions options = const UCodeScanOptions(multiple: true), UScanEngine engine = UScanEngine.auto}) =>
      UCameraController.analyzeImage(path: path, bytes: bytes, options: options, engine: engine);

  /// Finds codes in raw RGBA/BGRA pixels (pure Dart, works everywhere).
  static List<UCode> decodePixels(Uint8List pixels, int width, int height, {bool bgra = true, int rowStride = 0, UCodeScanOptions options = const UCodeScanOptions()}) =>
      UCodeReader.decodePixels(pixels, width, height, bgra: bgra, rowStride: rowStride, options: options);

  /// Every camera on the device.
  static Future<List<UCameraDevice>> devices() => UCameraController.availableCameras();

  /// True when this platform has a camera implementation.
  static Future<bool> isSupported() => UCameraController.isSupported();

  /// Current camera (and microphone) permission.
  static Future<UCameraPermissionState> permission() => UCameraController.permissionStatus();

  /// Asks for camera permission ([audio] also asks for the microphone).
  static Future<UCameraPermissionState> requestPermission({bool audio = false}) => UCameraController.requestPermission(audio: audio);

  /// Opens the app's settings page so the user can grant permission.
  static Future<bool> openSettings() => UCameraController.openSettings();

  /// Creates a controller for building your own camera screen (show it with UCameraPreview).
  static UCameraController controller({UCameraConfig config = const UCameraConfig()}) => UCameraController(config: config);
}
