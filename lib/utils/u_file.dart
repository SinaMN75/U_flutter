import "package:path/path.dart" as path;
import "package:u/utilities.dart";

/// Where pickImage/pickVideo take media from: the gallery or the camera.
enum UImageSource { camera, gallery }

/// A picked or captured file: bytes, name, extension, url or id. `file.bytes`, `file.name`, `file.isImage`
class UFileData {
  /// Holds a file in memory ([bytes]) or remotely ([url]/[id]); [tags] and [children] are for your own grouping.
  UFileData({
    this.bytes,
    this.extension,
    this.url,
    this.id,
    this.tags,
    this.children,
    this._name,
  });

  /// File content (null for remote files).
  final Uint8List? bytes;

  /// Extension without the dot, e.g. "jpg".
  final String? extension;

  /// Remote address when the file lives on a server.
  final String? url;

  /// Your own id, e.g. the server media id.
  final String? id;

  /// Your own numeric tags (e.g. TagMedia numbers).
  final List<int>? tags;

  /// Related files, e.g. pages of a document.
  final List<UFileData>? children;
  final String? _name;

  /// File name with extension, e.g. "photo.jpg".
  String? get name => _name;

  /// Size of [bytes]; null when not loaded.
  int? get sizeInBytes => bytes?.lengthInBytes;

  /// True when the content is in memory.
  bool get hasBytes => bytes != null && bytes!.isNotEmpty;

  /// True for image extensions (jpg, png, webp, heic…).
  bool get isImage => UFile.isImageExtension(extension);
}

/// How the cropper opens: shape, aspect ratio(s), max size, rotate/flip/adjust tools. `UCropOptions(aspectRatio: 1, shape: UCropShape.circle)`
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

  /// Crop frame shape: rectangle or circle.
  final UCropShape shape;

  /// Fixed width/height ratio, e.g. 1 for square, 16/9; null = free.
  final double? aspectRatio;

  /// Ratios the user can switch between.
  final List<UCropAspectRatio>? aspectRatios;

  /// Scales the result down to this width.
  final int? maxWidth;

  /// Scales the result down to this height.
  final int? maxHeight;

  /// Shows the rotate button.
  final bool allowRotate;

  /// Shows the flip button.
  final bool allowFlip;

  /// Shows brightness/contrast/saturation sliders.
  final bool allowAdjust;

  /// Lets the user switch rectangle/circle.
  final bool allowShapeToggle;

  /// Title of the crop screen.
  final String? title;
}

/// Pick, capture, crop, store, open and share files on all 6 platforms. `final UFileData? img = await UFile.pickSingleImage();`
abstract class UFile {
  /// Extensions treated as images.
  static const Set<String> imageExtensions = <String>{"jpg", "jpeg", "png", "gif", "webp", "bmp", "heic", "heif"};

  /// True when [extension] is an image type. `UFile.isImageExtension("png")` → true
  static bool isImageExtension(String? extension) => extension != null && imageExtensions.contains(extension.toLowerCase());

  /// Opens the system file picker; [allowedExtensions] filters, [crop] crops picked images. `await UFile.pickFiles(allowedExtensions: ["pdf", "docx"])`
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

  /// Picks images from the gallery, or takes them with the camera; optional crop. Camera: `permission add camera`. `await UFile.pickImage(allowMultiple: true, maxCount: 5)`
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

  /// Picks one image from the gallery or camera, optionally cropped. `await UFile.pickSingleImage(crop: const UCropOptions(aspectRatio: 1))`
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

  /// Picks one file of any type. `await UFile.pickFile(allowedExtensions: ["pdf"])`
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

  /// Opens the full camera screen (photos and/or video) and returns everything captured. Needs `permission add camera microphone`. `await UFile.openCamera()`
  static Future<List<UFileData>> openCamera({
    UCameraOptions options = const UCameraOptions(),
    Function(List<UFileData>)? action,
  }) => UCamera.open(options: options, action: action);

  /// Takes one photo, optionally cropped; [selfie] starts with the front camera. `await UFile.takePhoto(selfie: true)`
  static Future<UFileData?> takePhoto({
    bool selfie = false,
    UCropOptions? crop,
    UCameraOptions? options,
    Function(UFileData?)? action,
  }) => pickSingleImage(source: UImageSource.camera, selfie: selfie, crop: crop, cameraOptions: options, action: action);

  /// Takes several photos in one camera session ([maxCount] 0 = unlimited). `await UFile.takePhotos(maxCount: 4)`
  static Future<List<UFileData>> takePhotos({
    int maxCount = 0,
    bool selfie = false,
    UCropOptions? crop,
    UCameraOptions? options,
    Function(List<UFileData>)? action,
  }) => pickImage(source: UImageSource.camera, selfie: selfie, allowMultiple: true, maxCount: maxCount, crop: crop, cameraOptions: options, action: action);

