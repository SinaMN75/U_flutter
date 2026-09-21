import "package:path/path.dart" as path;
import "package:u/utilities.dart";

/// Helpers shared by the camera page, the scanner and any app-level UI built on
/// [UCameraController]. All of it is pure Dart, so it behaves the same on every
/// platform.
abstract class UCameraUtils {
  /// Maps a tap inside a preview box to the normalized (0..1) sensor point the
  /// controller expects, accounting for the preview being letterboxed or
  /// cropped by [fit] and for a mirrored front camera.
  static Offset normalizePoint({
    required Offset local,
    required Size widgetSize,
    required UCameraSize previewSize,
    BoxFit fit = BoxFit.cover,
    bool mirrored = false,
  }) {
    if (widgetSize.width <= 0 || widgetSize.height <= 0 || previewSize.width <= 0 || previewSize.height <= 0) {
      return const Offset(0.5, 0.5);
    }
    final double previewAspect = previewSize.aspectRatio;
    final double widgetAspect = widgetSize.width / widgetSize.height;

    double scale;
    if (fit == BoxFit.contain) {
      scale = previewAspect > widgetAspect ? widgetSize.width / previewSize.width : widgetSize.height / previewSize.height;
    } else {
      scale = previewAspect > widgetAspect ? widgetSize.height / previewSize.height : widgetSize.width / previewSize.width;
    }

    final double renderedWidth = previewSize.width * scale;
    final double renderedHeight = previewSize.height * scale;
    final double offsetX = (widgetSize.width - renderedWidth) / 2;
    final double offsetY = (widgetSize.height - renderedHeight) / 2;

    double x = ((local.dx - offsetX) / renderedWidth).clamp(0.0, 1.0);
    final double y = ((local.dy - offsetY) / renderedHeight).clamp(0.0, 1.0);
    if (mirrored) x = 1 - x;
    return Offset(x, y);
  }

  /// Inverse of [normalizePoint]: places a normalized point back on the widget.
  static Offset denormalizePoint({
    required Offset normalized,
    required Size widgetSize,
    required UCameraSize previewSize,
    BoxFit fit = BoxFit.cover,
    bool mirrored = false,
  }) {
    if (widgetSize.width <= 0 || previewSize.width <= 0) return Offset.zero;
    final double previewAspect = previewSize.aspectRatio;
    final double widgetAspect = widgetSize.width / widgetSize.height;
    double scale;
    if (fit == BoxFit.contain) {
      scale = previewAspect > widgetAspect ? widgetSize.width / previewSize.width : widgetSize.height / previewSize.height;
    } else {
      scale = previewAspect > widgetAspect ? widgetSize.height / previewSize.height : widgetSize.width / previewSize.width;
    }
    final double renderedWidth = previewSize.width * scale;
    final double renderedHeight = previewSize.height * scale;
    final double x = mirrored ? 1 - normalized.dx : normalized.dx;
    return Offset(
      (widgetSize.width - renderedWidth) / 2 + x * renderedWidth,
      (widgetSize.height - renderedHeight) / 2 + normalized.dy * renderedHeight,
    );
  }

  /// Converts a rectangle in frame pixels to widget coordinates, which is what
  /// a tracking overlay needs to draw a box around a detected symbol.
  static Rect frameRectToWidget({
    required Rect frameRect,
    required Size widgetSize,
    required UCameraSize previewSize,
    BoxFit fit = BoxFit.cover,
    bool mirrored = false,
  }) {
    final Offset topLeft = denormalizePoint(
      normalized: Offset(frameRect.left / previewSize.width, frameRect.top / previewSize.height),
      widgetSize: widgetSize,
      previewSize: previewSize,
      fit: fit,
      mirrored: mirrored,
    );
    final Offset bottomRight = denormalizePoint(
      normalized: Offset(frameRect.right / previewSize.width, frameRect.bottom / previewSize.height),
      widgetSize: widgetSize,
      previewSize: previewSize,
      fit: fit,
      mirrored: mirrored,
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Normalized scan window for a centered rectangle of [size] inside [bounds].
  static Rect centeredScanWindow(Size bounds, Size size) {
    if (bounds.width <= 0 || bounds.height <= 0) return const Rect.fromLTWH(0, 0, 1, 1);
    final double width = (size.width / bounds.width).clamp(0.05, 1.0);
    final double height = (size.height / bounds.height).clamp(0.05, 1.0);
    return Rect.fromLTWH((1 - width) / 2, (1 - height) / 2, width, height);
  }

  /// `mm:ss`, or `h:mm:ss` past an hour — used by the recording indicator.
  static String formatDuration(Duration duration) {
    final String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, "0");
    final String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, "0");
    if (duration.inHours == 0) return "$minutes:$seconds";
    return "${duration.inHours}:$minutes:$seconds";
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }

