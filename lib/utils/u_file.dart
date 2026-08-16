import "package:path/path.dart" as path;
import "package:u/utilities.dart";

enum UImageSource { camera, gallery }

class FileData {
  FileData({
    this.path,
    this.bytes,
    this.extension,
    this.url,
    this.id,
    this.tags,
    this.children,
  });

  final String? path;
  final Uint8List? bytes;
  final String? extension;
  final String? url;
  final String? id;
  final List<int>? tags;
  final List<FileData>? children;

  String? get name => path?.split(RegExp(r"[\\/]")).last;

  int? get sizeInBytes => bytes?.lengthInBytes;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;

  bool get isImage => UFile.isImageExtension(extension);
}

class UCropOptions {
  const UCropOptions({
    this.shape = UCropShape.rectangle,
    this.aspectRatio,
    this.aspectRatios,
    this.maxWidth,
    this.maxHeight,
    this.allowRotate = true,
    this.allowFlip = true,
    this.allowAdjust = true,
    this.allowShapeToggle = false,
    this.title,
  });

  final UCropShape shape;
  final double? aspectRatio;
  final List<UCropAspectRatio>? aspectRatios;
  final int? maxWidth;
  final int? maxHeight;
  final bool allowRotate;
  final bool allowFlip;
  final bool allowAdjust;
  final bool allowShapeToggle;
  final String? title;
}

abstract class UFile {
  static const Set<String> imageExtensions = <String>{"jpg", "jpeg", "png", "gif", "webp", "bmp", "heic", "heif"};

  static bool isImageExtension(String? extension) => extension != null && imageExtensions.contains(extension.toLowerCase());

  /// Backwards-compatible image picker. Delegates to [pickImage] (camera capture
  /// uses the in-app [UCameraPage]; gallery uses the file picker).
  static Future<List<FileData>> showImagePicker({
    required UImageSource source,
    bool allowMultiple = false,
    bool isSelfie = false,
    int? imageQuality,
    UCropOptions? crop,
    Function(List<FileData>)? action,
  }) => pickImage(source: source, selfie: isSelfie, allowMultiple: allowMultiple, imageQuality: imageQuality, crop: crop, action: action);

  static Future<List<FileData>> showFilePicker({
    Function(List<FileData>)? action,
    FileType fileType = FileType.any,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    UCropOptions? crop,
  }) async {
    try {
      final FileType type = allowedExtensions != null && allowedExtensions.isNotEmpty ? FileType.custom : (fileType == FileType.custom ? FileType.any : fileType);
      if (allowMultiple) {
        final List<PlatformFile> list = await FilePicker.pickFiles(type: type, allowedExtensions: allowedExtensions);
        if (list.isNullOrEmpty()) {
          action?.call(<FileData>[]);
          return <FileData>[];
        }
        final List<FileData> files = await _collect(list.map(_fromPlatformFile), crop);
        action?.call(files);
        return files;
      } else {
        final PlatformFile? platformFile = await FilePicker.pickFile(type: type, allowedExtensions: allowedExtensions);
        if (platformFile == null) {
          action?.call(<FileData>[]);
          return <FileData>[];
        }
        final List<FileData> files = await _collect(<Future<FileData>>[_fromPlatformFile(platformFile)], crop);
        action?.call(files);
        return files;
      }
    } catch (e) {
      action?.call(<FileData>[]);
      return <FileData>[];
    }
  }

  static Future<List<FileData>> pickImage({
    UImageSource source = UImageSource.gallery,
    bool selfie = false,
    bool allowMultiple = false,
    int? maxCount,
    int? imageQuality,
    UCropOptions? crop,
    UCameraOptions? cameraOptions,
    Function(List<FileData>)? action,
  }) async {
    try {
      List<FileData> files;
      if (source == UImageSource.camera) {
        final UCameraOptions base = (cameraOptions ?? const UCameraOptions()).copyWith(
          mode: UCameraMode.photo,
          allowMultiple: allowMultiple,
          maxCount: maxCount ?? 0,
          startFront: selfie ? true : null,
        );
        files = await _applyCrop(await UCamera.open(options: base), crop);
      } else {
        files = await showFilePicker(fileType: FileType.image, allowMultiple: allowMultiple, crop: crop);
      }
      action?.call(files);
      return files;
    } catch (_) {
      action?.call(<FileData>[]);
      return <FileData>[];
    }
  }

