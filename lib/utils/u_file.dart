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
    final Uint8List? bytes,
    final String? filePath,
    final Function(FileData file)? action,
    final int? maxWidth,
    final int? maxHeight,
    final UCropShape cropShape = UCropShape.rectangle,
    final double? aspectRatio,
    final List<UCropAspectRatio>? aspectRatios,
    final bool allowRotate = true,
    final bool allowFlip = true,
    final bool allowAdjust = true,
    final bool allowShapeToggle = false,
    final String? title,
  }) async {
    Uint8List? data = bytes;
    if (data == null && filePath != null && !kIsWeb) data = await File(filePath).readAsBytes();
    if (data == null) return null;

    final Uint8List? cropped = await UNavigator.push<Uint8List>(
      UImageCropper(
        bytes: data,
        title: title,
        shape: cropShape,
        aspectRatios: aspectRatios,
        initialAspectRatio: aspectRatio,
        allowRotate: allowRotate,
        allowFlip: allowFlip,
        allowAdjust: allowAdjust,
        allowShapeToggle: allowShapeToggle,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      fullscreenDialog: true,
    );
    if (cropped == null) return null;

    final FileData fileData = FileData(bytes: cropped, extension: "png");
    if (action != null) action(fileData);
    return fileData;
  }
}