  /// Rotates a grayscale buffer clockwise by 90, 180 or 270 degrees.
  static UGrayImage rotateGray(UGrayImage image, int degrees) {
    switch (((degrees % 360) + 360) % 360) {
      case 90:
        return image.rotate90();
      case 180:
        return image.rotate180();
      case 270:
        return image.rotate270();
      default:
        return image;
    }
  }

  /// Crops a frame to a normalized region before decoding, the cheapest way to
  /// make scanning faster and more accurate.
  static UGrayImage cropGray(UGrayImage image, Rect normalizedRegion) {
    final int left = (normalizedRegion.left * image.width).round();
    final int top = (normalizedRegion.top * image.height).round();
    final int width = (normalizedRegion.width * image.width).round();
    final int height = (normalizedRegion.height * image.height).round();
    return image.crop(left, top, width, height);
  }

  /// Packs a grayscale buffer into ARGB pixels, ready for `decodeImageFromPixels`.
  static Uint8List grayToRgba(UGrayImage image) {
    final Uint8List out = Uint8List(image.width * image.height * 4);
    for (int y = 0; y < image.height; y++) {
      final int source = y * image.stride;
      final int destination = y * image.width * 4;
      for (int x = 0; x < image.width; x++) {
        final int value = image.data[source + x];
        out[destination + x * 4] = value;
        out[destination + x * 4 + 1] = value;
        out[destination + x * 4 + 2] = value;
        out[destination + x * 4 + 3] = 255;
      }
    }
    return out;
  }

  /// Wraps a captured photo as the [UFileData] the rest of the package passes
  /// around, so camera output flows through uploads and pickers unchanged.
  static UFileData toFileData(UCapturedPhoto photo) => UFileData(
    bytes: photo.bytes,
    path: photo.path,
    extension: photo.extension,
  );

  static UFileData videoToFileData(UCapturedVideo video, {Uint8List? bytes}) => UFileData(
    bytes: bytes ?? video.bytes,
    path: video.path,
    extension: extensionOf(video.path, video.container.name),
  );

  static String extensionOf(String source, String fallback) {
    final String raw = path.extension(source);
    final String clean = raw.startsWith(".") ? raw.substring(1) : raw;
    return (clean.isEmpty ? fallback : clean).toLowerCase();
  }

  /// A timestamped path inside the app's temporary directory.
  static Future<String> temporaryPath(String extension) async {
    final Directory directory = Directory("${(await getTemporaryDirectory()).path}/u_camera");
    if (!directory.existsSync()) directory.createSync(recursive: true);
    return "${directory.path}/${DateTime.now().millisecondsSinceEpoch}.$extension";
  }

  static IconData flashIcon(UFlashMode mode) {
    switch (mode) {
      case UFlashMode.off:
        return Icons.flash_off_rounded;
      case UFlashMode.auto:
        return Icons.flash_auto_rounded;
      case UFlashMode.on:
        return Icons.flash_on_rounded;
      case UFlashMode.torch:
        return Icons.highlight_rounded;
    }
  }

  static UFlashMode nextFlashMode(UFlashMode current, {bool includeTorch = true}) {
    final List<UFlashMode> order = includeTorch
        ? const <UFlashMode>[UFlashMode.off, UFlashMode.auto, UFlashMode.on, UFlashMode.torch]
        : const <UFlashMode>[UFlashMode.off, UFlashMode.auto, UFlashMode.on];
    return order[(order.indexOf(current) + 1) % order.length];
  }

  static String resolutionLabel(UCameraResolution resolution) {
    switch (resolution) {
      case UCameraResolution.low:
        return "240p";
      case UCameraResolution.medium:
        return "480p";
      case UCameraResolution.high:
        return "720p";
      case UCameraResolution.veryHigh:
        return "1080p";
      case UCameraResolution.ultraHigh:
        return "4K";
      case UCameraResolution.max:
        return "Max";
    }
  }

  /// Picks the device closest to [facing], preferring the given [lens].
  static UCameraDevice? pickDevice(List<UCameraDevice> devices, {UCameraFacing facing = UCameraFacing.back, UCameraLens? lens}) {
    if (devices.isEmpty) return null;
    UCameraDevice? fallback;
    for (final UCameraDevice device in devices) {
      if (device.facing != facing) continue;
      if (lens == null || device.lens == lens) return device;
      fallback ??= device;
    }
    return fallback ?? devices.first;
  }

  /// Splits a multi-part QR payload set (structured append) back into one string
  /// once every part has been scanned; returns null while parts are missing.
  static String? joinStructuredAppend(Iterable<UCode> codes) {
    final Map<int, UCode> parts = <int, UCode>{};
    int? total;
    for (final UCode code in codes) {
      final UCodeStructuredAppend? append = code.structuredAppend;
      if (append == null) return null;
      total ??= append.total;
      parts[append.index] = code;
    }
    if (total == null || parts.length != total) return null;
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < total; i++) {
      final UCode? part = parts[i];
      if (part == null) return null;
      buffer.write(part.text);
    }
    return buffer.toString();
  }
}