  /// Records one video. Needs `permission add camera microphone`. `await UFile.recordVideo()`
  static Future<UFileData?> recordVideo({
    UCameraOptions options = const UCameraOptions(),
    Function(UFileData?)? action,
  }) => UCamera.recordVideo(options: options, action: action);

  /// Picks a video from the gallery, or records one with source camera. `await UFile.pickVideo()`
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

  /// Opens the cropper for bytes or a file path and returns the cropped image. `await UFile.cropImage(bytes: data, options: const UCropOptions(shape: UCropShape.circle))`
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

  /// Writes bytes to a new temp file and returns it (not on web). `final File f = await UFile.writeToFile(bytes, extension: "pdf")`
  static Future<File> writeToFile(Uint8List data, {String extension = "tmp"}) async {
    final Directory dir = await getTemporaryDirectory();
    return File("${dir.path}/u_${DateTime.now().microsecondsSinceEpoch}.$extension").writeAsBytes(data);
  }

  // --- App file storage (UFileStorage): keyed files, cached index, expiry, encrypted vault ---------

  /// Sets up file storage; initU() already does it. [cacheMaxBytes] limits the cache bucket.
  static Future<void> initStorage({int? cacheMaxBytes}) => UFileStorage.init(cacheMaxBytes: cacheMaxBytes);

  /// Saves bytes under [key] in app storage (all platforms; web uses IndexedDB). `await UFile.saveBytes("avatar.png", bytes)`
  static Future<void> saveBytes(String key, List<int> bytes, {UStorageBucket bucket = UStorageBucket.support, Duration? expireIn, String? mimeType}) =>
      UFileStorage.setBytes(key, bytes, bucket: bucket, expireIn: expireIn, mimeType: mimeType);

  /// Saves text under [key]. `await UFile.saveString("notes.txt", text)`
  static Future<void> saveString(String key, String value, {UStorageBucket bucket = UStorageBucket.support, Duration? expireIn}) =>
      UFileStorage.setString(key, value, bucket: bucket, expireIn: expireIn);

  /// Saves any JSON value under [key]. `await UFile.saveJson("draft", map)`
  static Future<void> saveJson(String key, Object? value, {UStorageBucket bucket = UStorageBucket.support, Duration? expireIn}) => UFileStorage.setJson(key, value, bucket: bucket, expireIn: expireIn);

  /// Saves bytes encrypted in the vault (key in Keychain/Keystore). `await UFile.saveSecure("id-card", bytes)`. macOS: unsigned debug builds show a Keychain password prompt after each rebuild; Team-signed apps never do.
  static Future<void> saveSecure(String key, List<int> bytes) => UFileStorage.setBytes(key, bytes, bucket: UStorageBucket.vault);

  /// Saves re-creatable cache; the OS/size limit may delete it. `await UFile.saveCache("thumb_1", bytes, expireIn: 7.days)`
  static Future<void> saveCache(String key, List<int> bytes, {Duration? expireIn}) => UFileStorage.setBytes(key, bytes, bucket: UStorageBucket.cache, expireIn: expireIn);

