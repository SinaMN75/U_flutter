import "package:u/utilities.dart";

import "maps_page.dart";

enum _Viz { heatmap, hexbin, choropleth, flows, lines, patterns, geometry }

/// Heatmap, hexbin, choropleth, flows, styled lines, patterns, text along paths and geometry operations.
class DataVizDemo extends StatefulWidget {
  const DataVizDemo({super.key});

  @override
  State<DataVizDemo> createState() => _DataVizDemoState();
}

class _DataVizDemoState extends State<DataVizDemo> {
  final Random _random = Random(9);
  late final List<LatLng> _points = <LatLng>[
    for (int c = 0; c < 6; c++) ...() {
      final LatLng center = UMapLinks.randomNear(kTehran, 9000, _random);
      return List<LatLng>.generate(400, (_) => UMapLinks.randomNear(center, 2500, _random));
    }(),
    ...List<LatLng>.generate(600, (_) => UMapLinks.randomNear(kTehran, 15000, _random)),
  ];
  late final List<LatLng> _sites = List<LatLng>.generate(25, (_) => UMapLinks.randomNear(kTehran, 12000, _random));
  late final List<List<LatLng>> _cells = UGeo.voronoi(_sites);
  late final List<double> _values = List<double>.generate(25, (_) => _random.nextDouble() * 100);
  late final List<LatLng> _road = <LatLng>[for (int i = 0; i <= 30; i++) UGeo.destination(UGeo.destination(kTehran, 6000, 250), i * 400.0, 60 + 25 * sin(i / 4))];
  _Viz _viz = _Viz.heatmap;
  String? _tapped;

  UGeoFeatureCollection get _districts => UGeoFeatureCollection(<UGeoFeature>[
    for (int i = 0; i < _cells.length; i++)
      UGeoFeature(geometry: UGeoPolygon.simple(_cells[i]), properties: <String, dynamic>{"name": "District ${i + 1}", "value": _values[i]}),
  ]);

