import "package:u/utilities.dart";

import "maps_page.dart";

enum _Base { raster, vectorLight, vectorDark, liberty }

/// Styles, vector maps, filters, terrain, tilt, compare and camera animations.
class StylesDemo extends StatefulWidget {
  const StylesDemo({super.key});

  @override
  State<StylesDemo> createState() => _StylesDemoState();
}

class _StylesDemoState extends State<StylesDemo> {
  final MapController _map = MapController();
  _Base _base = _Base.raster;
  UMapTileSource _source = UMapTileSource.openStreetMap;
  UMapVectorStyle? _liberty;
  UMapColorFilter _filter = UMapColorFilter.none;
  bool _hillshade = false;
  bool _contours = false;
  bool _labels = false;
  bool _miniMap = true;
  bool _lockToTehran = false;
  bool _persian = false;
  double _tilt = 0;

  static const List<(String, LatLng, double)> _cities = <(String, LatLng, double)>[
    ("Tehran", kTehran, 12),
    ("Isfahan", LatLng(32.6546, 51.6680), 13),
    ("Shiraz", LatLng(29.5918, 52.5837), 13),
    ("Damavand", LatLng(35.9556, 52.1100), 12),
    ("London", LatLng(51.5072, -0.1276), 12),
  ];

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _pickBase(_Base b) async {
    if (b == _Base.liberty && _liberty == null) {
      _liberty = await tryMap(() => UMaps.vectorStyle("https://tiles.openfreemap.org/styles/liberty", language: "fa"));
      if (_liberty == null) return;
    }
    setState(() => _base = b);
  }

  UMapVectorStyle? get _vector => switch (_base) {
    _Base.raster => null,
    _Base.vectorLight => UMapVectorStyle.light(language: _persian ? "fa" : null),
    _Base.vectorDark => UMapVectorStyle.dark(language: _persian ? "fa" : null),
    _Base.liberty => _liberty?.withLanguage(_persian ? "fa" : null),
  };

  @override
  Widget build(BuildContext context) => MapDemoScaffold(
    title: "Styles & camera",
    actions: <Widget>[
      IconButton(
        tooltip: "Compare 2016 satellite with a topographic map",
        icon: const Icon(Icons.compare),
        onPressed: () => UNavigator.push<void>(
          Scaffold(
            appBar: AppBar(title: const Text("Swipe compare")),
            body: UMapCompare(left: <Widget>[UMapTiles.layer(UMapTileSource.sentinel2)], right: <Widget>[UMapTiles.layer(UMapTileSource.openTopoMap)]),
          ),
        ),
      ),
    ],
    map: UMap(
      controller: _map,
      center: kTehran,
      zoom: 12,
      maxZoom: 20,
      source: _source,
      vectorStyle: _vector,
      vectorOverlay: _labels ? UMapVectorStyle.labels(language: _persian ? "fa" : null) : null,
      colorFilter: _filter,
      hillshade: _hillshade,
      contours: _contours,
      scaleBar: true,
      miniMap: _miniMap,
      tilt: _tilt,
      persianDigits: _persian,
      maxBounds: _lockToTehran ? LatLngBounds(const LatLng(35.55, 51.1), const LatLng(35.85, 51.65)) : null,
      persistKey: "styles_demo",
    ),
    panel: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        MapChips<_Base>(
          values: _Base.values,
          selected: _base,
          label: (_Base b) => switch (b) {
            _Base.raster => "Raster",
            _Base.vectorLight => "Vector light",
            _Base.vectorDark => "Vector dark",
            _Base.liberty => "OpenFreeMap Liberty",
          },
          onSelected: _pickBase,
        ),
        if (_base == _Base.raster)
          Row(
            children: <Widget>[
              Expanded(child: Text("Tiles: ${_source.name} · ${_source.policy.name}", style: const TextStyle(fontSize: 12))),
              TextButton.icon(
                icon: const Icon(Icons.layers),
                label: const Text("Change"),
                onPressed: () async {
                  final UMapTileSource? s = await UMapStylePicker.show(context, selected: _source);
                  if (s != null) setState(() => _source = s);
                },
              ),
            ],
          ),
        MapChips<UMapColorFilter>(values: UMapColorFilter.values, selected: _filter, label: (UMapColorFilter f) => f.name, onSelected: (UMapColorFilter f) => setState(() => _filter = f)),
        Wrap(
          spacing: 6,
          children: <Widget>[
            FilterChip(label: const Text("Hillshade"), selected: _hillshade, onSelected: (bool v) => setState(() => _hillshade = v)),
            FilterChip(label: const Text("Contours"), selected: _contours, onSelected: (bool v) => setState(() => _contours = v)),
            FilterChip(label: const Text("Vector labels overlay"), selected: _labels, onSelected: (bool v) => setState(() => _labels = v)),
            FilterChip(label: const Text("Mini-map"), selected: _miniMap, onSelected: (bool v) => setState(() => _miniMap = v)),
            FilterChip(label: const Text("Lock to Tehran"), selected: _lockToTehran, onSelected: (bool v) => setState(() => _lockToTehran = v)),
            FilterChip(label: const Text("فارسی"), selected: _persian, onSelected: (bool v) => setState(() => _persian = v)),
          ],
        ),
        Row(
          children: <Widget>[
            const Text("Tilt", style: TextStyle(fontSize: 12)),
            Expanded(child: Slider(value: _tilt, max: 60, onChanged: (double v) => setState(() => _tilt = v))),
          ],
        ),
        Wrap(
          spacing: 6,
          children: <Widget>[
            for (final (String name, LatLng p, double z) in _cities) ActionChip(avatar: const Icon(Icons.flight, size: 16), label: Text(name), onPressed: () => _map.flyTo(p, zoom: z)),
            ActionChip(label: const Text("Rotate 45°"), onPressed: () => _map.animateTo(rotation: _map.camera.rotation + 45)),
            ActionChip(label: const Text("North up"), onPressed: _map.resetNorth),
            ActionChip(label: const Text("Fit Iran"), onPressed: () => _map.fitPoints(const <LatLng>[LatLng(25.06, 44.03), LatLng(39.78, 63.32)])),
          ],
        ),
      ],
    ),
  );
}