  /// Reads bytes saved under [key], or null. `await UFile.readBytes("avatar.png")`
  static Future<Uint8List?> readBytes(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.getBytes(key, bucket: bucket);

  /// Reads text saved under [key].
  static Future<String?> readString(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.getString(key, bucket: bucket);

  /// Reads JSON saved under [key].
  static Future<dynamic> readJson(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.getJson(key, bucket: bucket);

  /// Reads bytes saved with saveSecure().
  static Future<Uint8List?> readSecure(String key) => UFileStorage.getBytes(key, bucket: UStorageBucket.vault);

  /// Reads bytes saved with saveCache() (null when evicted).
  static Future<Uint8List?> readCache(String key) => UFileStorage.getBytes(key, bucket: UStorageBucket.cache);

  /// Streams a big stored file in chunks, optionally a byte range (video, audio). `UFile.readStream("movie.mp4")`
  static Stream<Uint8List> readStream(String key, {UStorageBucket bucket = UStorageBucket.support, int start = 0, int? end}) => UFileStorage.read(key, bucket: bucket, start: start, end: end);

  /// Copies a file from disk into app storage under [key] (not on web). `await UFile.importFile(pickedPath, "docs/contract.pdf")`
  static Future<void> importFile(String sourcePath, String key, {UStorageBucket bucket = UStorageBucket.support, bool deleteSource = false}) =>
      UFileStorage.importFile(sourcePath, key, bucket: bucket, deleteSource: deleteSource);

  /// Copies the stored file under [key] to [destinationPath] (not on web).
  static Future<bool> exportFile(String key, String destinationPath, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.exportFile(key, destinationPath, bucket: bucket);

  /// True when something is stored under [key].
  static bool exists(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.contains(key, bucket: bucket);

  /// Size in bytes of the stored file.
  static int sizeOf(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.size(key, bucket: bucket);

  /// Real disk path of a stored file (null on web and for vault files). `UFile.pathOf("avatar.png")`
  static String? pathOf(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.pathOf(key, bucket: bucket);

  /// Every key in [bucket].
  static List<String> storageKeys({UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.keys(bucket: bucket);

  /// Every stored file with size, dates and tags (for a storage screen).
  static List<UStorageEntry> storageEntries({UStorageBucket? bucket}) => UFileStorage.entries(bucket: bucket);

  /// Bytes used by one bucket or all. `UFile.storageUsage().toBKMG()`
  static int storageUsage({UStorageBucket? bucket}) => UFileStorage.usage(bucket: bucket);

  /// Deletes a stored file. `await UFile.delete("avatar.png")`
  static Future<void> delete(String key, {UStorageBucket bucket = UStorageBucket.support}) => UFileStorage.remove(key, bucket: bucket);

  /// Deletes every stored file (one bucket or all); [includeDownloads] also deletes downloads.
  static Future<void> deleteAll({UStorageBucket? bucket, bool includeDownloads = false}) => UFileStorage.clear(bucket: bucket, includeDownloads: includeDownloads);

  /// Copies a stored file to another key.
  static Future<void> copy(String from, String to, {UStorageBucket bucket = UStorageBucket.support, UStorageBucket? toBucket}) => UFileStorage.copy(from, to, bucket: bucket, toBucket: toBucket);

  /// Renames a stored file.
  static Future<void> move(String from, String to, {UStorageBucket bucket = UStorageBucket.support, UStorageBucket? toBucket}) => UFileStorage.move(from, to, bucket: bucket, toBucket: toBucket);

  /// Emits when a stored file is added, changed or removed.
  static Stream<UStorageEvent> get storageChanges => UFileStorage.changes;

  /// Deletes files whose ttl passed (runs automatically too).
  static Future<void> deleteExpired() => UFileStorage.evictExpired();

  /// Shrinks the cache bucket to its size limit now.
  static Future<void> trimCache() => UFileStorage.trimCache();

  /// Opens the built-in "Storage" screen (usage per bucket, clear buttons). `UFile.openStoragePage()`
  static Future<void> openStoragePage() => UNavigator.push<void>(const UStorageManagerPage());

  // --- Native file actions (UFilesChannel) ---------------------------------------------------

  /// Opens a file with its default app (web: new tab). `UFile.open("/path/report.pdf")`
  static Future<bool> open(String pathOrUri, {String? mimeType}) => UFilesChannel.open(pathOrUri, mimeType: mimeType);

  /// Shows a file in Finder / Explorer / Files / the file manager. `UFile.reveal(path)`
  static Future<bool> reveal(String pathOrUri) => UFilesChannel.reveal(pathOrUri);

  /// "Save as" dialog, then copies [sourcePath] there; returns the new location or null (Android, iOS, macOS, Windows, Linux). `await UFile.saveAs(sourcePath: p, fileName: "invoice.pdf")`
  static Future<String?> saveAs({required String sourcePath, required String fileName, String? mimeType}) => UFilesChannel.saveAs(sourcePath: sourcePath, fileName: fileName, mimeType: mimeType);

  /// Copies a local file into the Downloads folder (Android: public Downloads; desktop: ~/Downloads); null on iOS/web. `await UFile.saveToDownloads(sourcePath: p, fileName: "a.pdf")`
  static Future<String?> saveToDownloads({required String sourcePath, required String fileName, String? mimeType, String? subfolder}) async {
    if (kIsWeb || Platform.isIOS) return null;
    if (Platform.isAndroid) return UFilesChannel.saveToDownloads(sourcePath: sourcePath, fileName: fileName, mimeType: mimeType, subfolder: subfolder);
    // Desktop: copy into the user's Downloads folder, adding " (1)", " (2)"… instead of overwriting.
    final Directory? downloads = await getDownloadsDirectory();
    if (downloads == null) return null;
    final Directory folder = Directory(subfolder == null ? downloads.path : path.join(downloads.path, subfolder));
    await folder.create(recursive: true);
    final String base = path.basenameWithoutExtension(fileName);
    final String ext = path.extension(fileName);
    String target = path.join(folder.path, fileName);
    for (int i = 1; File(target).existsSync(); i++) {
      target = path.join(folder.path, "$base ($i)$ext");
    }
    await File(sourcePath).copy(target);
    return target;
  }

  /// Free bytes on the disk that holds [path] (null on web).
  static Future<int?> freeSpace(String path) => UFilesChannel.freeSpace(path);

  /// Keeps [path] out of iCloud/device backups (iOS, macOS; ignored elsewhere).
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