  static Future<FileData?> pickSingleImage({
    UImageSource source = UImageSource.gallery,
    bool selfie = false,
    int? imageQuality,
    UCropOptions? crop,
    UCameraOptions? cameraOptions,
    Function(FileData?)? action,
  }) async {
    final List<FileData> files = await pickImage(source: source, selfie: selfie, imageQuality: imageQuality, crop: crop, cameraOptions: cameraOptions);
    final FileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  static Future<List<FileData>> pickFiles({
    bool allowMultiple = true,
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
    UCropOptions? crop,
    Function(List<FileData>)? action,
  }) => showFilePicker(allowMultiple: allowMultiple, fileType: fileType, allowedExtensions: allowedExtensions, crop: crop, action: action);

  static Future<FileData?> pickFile({
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
    UCropOptions? crop,
    Function(FileData?)? action,
  }) async {
    final List<FileData> files = await showFilePicker(fileType: fileType, allowedExtensions: allowedExtensions, crop: crop);
    final FileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  static Future<List<FileData>> openCamera({
    UCameraOptions options = const UCameraOptions(),
    Function(List<FileData>)? action,
  }) => UCamera.open(options: options, action: action);

  static Future<FileData?> takePhoto({
    bool selfie = false,
    UCropOptions? crop,
    UCameraOptions? options,
    Function(FileData?)? action,
  }) => pickSingleImage(source: UImageSource.camera, selfie: selfie, crop: crop, cameraOptions: options, action: action);

  /// Captures multiple photos in one camera session. [maxCount] 0 means unlimited.
  static Future<List<FileData>> takePhotos({
    int maxCount = 0,
    bool selfie = false,
    UCropOptions? crop,
    UCameraOptions? options,
    Function(List<FileData>)? action,
  }) => pickImage(source: UImageSource.camera, selfie: selfie, allowMultiple: true, maxCount: maxCount, crop: crop, cameraOptions: options, action: action);

  /// Records a single video with the in-app camera.
  static Future<FileData?> recordVideo({
    UCameraOptions options = const UCameraOptions(),
    Function(FileData?)? action,
  }) => UCamera.recordVideo(options: options, action: action);

  /// Picks a video from the gallery, or records one when [source] is camera.
  static Future<FileData?> pickVideo({
    UImageSource source = UImageSource.gallery,
    UCameraOptions options = const UCameraOptions(),
    Function(FileData?)? action,
  }) async {
    if (source == UImageSource.camera) return recordVideo(options: options, action: action);
    final List<FileData> files = await showFilePicker(fileType: FileType.video);
    final FileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  static Future<List<FileData>> _applyCrop(List<FileData> files, UCropOptions? crop) async {
    if (crop == null) return files;
    final List<FileData> out = <FileData>[];
    for (final FileData file in files) {
      final FileData? result = await _maybeCrop(file, crop);
      if (result != null) out.add(result);
    }
    return out;
  }

  static Future<FileData?> cropImage({
    Uint8List? bytes,
    String? filePath,
    UCropOptions options = const UCropOptions(),
    Function(FileData file)? action,
  }) async {
    Uint8List? data = bytes;
    if (data == null && filePath != null && !kIsWeb) data = await File(filePath).readAsBytes();
    if (data == null) return null;

    final FileData? cropped = await _openCropper(data, options);
    if (cropped == null) return null;
    action?.call(cropped);
    return cropped;
  }

  static Future<File> writeToFile(Uint8List data, {String extension = "tmp"}) async {
    final Directory dir = await getTemporaryDirectory();
    return File("${dir.path}/u_${DateTime.now().microsecondsSinceEpoch}.$extension").writeAsBytes(data);
  }

  static Future<List<FileData>> _collect(Iterable<Future<FileData>> sources, UCropOptions? crop) async {
    final List<FileData> out = <FileData>[];
    for (final Future<FileData> source in sources) {
      final FileData base = await source;
      final FileData? result = await _maybeCrop(base, crop);
      if (result != null) out.add(result);
    }
    return out;
  }

  static Future<FileData?> _maybeCrop(FileData file, UCropOptions? crop) async {
    if (crop == null || !file.isImage || file.bytes == null) return file;
    return _openCropper(file.bytes!, crop);
  }

  static Future<FileData?> _openCropper(Uint8List bytes, UCropOptions options) async {
    final Uint8List? cropped = await UNavigator.push<Uint8List>(
      UImageCropper(
        bytes: bytes,
        title: options.title,
        shape: options.shape,
        aspectRatios: options.aspectRatios,
        initialAspectRatio: options.aspectRatio,
        allowRotate: options.allowRotate,
        allowFlip: options.allowFlip,
        allowAdjust: options.allowAdjust,
        allowShapeToggle: options.allowShapeToggle,
        maxWidth: options.maxWidth,
        maxHeight: options.maxHeight,
      ),
      fullscreenDialog: true,
    );
    if (cropped == null) return null;
    return FileData(bytes: cropped, path: await _persistTemp(cropped, "png"), extension: "png");
  }

  static Future<FileData> _fromPlatformFile(PlatformFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    return FileData(bytes: bytes, path: kIsWeb ? null : file.path, extension: (file.xFile.mimeType ?? _extensionOf(file.name)).toLowerCase());
  }

  static Future<String?> _persistTemp(Uint8List bytes, String extension) async {
    if (kIsWeb) return null;
    try {
      final Directory dir = await getTemporaryDirectory();
      final File file = File("${dir.path}/u_${DateTime.now().microsecondsSinceEpoch}.$extension");
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static String _extensionOf(String? source, [String fallback = ""]) {
    if (source == null || source.isEmpty) return fallback.toLowerCase();
    final String raw = path.extension(source);
    final String clean = raw.startsWith(".") ? raw.substring(1) : raw;
    return (clean.isEmpty ? fallback : clean).toLowerCase();
  }
}
