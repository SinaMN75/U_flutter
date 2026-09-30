import "package:path/path.dart" as path;
import "package:u/utilities.dart";

enum UImageSource { camera, gallery }

class UFileData {
  UFileData({
    this.bytes,
    this.extension,
    this.url,
    this.id,
    this.tags,
    this.children,
    this._name,
  });

  final Uint8List? bytes;
  final String? extension;
  final String? url;
  final String? id;
  final List<int>? tags;
  final List<UFileData>? children;
  final String? _name;

  String? get name => _name;

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
  /// File extensions treated as images.
  static const Set<String> imageExtensions = <String>{"jpg", "jpeg", "png", "gif", "webp", "bmp", "heic", "heif"};

  /// True when [extension] is an image type (jpg, png, …).
  static bool isImageExtension(String? extension) => extension != null && imageExtensions.contains(extension.toLowerCase());

  /// Picks one or more files of any type.
  static Future<List<UFileData>> pickFiles({
    bool allowMultiple = true,
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
    UCropOptions? crop,
    Function(List<UFileData>)? action,
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

  /// Picks one or more images from the gallery or camera, optionally cropped.
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
        files = await pickFiles(fileType: FileType.image, allowMultiple: allowMultiple, crop: crop);
      }
      action?.call(files);
      return files;
    } catch (_) {
      action?.call(<UFileData>[]);
      return <UFileData>[];
    }
  }

  /// Picks one image from the gallery or camera, optionally cropped.
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

  /// Picks one file of any type.
  static Future<UFileData?> pickFile({
    FileType fileType = FileType.any,
    List<String>? allowedExtensions,
    UCropOptions? crop,
    Function(UFileData?)? action,
  }) async {
    final List<UFileData> files = await pickFiles(allowMultiple: false, fileType: fileType, allowedExtensions: allowedExtensions, crop: crop);
    final UFileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  /// Opens the camera page and returns everything captured.
  static Future<List<UFileData>> openCamera({
    UCameraOptions options = const UCameraOptions(),
    Function(List<UFileData>)? action,
  }) => UCamera.open(options: options, action: action);

  /// Takes one photo with the camera, optionally cropped.
  static Future<UFileData?> takePhoto({
    bool selfie = false,
    UCropOptions? crop,
    UCameraOptions? options,
    Function(UFileData?)? action,
  }) => pickSingleImage(source: UImageSource.camera, selfie: selfie, crop: crop, cameraOptions: options, action: action);

  /// Takes several photos in one camera session.
  static Future<List<UFileData>> takePhotos({
    int maxCount = 0,
    bool selfie = false,
    UCropOptions? crop,
    UCameraOptions? options,
    Function(List<UFileData>)? action,
  }) => pickImage(source: UImageSource.camera, selfie: selfie, allowMultiple: true, maxCount: maxCount, crop: crop, cameraOptions: options, action: action);

  /// Records one video with the camera.
  static Future<UFileData?> recordVideo({
    UCameraOptions options = const UCameraOptions(),
    Function(UFileData?)? action,
  }) => UCamera.recordVideo(options: options, action: action);

  /// Picks a video from the gallery or records one.
  static Future<UFileData?> pickVideo({
    UImageSource source = UImageSource.gallery,
    UCameraOptions options = const UCameraOptions(),
    Function(UFileData?)? action,
  }) async {
    if (source == UImageSource.camera) return recordVideo(options: options, action: action);
    final List<UFileData> files = await pickFiles(allowMultiple: false, fileType: FileType.video);
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

  /// Opens the cropper for an image and returns the cropped file.
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

  /// Writes bytes to a new temporary file and returns it.
  static Future<File> writeToFile(Uint8List data, {String extension = "tmp"}) async {
    final Directory dir = await getTemporaryDirectory();
    return File("${dir.path}/u_${DateTime.now().microsecondsSinceEpoch}.$extension").writeAsBytes(data);
  }

  // --- App file storage (UFileStorage): keyed files, cached index, expiry, encrypted vault ---------

  /// Sets up file storage (initU() already does this).
  static Future<void> initStorage({int? cacheMaxBytes}) => UFileStorage.init(cacheMaxBytes: cacheMaxBytes);

  /// Saves bytes under [key]; use bucket cache/vault/temp for other places.
  static Future<void> saveBytes(String key, List<int> bytes, {UStorageBucket bucket = UStorageBucket.support, Duration? expireIn, String? mimeType}) =>
      UFileStorage.setBytes(key, bytes, bucket: bucket, expireIn: expireIn, mimeType: mimeType);

  /// Saves text under [key].
  static Future<void> saveString(String key, String value, {UStorageBucket bucket = UStorageBucket.support, Duration? expireIn}) =>
      UFileStorage.setString(key, value, bucket: bucket, expireIn: expireIn);

  /// Saves any JSON value under [key].
  static Future<void> saveJson(String key, Object? value, {UStorageBucket bucket = UStorageBucket.support, Duration? expireIn}) =>
      UFileStorage.setJson(key, value, bucket: bucket, expireIn: expireIn);

  /// Saves bytes encrypted (vault) under [key].
  static Future<void> saveSecure(String key, List<int> bytes) => UFileStorage.setBytes(key, bytes, bucket: UStorageBucket.vault);

  /// Saves bytes as re-creatable cache under [key] (may be evicted when space is low).
  static Future<void> saveCache(String key, List<int> bytes, {Duration? expireIn}) => UFileStorage.setBytes(key, bytes, bucket: UStorageBucket.cache, expireIn: expireIn);

  /// Reads the bytes saved under [key] (null if missing).
  static Future<Uint8List?> readBytes(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.getBytes(key, bucket: bucket);

  /// Reads the text saved under [key].
  static Future<String?> readString(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.getString(key, bucket: bucket);

  /// Reads the JSON saved under [key].
  static Future<dynamic> readJson(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.getJson(key, bucket: bucket);

  /// Reads encrypted bytes saved with [saveSecure].
  static Future<Uint8List?> readSecure(String key) => UFileStorage.getBytes(key, bucket: UStorageBucket.vault);

  /// Reads cached bytes saved with [saveCache].
  static Future<Uint8List?> readCache(String key) => UFileStorage.getBytes(key, bucket: UStorageBucket.cache);

  /// Streams the bytes under [key] (optionally a byte range), for big files.
  static Stream<Uint8List> readStream(String key, {UStorageBucket bucket = UStorageBucket.support, int start = 0, int? end}) =>
      UFileStorage.read(key, bucket: bucket, start: start, end: end);

  /// Copies a file from disk into storage under [key].
  static Future<void> importFile(String sourcePath, String key, {UStorageBucket bucket = UStorageBucket.support, bool deleteSource = false}) =>
      UFileStorage.importFile(sourcePath, key, bucket: bucket, deleteSource: deleteSource);

  /// Copies the file under [key] out to [destinationPath].
  static Future<bool> exportFile(String key, String destinationPath, {UStorageBucket bucket = UStorageBucket.support}) =>
      UFileStorage.exportFile(key, destinationPath, bucket: bucket);

  /// True when something is saved under [key].
  static bool exists(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.contains(key, bucket: bucket);

  /// Size in bytes of the file under [key].
  static int sizeOf(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.size(key, bucket: bucket);

  /// Real file path of [key] (null on the web or for vault files).
  static String? pathOf(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.pathOf(key, bucket: bucket);

  /// All keys saved in [bucket].
  static List<String> storageKeys({UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.keys(bucket: bucket);

  /// All stored files with their size, dates and tags.
  static List<UStorageEntry> storageEntries({UStorageBucket? bucket}) => UFileStorage.entries(bucket: bucket);

  /// Bytes used by storage (one bucket or all).
  static int storageUsage({UStorageBucket? bucket}) => UFileStorage.usage(bucket: bucket);

  /// Deletes the file under [key].
  static Future<void> delete(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.remove(key, bucket: bucket);

  /// Deletes every stored file (one bucket or all).
  static Future<void> deleteAll({UStorageBucket? bucket, bool includeDownloads = false}) => UFileStorage.clear(bucket: bucket, includeDownloads: includeDownloads);

  /// Copies a stored file to another key.
  static Future<void> copy(String from, String to, {UStorageBucket bucket = UStorageBucket.support, UStorageBucket? toBucket}) =>
      UFileStorage.copy(from, to, bucket: bucket, toBucket: toBucket);

  /// Moves a stored file to another key.
  static Future<void> move(String from, String to, {UStorageBucket bucket = UStorageBucket.support, UStorageBucket? toBucket}) =>
      UFileStorage.move(from, to, bucket: bucket, toBucket: toBucket);

  /// Emits whenever a stored file is added, changed or removed.
  static Stream<UStorageEvent> get storageChanges => UFileStorage.changes;

  /// Deletes expired files now.
  static Future<void> deleteExpired() => UFileStorage.evictExpired();

  /// Shrinks the cache bucket to its size limit now.
  static Future<void> trimCache() => UFileStorage.trimCache();

  /// Opens the built-in storage manager screen.
  static Future<void> openStoragePage() => UNavigator.push<void>(const UStorageManagerPage());

  // --- Native file actions (UFilesChannel) ---------------------------------------------------

  /// Opens a file with the default app.
  static Future<bool> open(String pathOrUri, {String? mimeType}) => UFilesChannel.open(pathOrUri, mimeType: mimeType);

  /// Shows a file in Finder / Explorer / Files.
  static Future<bool> reveal(String pathOrUri) => UFilesChannel.reveal(pathOrUri);

  /// Shows the "Save as" dialog and copies [sourcePath] there; returns where it was saved.
  static Future<String?> saveAs({required String sourcePath, required String fileName, String? mimeType}) =>
      UFilesChannel.saveAs(sourcePath: sourcePath, fileName: fileName, mimeType: mimeType);

  /// Copies a local file into the public Downloads folder (Android).
  static Future<String?> saveToDownloads({required String sourcePath, required String fileName, String? mimeType, String? subfolder}) =>
      UFilesChannel.saveToDownloads(sourcePath: sourcePath, fileName: fileName, mimeType: mimeType, subfolder: subfolder);

  /// Free disk space in bytes where [path] lives.
  static Future<int?> freeSpace(String path) => UFilesChannel.freeSpace(path);

  /// Keeps [path] out of iCloud / device backups (iOS, macOS).
  static Future<void> excludeFromBackup(String path) => UFilesChannel.excludeFromBackup(path);

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
    return UFileData(bytes: cropped, extension: "png");
  }

  static Future<UFileData> _fromPlatformFile(PlatformFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    return UFileData(bytes: bytes, name: file.name, extension: _extensionOf(file.name));
  }

  static String _extensionOf(String? source, [String fallback = ""]) {
    if (source == null || source.isEmpty) return fallback.toLowerCase();
    final String raw = path.extension(source);
    final String clean = raw.startsWith(".") ? raw.substring(1) : raw;
    return (clean.isEmpty ? fallback : clean).toLowerCase();
  }
}
