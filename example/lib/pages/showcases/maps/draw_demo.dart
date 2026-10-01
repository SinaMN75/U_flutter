import "package:u/utilities.dart";

import "maps_page.dart";

/// Drawing, editing, measuring, GeoJSON export/import and annotated screenshots.
class DrawDemo extends StatefulWidget {
  const DrawDemo({super.key});

  @override
  State<DrawDemo> createState() => _DrawDemoState();
}

class _DrawDemoState extends State<DrawDemo> {
  final UMapDrawController _draw = UMapDrawController();
  final UWidgetToImageController _capture = UWidgetToImageController();
  bool _persian = false;

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final String json = _draw.toGeoJson();
    await UClipboard.set(json);
    UToast.info(message: "GeoJSON of ${_draw.shapes.length} shapes copied (${json.length} chars)");
  }

  Future<void> _import() async {
    final String? text = await UClipboard.getText();
    if (text == null || text.isEmpty) return UToast.info(message: "Clipboard is empty");
    final UGeoFeatureCollection? fc = await tryMap(() async => UGeo.readGeoJson(text));
    if (fc != null) _draw.loadGeoJson(text);
  }

  Future<void> _annotate() async {
    final Uint8List? png = await _capture.capture();
    if (png == null || !mounted) return;
    await UNavigator.push<void>(
      Scaffold(
        appBar: AppBar(title: const Text("Mark up and share")),
        body: UMapAnnotator(image: png, onDone: (Uint8List out) => UShare.bytes(out, name: "map.png", mimeType: "image/png")),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MapDemoScaffold(
    title: "Draw & measure",
    actions: <Widget>[
      IconButton(tooltip: "Copy GeoJSON", icon: const Icon(Icons.copy_all), onPressed: _export),
      IconButton(tooltip: "Paste GeoJSON", icon: const Icon(Icons.content_paste), onPressed: _import),
      IconButton(tooltip: "Screenshot & annotate", icon: const Icon(Icons.draw_outlined), onPressed: _annotate),
    ],
    map: UMap(center: kTehran, zoom: 14, drawController: _draw, captureController: _capture, persianDigits: _persian, scaleBar: true, myLocationButton: false),
    panel: ListenableBuilder(
      listenable: _draw,
      builder: (BuildContext context, _) {
        final UMapShape? s = _draw.selected;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: <Widget>[
            UMapDrawToolbar(controller: _draw, persian: _persian),
            Text(
              switch (_draw.mode) {
                UMapDrawMode.none => "Pick a tool. Select: tap a shape, drag its white handles, tap a small dot to add a vertex, long-press a handle to remove it.",
                UMapDrawMode.line || UMapDrawMode.polygon || UMapDrawMode.measureDistance || UMapDrawMode.measureArea => "Tap to add points, ✓ to finish.",
                UMapDrawMode.rectangle || UMapDrawMode.circle || UMapDrawMode.freehand => "Drag on the map (panning is paused for this tool).",
                _ => "Tap on the map.",
              },
              style: const TextStyle(fontSize: 12),
            ),
            if (s != null)
              Text(
                "Selected ${s.kind.name}: ${UMaps.formatDistance(s.length, persian: _persian)}${s.area > 0 ? " · ${UMapFormat.area(s.area, persian: _persian)}" : ""}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            Row(
              children: <Widget>[
                Text("${_draw.shapes.length} shapes", style: const TextStyle(fontSize: 12)),
                const Spacer(),
                for (final Color c in const <Color>[Color(0xFF1A73E8), Color(0xFFE53935), Color(0xFF43A047), Color(0xFFFB8C00)])
                  IconButton(
                    icon: Icon(Icons.circle, color: c, size: _draw.color == c ? 26 : 18),
                    onPressed: () => setState(() => _draw.color = c),
                  ),
                FilterChip(label: const Text("فارسی"), selected: _persian, onSelected: (bool v) => setState(() => _persian = v)),
                TextButton(onPressed: _draw.clear, child: const Text("Clear")),
              ],
            ),
          ],
        );
      },
    ),
  );
}
