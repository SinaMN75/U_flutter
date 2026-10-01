import "dart:ui" as ui;

import "package:u/utilities.dart";

import "maps_page.dart";

enum _Mode { clusters, icons, vehicles, draggable, labels, lasso }

/// Clustering, canvas markers, moving vehicles, draggable pins, labels, popups, effects and lasso.
class MarkersDemo extends StatefulWidget {
  const MarkersDemo({super.key});

  @override
  State<MarkersDemo> createState() => _MarkersDemoState();
}

class _MarkersDemoState extends State<MarkersDemo> {
  final MapController _map = MapController();
  final UMapPopupController _popup = UMapPopupController();
  final Random _random = Random(4);
  late final List<LatLng> _points = List<LatLng>.generate(5000, (_) => UMapLinks.randomNear(kTehran, 18000, _random));
  late List<(LatLng, double)> _vehicles = List<(LatLng, double)>.generate(12, (_) => (UMapLinks.randomNear(kTehran, 4000, _random), _random.nextDouble() * 360));
  late final ui.Image _pin = UMapMarkerIcon.pin(Icons.store, color: const Color(0xFF8E24AA));
  final Map<String, LatLng> _dragged = <String, LatLng>{"A": kTehran, "B": const LatLng(35.71, 51.36)};
  List<LatLng> _selected = <LatLng>[];
  _Mode _mode = _Mode.clusters;
  bool _snap = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_mode != _Mode.vehicles) return;
      setState(() {
        _vehicles = _vehicles.map(((LatLng, double) v) {
          final double heading = (v.$2 + (_random.nextDouble() - 0.5) * 40) % 360;
          return (UGeo.destination(v.$1, 60 + _random.nextDouble() * 60, heading), heading);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _popup.dispose();
    _map.dispose();
    super.dispose();
  }

  void _showPopup(LatLng p, String title) => _popup.show(
    p,
    (BuildContext context) => UMapInfoWindow(
      title: title,
      subtitle: "${UGeo.toDms(p)}\n${UGeo.plusCode(p)}",
      leading: const Icon(Icons.storefront),
      onClose: _popup.hide,
      actions: <Widget>[
        TextButton(onPressed: () => UMaps.share(p, label: title), child: const Text("Share")),
        TextButton(onPressed: () => UMaps.openDirections(p), child: const Text("Directions")),
      ],
    ),
  );

  List<Widget> get _layers => switch (_mode) {
    _Mode.clusters => <Widget>[
      UMapClusterLayer<LatLng>(
        items: _points,
        pointOf: (LatLng p) => p,
        markerBuilder: (BuildContext context, LatLng p) => const Icon(Icons.location_on, color: Color(0xFFE53935), size: 36),
        anchor: const Offset(0.5, 1),
        onTap: (LatLng p) => _showPopup(p, "Shop"),
      ),
    ],
    _Mode.icons => <Widget>[
      UMapIconMarkersLayer(
        markers: <UMapIconMarker>[for (final LatLng p in _points.take(2000)) UMapIconMarker(point: p, image: _pin, data: p)],
        onTap: (UMapIconMarker m) => _showPopup(m.point, "Canvas marker"),
      ),
    ],
    _Mode.vehicles => <Widget>[
      UMapMovingMarkersLayer(
        markers: <UMapMovingMarker>[
          for (int i = 0; i < _vehicles.length; i++)
            UMapMovingMarker(
              id: i,
              point: _vehicles[i].$1,
              heading: _vehicles[i].$2,
              label: "Car $i",
              child: i == 0 ? const UMapPulse(child: Icon(Icons.navigation, color: Color(0xFF1A73E8), size: 30)) : const Icon(Icons.navigation, color: Color(0xFF0B6E4F), size: 28),
            ),
        ],
        onTap: (UMapMovingMarker m) => _showPopup(_vehicles[m.id as int].$1, "Car ${m.id}"),
      ),
    ],
    _Mode.draggable => <Widget>[
      UMapDraggableMarkersLayer(
        markers: <UMapDraggableMarker>[
          for (final MapEntry<String, LatLng> e in _dragged.entries)
            UMapDraggableMarker(id: e.key, point: e.value, child: UMapDropIn(child: Icon(Icons.location_on, size: 44, color: e.key == "A" ? Colors.green : Colors.red))),
        ],
        snap: _snap ? UMaps.snapToRoad : null,
        onDragEnd: (Object id, LatLng p) => setState(() => _dragged[id as String] = p),
      ),
    ],
    _Mode.labels => <Widget>[
      UMapLabelLayer(labels: <UMapLabel>[for (int i = 0; i < 300; i++) UMapLabel(point: _points[i], text: i.isEven ? "Shop $i" : "فروشگاه $i", priority: (300 - i).toDouble())]),
    ],
    _Mode.lasso => <Widget>[
      MarkerLayer(
        markers: <Marker>[
          for (final LatLng p in _points.take(800))
            Marker(
              point: p,
              width: 10,
              height: 10,
              child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: _selected.contains(p) ? Colors.orange : Colors.blueGrey)),
            ),
        ],
      ),
      UMapLassoLayer(onSelected: (List<LatLng> polygon) => setState(() => _selected = UGeo.inside(_points.take(800).toList(), polygon))),
    ],
  };

  @override
  Widget build(BuildContext context) => MapDemoScaffold(
    title: "Markers",
    map: UMap(
      controller: _map,
      center: kTehran,
      zoom: 11,
      interactive: _mode != _Mode.lasso,
      layers: _layers,
      topLayers: <Widget>[UMapPopupLayer(controller: _popup)],
      onTap: (_, _) => _popup.hide(),
    ),
    panel: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        MapChips<_Mode>(
          values: _Mode.values,
          selected: _mode,
          label: (_Mode m) => m.name,
          onSelected: (_Mode m) => setState(() {
            _mode = m;
            _popup.hide();
          }),
        ),
        Text(switch (_mode) {
          _Mode.clusters => "5,000 points clustered on the fly; tap a bubble to zoom into it, tap a pin for an info window.",
          _Mode.icons => "2,000 markers drawn in one canvas pass (no widget per marker).",
          _Mode.vehicles => "Vehicles glide to new GPS points and turn along the shortest angle; the first one pulses.",
          _Mode.draggable => "Long-press a pin, then drag. Snap-to-road moves the drop onto the nearest road (OSRM).",
          _Mode.labels => "300 labels; overlapping ones hide by priority and reappear as you zoom.",
          _Mode.lasso => "Map dragging is off: draw a loop to select points (${_selected.length} selected).",
        }, style: const TextStyle(fontSize: 12)),
        if (_mode == _Mode.draggable) SwitchListTile(dense: true, title: const Text("Snap to road"), value: _snap, onChanged: (bool v) => setState(() => _snap = v)),
        if (_mode == _Mode.draggable) Text("A: ${UGeo.toDms(_dragged["A"]!)}  ·  ${UMaps.formatDistance(UGeo.distance(_dragged["A"]!, _dragged["B"]!))} to B", style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