  List<Widget> get _layers {
    switch (_viz) {
      case _Viz.heatmap:
        return <Widget>[UMapHeatmapLayer(points: _points)];
      case _Viz.hexbin:
        return <Widget>[UMapHexbinLayer(points: _points, showCounts: true)];
      case _Viz.choropleth:
        return <Widget>[
          UMapChoroplethLayer(features: _districts, valueOf: (UGeoFeature f) => (f.properties["value"] as num).toDouble(), onTap: (UGeoFeature f) => setState(() => _tapped = "${f.name}: ${(f.properties["value"] as double).round()}")),
          UMapLabelLayer(labels: <UMapLabel>[for (int i = 0; i < _cells.length; i++) UMapLabel(point: UGeo.labelPoint(<List<LatLng>>[_cells[i]]), text: "${_values[i].round()}")]),
        ];
      case _Viz.flows:
        return <Widget>[
          UMapFlowLayer(flows: <UMapFlow>[for (int i = 1; i < 12; i++) UMapFlow(from: _sites[0], to: _sites[i], weight: _values[i])]),
        ];
      case _Viz.lines:
        return <Widget>[
          UMapStyledLineLayer(
            lines: <UMapStyledLine>[
              UMapStyledLine(points: _road, values: <double>[for (int i = 0; i < _road.length; i++) 20 + 60 * (0.5 + 0.5 * sin(i / 3))], width: 8, casing: Colors.black54),
              UMapStyledLine(points: _road.map((LatLng p) => UGeo.destination(p, 1500, 330)).toList(), arrows: true, color: const Color(0xFF8E24AA), width: 7),
              UMapStyledLine(points: _road.map((LatLng p) => UGeo.destination(p, 3000, 330)).toList(), marching: true, color: const Color(0xFF00897B)),
            ],
          ),
          UMapAnimatedLine(points: _road.map((LatLng p) => UGeo.destination(p, 4500, 330)).toList(), color: const Color(0xFFE53935)),
          UMapPathTextLayer(
            items: <UMapPathText>[
              UMapPathText(points: _road, text: "Speed-coloured avenue", repeat: 300),
              UMapPathText(points: _road.map((LatLng p) => UGeo.destination(p, 1500, 330)).toList(), text: "بزرگراه نمونه"),
            ],
          ),
          PolylineLayer<Object>(polylines: <Polyline<Object>>[Polyline<Object>(points: UGeo.greatCircle(kTehran, const LatLng(51.5, -0.12)), color: Colors.indigo, strokeWidth: 3, pattern: StrokePattern.dashed(segments: const <double>[8, 6]))]),
        ];
      case _Viz.patterns:
        return <Widget>[
          UMapPatternPolygonLayer(
            polygons: <UMapPatternPolygon>[
              for (final UMapFillPattern p in UMapFillPattern.values)
                UMapPatternPolygon(points: UGeo.circle(UGeo.destination(kTehran, 5000, p.index * 72.0), 2000), pattern: p, color: Colors.primaries[p.index * 3]),
            ],
          ),
        ];
      case _Viz.geometry:
        final List<LatLng> a = UGeo.circle(UGeo.destination(kTehran, 1500, 270), 3000);
        final List<LatLng> b = UGeo.circle(UGeo.destination(kTehran, 1500, 90), 3000);
        final List<List<List<LatLng>>> union = UGeo.union(<List<LatLng>>[a], <List<LatLng>>[b]);
        final List<List<List<LatLng>>> overlap = UGeo.intersection(<List<LatLng>>[a], <List<LatLng>>[b]);
        final List<LatLng> hull = UGeo.convexHull(_sites);
        final List<LatLng> concave = UGeo.concaveHull(_sites, maxEdge: 9000);
        return <Widget>[
          PolygonLayer<Object>(
            polygons: <Polygon<Object>>[
              for (final List<LatLng> c in _cells) Polygon<Object>(points: c, borderColor: Colors.grey, borderStrokeWidth: 1),
              Polygon<Object>(points: hull, borderColor: Colors.purple, borderStrokeWidth: 2, pattern: StrokePattern.dashed(segments: const <double>[6, 4])),
              Polygon<Object>(points: concave, color: Colors.purple.withValues(alpha: 0.08), borderColor: Colors.purple, borderStrokeWidth: 2),
              for (final List<List<LatLng>> u in union) Polygon<Object>(points: u.first, color: Colors.blue.withValues(alpha: 0.15), borderColor: Colors.blue, borderStrokeWidth: 2),
              for (final List<List<LatLng>> o in overlap) Polygon<Object>(points: o.first, color: Colors.red.withValues(alpha: 0.35), borderColor: Colors.red, borderStrokeWidth: 2),
              Polygon<Object>(points: UGeo.bufferLine(_road, 400), color: Colors.green.withValues(alpha: 0.2), borderColor: Colors.green),
            ],
          ),
          PolylineLayer<Object>(polylines: <Polyline<Object>>[Polyline<Object>(points: _road, color: Colors.green.shade800, strokeWidth: 3)]),
          CircleLayer<Object>(circles: <CircleMarker<Object>>[for (final LatLng s in _sites) CircleMarker<Object>(point: s, radius: 4, color: Colors.black)]),
        ];
    }
  }

  @override
  Widget build(BuildContext context) => MapDemoScaffold(
    title: "Data visualisation",
    map: Stack(
      children: <Widget>[
        UMap(center: kTehran, zoom: 11, vectorStyle: UMapVectorStyle.light(), layers: _layers, myLocationButton: false),
        if (_viz == _Viz.choropleth) const Positioned(left: 12, top: 12, child: UMapLegend(colors: uSequentialColors, min: 0, max: 100, title: "Score")),
        if (_viz == _Viz.heatmap) const Positioned(left: 12, top: 12, child: UMapLegend(colors: uHeatColors, min: 0, max: 1, title: "Density")),
      ],
    ),
    panel: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        MapChips<_Viz>(values: _Viz.values, selected: _viz, label: (_Viz v) => v.name, onSelected: (_Viz v) => setState(() => _viz = v)),
        Text(switch (_viz) {
          _Viz.heatmap => "${_points.length} points as a kernel-density heatmap; it re-renders as you move.",
          _Viz.hexbin => "Points aggregated into screen hexagons with counts.",
          _Viz.choropleth => _tapped ?? "Voronoi districts coloured by a value; tap one.",
          _Viz.flows => "Origin → destination arcs with moving particles, width by weight.",
          _Viz.lines => "Speed-coloured road with casing, direction arrows, marching ants, a self-drawing route, text along roads and a great-circle flight line.",
          _Viz.patterns => "Hatch, cross-hatch, dots and stripe fills.",
          _Viz.geometry => "Voronoi cells, convex vs concave hull, union (blue) and intersection (red) of two circles, a 400 m buffer around a road.",
        }, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
