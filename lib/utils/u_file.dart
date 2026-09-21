import "package:path/path.dart" as path;
import "package:u/utilities.dart";

enum UImageSource { camera, gallery }

class UFileData {
  UFileData({
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
  final List<UFileData>? children;

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

  static Future<List<UFileData>> showImagePicker({
    required UImageSource source,
    bool allowMultiple = false,
    bool isSelfie = false,
    UCropOptions? crop,
    Function(List<UFileData>)? action,
  }) => pickImage(source: source, selfie: isSelfie, allowMultiple: allowMultiple, crop: crop, action: action);

  static Future<List<UFileData>> showFilePicker({
    Function(List<UFileData>)? action,
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
          action?.call(<UFileData>[]);
          return <UFileData>[];
        }
        final List<UFileData> files = await _collect(list.map(_fromPlatformFile), crop);
        action?.call(files);
        return files;
      } else {
        final PlatformFile? platformFile = await FilePicker.pickFile(type: type, allowedExtensions: allowedExtensions);
        if (platformFile == null) {
          action?.call(<UFileData>[]);
          return <UFileData>[];
        }
        final List<UFileData> files = await _collect(<Future<UFileData>>[_fromPlatformFile(platformFile)], crop);
        action?.call(files);
        return files;
      }
    } catch (e) {
      action?.call(<UFileData>[]);
      return <UFileData>[];
    }
  }

  static Future<List<UFileData>> pickImage({
    UImageSource source = UImageSource.gallery,
    bool selfie = false,
    bool allowMultiple = false,
    int? maxCount,
    UCropOptions? crop,
    UCameraOptions? cameraOptions,
    Function(List<UFileData>)? action,
  }) async {
    try {
      List<UFileData> files;
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
      action?.call(<UFileData>[]);
      return <UFileData>[];
    }
  }

  static Future<UFileData?> pickSingleImage({
    UImageSource source = UImageSource.gallery,
    bool selfie = false,
    int? imageQuality,
    UCropOptions? crop,
    UCameraOptions? cameraOptions,
    Function(UFileData?)? action,
  }) async {
    final List<UFileData> files = await pickImage(source: source, selfie: selfie, crop: crop, cameraOptions: cameraOptions);
    final UFileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  static Future<List<UFileData>> pickFiles({
    bool allowMultiple = true,
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
    UCropOptions? crop,
    Function(List<UFileData>)? action,
  }) => showFilePicker(allowMultiple: allowMultiple, fileType: fileType, allowedExtensions: allowedExtensions, crop: crop, action: action);

  static Future<UFileData?> pickFile({
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
    UCropOptions? crop,
    Function(UFileData?)? action,
  }) async {
    final List<UFileData> files = await showFilePicker(fileType: fileType, allowedExtensions: allowedExtensions, crop: crop);
    final UFileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  static Future<List<UFileData>> openCamera({
    UCameraOptions options = const UCameraOptions(),
    Function(List<UFileData>)? action,
  }) => UCamera.open(options: options, action: action);

  static Future<UFileData?> takePhoto({
    bool selfie = false,
    UCropOptions? crop,
    UCameraOptions? options,
    Function(UFileData?)? action,
  }) => pickSingleImage(source: UImageSource.camera, selfie: selfie, crop: crop, cameraOptions: options, action: action);

  static Future<List<UFileData>> takePhotos({
    int maxCount = 0,
    bool selfie = false,
    UCropOptions? crop,
    UCameraOptions? options,
    Function(List<UFileData>)? action,
  }) => pickImage(source: UImageSource.camera, selfie: selfie, allowMultiple: true, maxCount: maxCount, crop: crop, cameraOptions: options, action: action);

  static Future<UFileData?> recordVideo({
    UCameraOptions options = const UCameraOptions(),
    Function(UFileData?)? action,
  }) => UCamera.recordVideo(options: options, action: action);

  static Future<UFileData?> pickVideo({
    UImageSource source = UImageSource.gallery,
    UCameraOptions options = const UCameraOptions(),
    Function(UFileData?)? action,
  }) async {
    if (source == UImageSource.camera) return recordVideo(options: options, action: action);
    final List<UFileData> files = await showFilePicker(fileType: FileType.video);
    final UFileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  static Future<List<UFileData>> _applyCrop(List<UFileData> files, UCropOptions? crop) async {
    if (crop == null) return files;
    final List<UFileData> out = <UFileData>[];
    for (final UFileData file in files) {
      final UFileData? result = await _maybeCrop(file, crop);
      if (result != null) out.add(result);
    }
    return out;
  }

  static Future<UFileData?> cropImage({
    Uint8List? bytes,
    String? filePath,
    UCropOptions options = const UCropOptions(),
    Function(UFileData file)? action,
  }) async {
    Uint8List? data = bytes;
    if (data == null && filePath != null && !kIsWeb) data = await File(filePath).readAsBytes();
    if (data == null) return null;

    final UFileData? cropped = await _openCropper(data, options);
    if (cropped == null) return null;
    action?.call(cropped);
    return cropped;
  }

  static Future<File> writeToFile(Uint8List data, {String extension = "tmp"}) async {
    final Directory dir = await getTemporaryDirectory();
    return File("${dir.path}/u_${DateTime.now().microsecondsSinceEpoch}.$extension").writeAsBytes(data);
  }

  static Future<List<UFileData>> _collect(Iterable<Future<UFileData>> sources, UCropOptions? crop) async {
    final List<UFileData> out = <UFileData>[];
    for (final Future<UFileData> source in sources) {
      final UFileData base = await source;
      final UFileData? result = await _maybeCrop(base, crop);
      if (result != null) out.add(result);
    }
    return out;
  }

  static Future<UFileData?> _maybeCrop(UFileData file, UCropOptions? crop) async {
    if (crop == null || !file.isImage || file.bytes == null) return file;
    return _openCropper(file.bytes!, crop);
  }

  static Future<UFileData?> _openCropper(Uint8List bytes, UCropOptions options) async {
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
    return UFileData(bytes: cropped, path: await _persistTemp(cropped, "png"), extension: "png");
  }

  static Future<UFileData> _fromPlatformFile(PlatformFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    return UFileData(bytes: bytes, path: kIsWeb ? null : file.path, extension: (file.xFile.mimeType ?? _extensionOf(file.name)).toLowerCase());
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
