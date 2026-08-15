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

  static Future<List<FileData>> showImagePicker({
    required UImageSource source,
    bool allowMultiple = false,
    bool isSelfie = false,
    int? imageQuality,
    UCropOptions? crop,
    Function(List<FileData>)? action,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> picked = <XFile>[];

      if (allowMultiple) {
        picked.addAll(await picker.pickMultiImage(imageQuality: imageQuality));
      } else {
        final XFile? single = await picker.pickImage(
          source: source == UImageSource.camera ? ImageSource.camera : ImageSource.gallery,
          preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear,
          imageQuality: imageQuality,
        );
        if (single != null) picked.add(single);
      }

      final List<FileData> files = await _collect(picked.map(_fromXFile), crop);
      action?.call(files);
      return files;
    } catch (e) {
      action?.call(<FileData>[]);
      return <FileData>[];
    }
  }

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

  static Future<FileData> _fromXFile(XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    return FileData(bytes: bytes, path: file.path, extension: _extensionOf(file.name.isNotEmpty ? file.name : file.path, "jpg"));
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
