import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// UFile (pick, capture, crop, store, open) and UDownloads.
class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  static const String _sampleUrl = "https://raw.githubusercontent.com/flutter/flutter/master/README.md";
  UFileData? _picked;
  UDownloadTask? _task;

  String? get _pickedName => _picked?.name;

  Future<Object?> _keep(Future<Object?> job) async {
    final Object? result = await job;
    if (result is UFileData) setState(() => _picked = result);
    if (result is List<UFileData> && result.isNotEmpty) {
      setState(() => _picked = result.first);
    }
    return result is List<UFileData>
        ? result.map((UFileData f) => "${f.name} (${f.sizeInBytes?.toBKMG()})").toList()
        : (result is UFileData ? "${result.name} (${result.sizeInBytes?.toBKMG()})" : result);
  }

  Future<Object?> _withTask(Future<Object?> Function(UDownloadTask task) run) async {
    final UDownloadTask? task = _task ?? (UDownloads.tasks.isEmpty ? null : UDownloads.tasks.first);
    if (task == null) return "Start a download first";
    return run(task);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Files & downloads",
    intro: "Camera functions need `dart run u:app permission add camera` (and microphone for video).",
    children: <Widget>[
      DemoGroup("Pick & capture", <Widget>[
        Fn("await UFile.pickFiles()", () => _keep(UFile.pickFiles())),
        Fn('await UFile.pickFile(allowedExtensions: ["pdf", "txt"])', () => _keep(UFile.pickFile(allowedExtensions: <String>["pdf", "txt"]))),
        Fn("await UFile.pickImage(allowMultiple: true, maxCount: 3)", () => _keep(UFile.pickImage(allowMultiple: true, maxCount: 3))),
        Fn("await UFile.pickSingleImage(crop: UCropOptions(aspectRatio: 1))", () => _keep(UFile.pickSingleImage(crop: const UCropOptions(aspectRatio: 1)))),
        Fn("await UFile.pickVideo()", () => _keep(UFile.pickVideo())),
        Fn("await UFile.takePhoto(selfie: true)", () => _keep(UFile.takePhoto(selfie: true))),
        Fn("await UFile.takePhotos(maxCount: 3)", () => _keep(UFile.takePhotos(maxCount: 3))),
        Fn("await UFile.recordVideo()", () => _keep(UFile.recordVideo())),
        Fn("await UFile.openCamera()", () => _keep(UFile.openCamera())),
        Fn("await UFile.cropImage(bytes: picked, options: circle)", () async {
          final Uint8List? bytes = _picked?.bytes;
          if (bytes == null || !(_picked?.isImage ?? false)) {
            return "Pick an image first";
          }
          return _keep(
            UFile.cropImage(
              bytes: bytes,
              options: const UCropOptions(shape: UCropShape.circle),
            ),
          );
        }),
        Demo("last picked", child: Text(_pickedName ?? "nothing yet")),
        Fn('UFile.isImageExtension("png")', () => UFile.isImageExtension("png"), auto: true),
        Fn('UFile.writeToFile(bytes, extension: "txt")', () async => (await UFile.writeToFile(Uint8List.fromList(utf8.encode("hello")), extension: "txt")).path, note: "Not on web"),
      ]),
      DemoGroup("App storage (all platforms, web = IndexedDB)", <Widget>[
        Fn("UFile.initStorage()", UFile.initStorage),
        Fn('UFile.saveString("notes.txt", "hello")', () => UFile.saveString("notes.txt", "hello")),
        Fn('UFile.readString("notes.txt")', () => UFile.readString("notes.txt")),
        Fn('UFile.saveBytes("a.bin", [1, 2, 3])', () => UFile.saveBytes("a.bin", <int>[1, 2, 3])),
        Fn('UFile.readBytes("a.bin")', () => UFile.readBytes("a.bin")),
        Fn('UFile.saveJson("draft", {...})', () => UFile.saveJson("draft", <String, Object>{"title": "Draft", "done": false})),
        Fn('UFile.readJson("draft")', () => UFile.readJson("draft")),
        Fn('UFile.saveSecure("id-card", bytes)', () => UFile.saveSecure("id-card", utf8.encode("secret"))),
        Fn('UFile.readSecure("id-card")', () async => utf8.decode((await UFile.readSecure("id-card")) ?? <int>[])),
        Fn('UFile.saveCache("thumb", bytes, expireIn: 7.days)', () => UFile.saveCache("thumb", <int>[9, 9], expireIn: 7.days)),
        Fn('UFile.readCache("thumb")', () => UFile.readCache("thumb")),
        Fn('UFile.readStream("a.bin")', () => UFile.readStream("a.bin")),
        Fn('UFile.exists("a.bin") / sizeOf / pathOf', () => <Object?>[UFile.exists("a.bin"), UFile.sizeOf("a.bin"), UFile.pathOf("a.bin")]),
        Fn("UFile.storageKeys()", UFile.storageKeys),
        Fn("UFile.storageEntries()", UFile.storageEntries),
        Fn("UFile.storageUsage().toBKMG()", () => UFile.storageUsage().toBKMG()),
        Fn('UFile.copy("a.bin", "b.bin")', () => UFile.copy("a.bin", "b.bin")),
        Fn('UFile.move("b.bin", "c.bin")', () => UFile.move("b.bin", "c.bin")),
        Fn('UFile.delete("c.bin")', () => UFile.delete("c.bin")),
        Fn("UFile.storageChanges (first)", () {
          Future<void>.delayed(200.ms, () => UFile.saveString("tick.txt", "${DateTime.now()}"));
          return UFile.storageChanges.first.timeout(3.seconds);
        }),
        Fn("UFile.deleteExpired()", UFile.deleteExpired),
        Fn("UFile.trimCache()", UFile.trimCache),
        Fn("UFile.importFile(path, key)", () async {
          final File f = await UFile.writeToFile(Uint8List.fromList(utf8.encode("imported")), extension: "txt");
          await UFile.importFile(f.path, "imported.txt");
          return UFile.readString("imported.txt");
        }, note: "Not on web"),
        Fn("UFile.exportFile(key, path)", () async {
          final Directory dir = await getTemporaryDirectory();
          return UFile.exportFile("notes.txt", "${dir.path}/exported.txt");
        }, note: "Not on web"),
        Fn("UFile.deleteAll(bucket: UStorageBucket.cache)", () => UFile.deleteAll(bucket: UStorageBucket.cache)),
        Fn("UFile.openStoragePage()", UFile.openStoragePage),
      ]),
      DemoGroup("Open & save on the device", <Widget>[
        Fn("UFile.open(path)", () async => UFile.open((await UFile.writeToFile(Uint8List.fromList(utf8.encode("open me")), extension: "txt")).path)),
        Fn("UFile.reveal(path)", () async => UFile.reveal((await UFile.writeToFile(Uint8List.fromList(utf8.encode("reveal")), extension: "txt")).path)),
        Fn(
          'UFile.saveAs(sourcePath: p, fileName: "a.txt")',
          () async => UFile.saveAs(
            sourcePath: (await UFile.writeToFile(Uint8List.fromList(utf8.encode("save")), extension: "txt")).path,
            fileName: "u-example.txt",
          ),
        ),
        Fn(
          'UFile.saveToDownloads(sourcePath: p, fileName: "a.txt")',
          () async => UFile.saveToDownloads(
            sourcePath: (await UFile.writeToFile(Uint8List.fromList(utf8.encode("dl")), extension: "txt")).path,
            fileName: "u-example.txt",
          ),
          note: "Android & desktop",
        ),
        Fn("UFile.freeSpace(tempDir)", () async => (await UFile.freeSpace((await getTemporaryDirectory()).path))?.toBKMG()),
        Fn("UFile.excludeFromBackup(path)", () async => UFile.excludeFromBackup((await getApplicationSupportDirectory()).path), note: "iOS, macOS"),
      ]),
      DemoGroup("Downloads", <Widget>[
        Fn("UDownloads.init()", UDownloads.init),
        Fn("UDownloads.download(url)", () async {
          final UDownloadTask t = await UDownloads.download(_sampleUrl);
          setState(() => _task = t);
          return t.displayName;
        }),
        Fn("UDownloads.toStorage(url, 'readme.md')", () async => (await UDownloads.toStorage(_sampleUrl, "readme.md")).status),
        Fn("UDownloads.toVault(url, 'readme.vault')", () async => (await UDownloads.toVault(_sampleUrl, "readme.vault")).status),
        Fn("UDownloads.toFile(url, path)", () async => (await UDownloads.toFile(_sampleUrl, "${(await getTemporaryDirectory()).path}/readme.md")).status, note: "Not on web"),
        Fn("UDownloads.saveAs(url)", () async => (await UDownloads.saveAs(_sampleUrl, fileName: "README.md")).status),
        Fn("UDownloads.enqueue(UDownloadRequest(…))", () async => (await UDownloads.enqueue(UDownloadRequest(url: _sampleUrl))).status),
        Fn("UDownloads.bytes(url)", () async => (await UDownloads.bytes(_sampleUrl)).length.toBKMG()),
        Fn("UDownloads.text(url)", () async => (await UDownloads.text(_sampleUrl)).maxLength(max: 80)),
        Fn("UDownloads.fetchToStorage(url, key)", () => UDownloads.fetchToStorage(_sampleUrl, "readme2.md")),
        Fn(
          "UDownloads.tasks / allTasks / active / completed / failed",
          () => <int>[UDownloads.tasks.length, UDownloads.allTasks.length, UDownloads.active.length, UDownloads.completed.length, UDownloads.failed.length],
        ),
        Fn("UDownloads.task(id)", () => _withTask((UDownloadTask t) async => UDownloads.task(t.id)?.status)),
        Fn("UDownloads.events (first)", () => UDownloads.events.first.timeout(3.seconds)),
        Fn("UDownloads.totalSpeed / isDownloading", () => <Object>[UDownloads.totalSpeed.toBKMG(), UDownloads.isDownloading]),
        Fn("UDownloads.pause(id)", () => _withTask((UDownloadTask t) => UDownloads.pause(t.id))),
        Fn("UDownloads.resume(id)", () => _withTask((UDownloadTask t) => UDownloads.resume(t.id))),
        Fn("UDownloads.retry(id)", () => _withTask((UDownloadTask t) => UDownloads.retry(t.id))),
        Fn("UDownloads.cancel(id)", () => _withTask((UDownloadTask t) => UDownloads.cancel(t.id))),
        Fn("UDownloads.open(task)", () => _withTask(UDownloads.open)),
        Fn("UDownloads.reveal(task)", () => _withTask(UDownloads.reveal)),
        Fn("UDownloads.share(task)", () => _withTask(UDownloads.share)),
        Fn("UDownloads.remove(id, deleteFile: true)", () => _withTask((UDownloadTask t) => UDownloads.remove(t.id, deleteFile: true))),
        Fn("UDownloads.pauseAll() / resumeAll()", () async {
          await UDownloads.pauseAll();
          await UDownloads.resumeAll();
          return "ok";
        }),
        Fn("UDownloads.clearFinished()", UDownloads.clearFinished),
        Fn("UDownloads.config", () => UDownloads.config),
        Fn("UDownloads.maxConcurrent = 2; speedLimit = 0", () {
          UDownloads.maxConcurrent = 2;
          UDownloads.speedLimit = 0;
          return "set";
        }),
        Fn("UDownloads.headersProvider / urlResolver", () {
          UDownloads.headersProvider = (UDownloadTask t) async => <String, String>{"X-App": UApp.name};
          UDownloads.urlResolver = null;
          return "set";
        }),
        Fn("UDownloads.manager", () => UDownloads.manager.runtimeType),
        Fn("UDownloads.openPage()", UDownloads.openPage),
      ]),
    ],
  );
}
