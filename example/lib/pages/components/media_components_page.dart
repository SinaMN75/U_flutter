import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// Images, viewers, cropper, barcodes, scanner, camera page, media notes, music helpers, web, HTML, map, capture.
class MediaComponentsPage extends StatefulWidget {
  const MediaComponentsPage({super.key});

  @override
  State<MediaComponentsPage> createState() => _MediaComponentsPageState();
}

class _MediaComponentsPageState extends State<MediaComponentsPage> {
  static const String _photo = "https://picsum.photos/seed/u/600/400";
  static const String _mp3 = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
  static const String _lrc = "[00:01.00]First line\n[00:04.00]Second line\n[00:07.00]Third line";
  static const String _pixel = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";

  final UWidgetToImageController _capture = UWidgetToImageController();
  final UMediaNotesController _notes = UMediaNotesController();
  final MapController _map = MapController();
  late final UMediaController _player = UMedia.audio();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  UFileData get _photoData => UFileData(url: _photo);

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Media components",
    children: <Widget>[
      DemoGroup("Images", <Widget>[
        Demo(
          'UImage(url / asset / svg / lottie / base64, …)',
          child: URow(
            spacing: 8,
            children: <Widget>[
              UImage(_photo, width: 80, height: 60, borderRadius: 8, fit: BoxFit.cover),
              const UImage("assets/icons/telegram.svg", width: 40, height: 40, package: "u"),
              const UImage(_pixel, width: 40, height: 40),
            ],
          ),
        ),
        Demo("UIconPrimary(svg, width: 28)", child: const UIconPrimary(UIcons.whatsapp, width: 28, package: "u")),
        const Demo("UImageNetwork(url) (disk-cached)", child: UImageNetwork(_photo, width: 80, height: 60)),
        Demo("UImageAsset(path, package: 'u')", child: const UImageAsset(UIcons.instagram, width: 40, package: "u")),
        Demo("UImageMemory(bytes)", child: UImageMemory(base64Decode(_pixel), width: 40, height: 40)),
        Demo("UImageFile(File(path))", child: kIsWeb ? const Text("not on web") : UImageFile(File("/does/not/exist.png"), width: 40, height: 40)),
        Fn("UBase64Image.isBase64(…) / tryParse(…).kind", () => <Object?>[UBase64Image.isBase64(_pixel), UBase64Image.tryParse(_pixel)?.kind], auto: true),
      ]),
      DemoGroup("Viewers & cropper", <Widget>[
        Fn("UNavigator.push(UImageViewer(fileData: …))", () => UNavigator.push<void>(UImageViewer(fileData: _photoData))),
        Fn("UNavigator.push(UBetterImageViewer(fileData: …))", () => UNavigator.push<void>(UBetterImageViewer(fileData: _photoData))),
        Fn(
          "UNavigator.push(UImageGalleryViewer(files: …))",
          () => UNavigator.push<void>(UImageGalleryViewer(files: List<UFileData>.generate(4, (int i) => UFileData(url: "https://picsum.photos/seed/g$i/800/600")))),
        ),
        Fn("UNavigator.push<Uint8List>(UImageCropper(bytes: …))", () async {
          final Uint8List bytes = await UDownloads.bytes(_photo);
          final Uint8List? out = await UNavigator.push<Uint8List>(UImageCropper(bytes: bytes, aspectRatios: const <UCropAspectRatio>[UCropAspectRatio("1:1", 1), UCropAspectRatio("16:9", 16 / 9)]));
          return out?.length.toBKMG();
        }),
      ]),
      DemoGroup("Barcodes & scanning", <Widget>[
        Demo(
          'UBarcode(value: …, type: qrCode)',
          child: const URow(
            spacing: 16,
            children: <Widget>[
              UBarcode(value: "https://sinamn75.com", width: 120, height: 120),
              UBarcode(value: "5901234123457", type: UBarcodeType.ean13, width: 160, height: 80),
            ],
          ),
        ),
        Fn("UBarcode.toSvg(value: …) length / UBarcode.isValid(…, ean13)", () => <Object>[UBarcode.toSvg(value: "hello").length, UBarcode.isValid("5901234123457", UBarcodeType.ean13)], auto: true),
        Fn("UBarcode.toPng(value: …)", () async => (await UBarcode.toPng(value: "hello"))?.length.toBKMG()),
        Demo(
          "UScanner(onScan: …)",
          note: "Needs `permission add camera`",
          child: SizedBox(
            height: 260,
            child: UScanner(onScan: (String text) => UToast.toast(message: text)),
          ),
        ),
        Fn("UScannerPage.open() / openForCode()", () async => <Object?>[await UScannerPage.open(), (await UScannerPage.openForCode())?.format]),
        Fn("UScanSpeed.normal.interval / maxFps", () => <Object>[UScanSpeed.normal.interval, UScanSpeed.normal.maxFps], auto: true),
        Fn("UNavigator.push(UCameraPage())", () => UNavigator.push<void>(const UCameraPage())),
      ]),
      DemoGroup("Media notes", <Widget>[
        Fn("notes.add(position: …, text: …) / length / notes / isEmpty", () {
          final UMediaNote n = _notes.add(position: 5.seconds, text: "Important bit");
          _notes.add(position: 20.seconds, end: 30.seconds, text: "Range note");
          return <Object>[n.id, _notes.length, _notes.notes.length, _notes.isEmpty];
        }),
        Fn(
          "byId / activeAt / indexBefore / search / markers",
          () => <Object?>[_notes.byId(_notes.notes.first.id)?.text, _notes.activeAt(6.seconds).length, _notes.indexBefore(25.seconds), _notes.search("range").length, _notes.markers.length],
        ),
        Fn("replace / remove / undo / redo / canUndo / canRedo", () {
          final UMediaNote first = _notes.notes.first;
          _notes.replace(first.copyWith(text: "Edited"));
          _notes.undo();
          _notes.redo();
          final List<bool> flags = <bool>[_notes.canUndo, _notes.canRedo];
          _notes.remove(first.id);
          _notes.undo();
          return flags;
        }),
        Fn("addShape / updateShape / shapes / shapesAt / removeShape / clearShapes", () {
          final UDocShape s = _notes.addShape(UDocShape.create(kind: UDocShapeKind.arrow, points: const <Offset>[Offset(0.1, 0.1), Offset(0.5, 0.5)], strokeColor: Colors.red));
          _notes.updateShape(s);
          final List<int> counts = <int>[_notes.shapes.length, _notes.shapesAt(Duration.zero).length];
          _notes.removeShape(s.id);
          _notes.clearShapes();
          return counts;
        }),
        Fn("color / updatedAt / storageKey", () {
          _notes.color = Colors.teal;
          return <Object?>[_notes.color, _notes.updatedAt, _notes.storageKey];
        }),
        Fn("export() / import(data) / toMarkdown() / toSrt()", () {
          final String data = _notes.export();
          return <Object>[data.length, _notes.import(data), _notes.toMarkdown(title: "Lecture").length, _notes.toSrt().length];
        }),
        Fn("attachStorage('notes-demo') / save() / load()", () async {
          await _notes.attachStorage("notes-demo");
          await _notes.save();
          await _notes.load();
          return _notes.length;
        }),
        Fn("notes.clear()", () {
          _notes.clear();
          return _notes.length;
        }),
        Fn("UMediaResume.save / get / clear", () {
          UMediaResume.save("lesson-1", 42.seconds, 10.minutes);
          final Duration? at = UMediaResume.get("lesson-1");
          UMediaResume.clear("lesson-1");
          return at;
        }),
        Fn("UMediaNotes.showPanel(notes, player) / addAtCurrentTime", () async {
          await _player.open(UMedia.network(_mp3), autoPlay: true);
          await UMediaNotes.addAtCurrentTime(_notes, _player);
          await UMediaNotes.showPanel(_notes, _player);
          await _player.pause();
          return _notes.length;
        }),
        Demo(
          "UMediaNotesPanel(notes: …, controller: …)",
          child: SizedBox(
            height: 260,
            child: UMediaNotesPanel(notes: _notes, controller: _player),
          ),
        ),
        Demo(
          "UMovingWatermark(watermark: …) over content",
          child: SizedBox(
            height: 120,
            child: Stack(
              children: <Widget>[
                Container(color: Colors.black12),
                const UMovingWatermark(watermark: UDocWatermark(lines: <String>["user@example.com", "0912***4567"])),
              ],
            ),
          ),
        ),
        Demo(
          "UMediaPipSwitcher(controller: …, child: …)",
          child: SizedBox(
            height: 60,
            child: UMediaPipSwitcher(
              controller: _player,
              child: const Center(child: Text("normal view (swaps to the pip child in picture-in-picture)")),
            ),
          ),
        ),
      ]),
      DemoGroup("Music helpers", <Widget>[
        Fn("ULyrics.fromText(lrc) synced lines", () {
          final ULyrics l = ULyrics.fromText(_lrc);
          return <Object>[l.synced, l.lines.length, l.indexAt(5.seconds), l.plainText];
        }, auto: true),
        Demo(
          "ULyricsView(controller: …, lyrics: ULyrics.fromText(…))",
          child: SizedBox(
            height: 120,
            child: ULyricsView(controller: _player, lyrics: ULyrics.fromText(_lrc)),
          ),
        ),
        Fn("UArtworkCache.load / peek / bytesHeld / clear", () async {
          const UArtworkRef ref = UArtworkRef.uri("https://picsum.photos/seed/art/200");
          final Uint8List? bytes = await UArtworkCache.load(ref);
          final List<Object?> out = <Object?>[bytes?.length, UArtworkCache.peek(ref)?.length, UArtworkCache.bytesHeld];
          UArtworkCache.clear();
          return out;
        }),
        Fn("UEqualizer(player): read / setEnabled / setBand / setPreset / setBassBoost / setVirtualizer / setLoudness", () async {
          final UEqualizer eq = UEqualizer(_player);
          final UEqualizerState s = await eq.read();
          if (!s.available) {
            return "no equalizer on this platform (Android only)";
          }
          await eq.setEnabled(true);
          await eq.setBand(0, 3);
          if (s.presets.isNotEmpty) await eq.setPreset(s.presets.first);
          await eq.setBassBoost(0.5);
          await eq.setVirtualizer(0.3);
          await eq.setLoudness(2);
          return (await eq.read()).bands.length;
        }),
      ]),
      DemoGroup("Web, HTML, map, capture", <Widget>[
        Demo(
          "UWebView(initialUrl: …)",
          child: const SizedBox(height: 320, child: UWebView(initialUrl: "https://flutter.dev")),
        ),
        Demo("UHtmlView(html: …)", child: const UHtmlView(html: "<h3>Hello</h3><p>This is <b>bold</b>, <i>italic</i> and a <a href='https://x.com'>link</a>.</p><ul><li>one</li><li>two</li></ul>")),
        Demo(
          "UMap(controller: MapController(), center: …)",
          child: SizedBox(
            height: 240,
            child: UMap(controller: _map, center: const LatLng(35.6997, 51.3380), zoom: 13),
          ),
        ),
        Demo("UDemoMap()", child: const SizedBox(height: 240, child: UDemoMap())),
        Demo(
          "UWidgetToImage(controller: …) + controller.capture()",
          child: UColumn(
            spacing: 8,
            children: <Widget>[
              UWidgetToImage(
                controller: _capture,
                child: const UPill("Receipt #42", icon: Icons.receipt_long),
              ),
              UButton(
                title: "capture()",
                onTap: () async => UToast.info(message: "${(await _capture.capture())?.length.toBKMG()}"),
              ),
              UButton(title: "bind(key) (done by the widget)", onTap: () => _capture.bind(GlobalKey())),
            ],
          ),
        ),
      ]),
    ],
  );
}
