import "package:path/path.dart" as path;
import "package:u/utilities.dart";

enum UImageSource {
  camera,
  gallery,
}

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
}

abstract class UFile {
  static Future<List<FileData>> showImagePicker({
    required final UImageSource source,
    final bool allowMultiple = false,
    final bool isSelfie = false,
    final Function(List<FileData>)? action,
  }) async {
    final List<FileData> files = <FileData>[];
    final ImagePicker imagePicker = ImagePicker();

    if (allowMultiple) {
      final List<XFile> images = await imagePicker.pickMultiImage();
      for (final XFile i in images) {
        final Uint8List bytes = await i.readAsBytes();
        files.add(FileData(bytes: bytes, path: i.path, extension: i.path.split(".").last));
      }
      if (action != null) action(files);
      return files;
    } else {
      final XFile? image = await imagePicker.pickImage(
        source: source == UImageSource.camera ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear,
      );
      if (image == null) return <FileData>[];
      final Uint8List bytes = await image.readAsBytes();
      files.add(FileData(bytes: bytes, path: image.path, extension: image.path.split(".").last));
      if (action != null) action(files);
      return files;
    }
  }

  static Future<void> showFilePicker({
    required final Function(List<FileData>) action,
    final FileType fileType = FileType.custom,
    final bool allowMultiple = false,
    final String? initialDirectory,
    final String? dialogTitle,
    final bool allowCompression = true,
    final bool withReadStream = false,
    final bool lockParentWindow = false,
    final List<String>? allowedExtensions,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: fileType,
        allowMultiple: allowMultiple,
        allowedExtensions: allowedExtensions,

      );

      if (result == null) return;

      final List<FileData> files = await Future.wait(
        result.files.map((PlatformFile file) async {
          if (kIsWeb) {
            return FileData(
              bytes: await file.readAsBytes(),
              extension: file.extension,
            );
          } else {
            return FileData(
              path: file.path,
              bytes: await File(file.path!).readAsBytes(),
              extension: file.extension ?? path.extension(file.path!),
            );
          }
        }),
      );

      action(files);
    } catch (e) {
      debugPrint("File picker error: $e");
      action(<FileData>[]);
    }
  }

  static Future<File> writeToFile(final Uint8List data) async {
    final Directory tempDir = await getTemporaryDirectory();
    return File("${tempDir.path}/${Random.secure().nextInt(10000)}.tmp").writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  static Future<FileData?> cropImage({
    required final String filePath,
    final Function(FileData file)? action,
    final int? maxWidth,
    final int? maxHeight,
    final CropStyle cropStyle = CropStyle.rectangle,
    final CropAspectRatio cropAspectRatio = const CropAspectRatio(ratioX: 3, ratioY: 1.2),
    final ImageCompressFormat imageCompressFormat = ImageCompressFormat.png,
    final AndroidUiSettings? androidUiSettings,
    final WebUiSettings? webUiSettings,
    final IOSUiSettings? iOSUiSettings,
    final Color? activeControlsWidgetColor,
    final Color? toolbarColor,
    final Color? toolbarWidgetColor,
    final List<CropAspectRatioPreset> aspectRatioPresets = const <CropAspectRatioPreset>[
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9,
    ],
  }) async {
    final CroppedFile? result = await ImageCropper().cropImage(
      sourcePath: filePath,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      aspectRatio: cropAspectRatio,
      compressFormat: imageCompressFormat,
      uiSettings: <PlatformUiSettings>[
        androidUiSettings ??
            AndroidUiSettings(
              aspectRatioPresets: aspectRatioPresets,
              cropStyle: cropStyle,
              toolbarTitle: "Crop Your Image",
              showCropGrid: true,
              hideBottomControls: false,
              lockAspectRatio: true,
              initAspectRatio: CropAspectRatioPreset.square,
              activeControlsWidgetColor: activeControlsWidgetColor ?? Theme.of(navigatorKey.currentContext!).colorScheme.primary,
              toolbarColor: toolbarColor ?? Theme.of(navigatorKey.currentContext!).colorScheme.primary,
              toolbarWidgetColor: toolbarWidgetColor ?? Theme.of(navigatorKey.currentContext!).cardColor,
            ),
        iOSUiSettings ??
            IOSUiSettings(
              aspectRatioPresets: aspectRatioPresets,
              cropStyle: cropStyle,
              resetAspectRatioEnabled: false,
              minimumAspectRatio: 1,
              aspectRatioPickerButtonHidden: true,
              title: "Crop Your Image",
              aspectRatioLockDimensionSwapEnabled: true,
              aspectRatioLockEnabled: true,
              hidesNavigationBar: true,
            ),
        webUiSettings ??
            WebUiSettings(
              context: navigatorKey.currentContext!,
              cropBoxMovable: true,
              background: true,
              center: true,
              checkCrossOrigin: true,
              checkOrientation: true,
              cropBoxResizable: true,
              guides: true,
              highlight: true,
              rotatable: true,
              zoomable: true,
              zoomOnTouch: true,
              zoomOnWheel: true,
            ),
      ],
    );
    if (result == null) return null;
    final FileData fileData = FileData(path: result.path, bytes: await result.readAsBytes(), extension: result.path.split(".").last);
    if (action != null) action(fileData);
    return fileData;
  }
}
