import "package:u/utilities.dart";

import "data_viz_demo.dart";
import "draw_demo.dart";
import "location_demo.dart";
import "markers_demo.dart";
import "offline_demo.dart";
import "routing_demo.dart";
import "search_demo.dart";
import "styles_demo.dart";

/// Tehran, where the demos start.
const LatLng kTehran = LatLng(35.6997, 51.3380);

/// Runs [action] and shows any error as a toast (online services can be busy or offline).
Future<T?> tryMap<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Object catch (e) {
    UToast.error(message: "$e".length > 160 ? "${"$e".substring(0, 160)}…" : "$e");
    return null;
  }
}

/// Full-screen map demo: app bar, the map, and an optional panel of controls under it.
class MapDemoScaffold extends StatelessWidget {
  const MapDemoScaffold({required this.title, required this.map, this.panel, this.actions = const <Widget>[], super.key});

  final String title;
  final Widget map;
  final Widget? panel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: Column(
      children: <Widget>[
        Expanded(child: map),
        if (panel != null)
          Material(
            elevation: 6,
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: panel),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Horizontal chips to pick one option.
class MapChips<T> extends StatelessWidget {
  const MapChips({required this.values, required this.selected, required this.label, required this.onSelected, super.key});

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final void Function(T value) onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      spacing: 6,
      children: <Widget>[for (final T v in values) ChoiceChip(label: Text(label(v)), selected: v == selected, onSelected: (_) => onSelected(v))],
    ),
  );
}

/// Every map feature of u, grouped into runnable showcases.
class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  static final List<(String, String, IconData, Widget Function())> _demos = <(String, String, IconData, Widget Function())>[
    ("Styles & camera", "Free raster presets, vector maps (built-in + OpenFreeMap Liberty), dark/grayscale filters, hillshade, contours, tilt, compare swipe, mini-map, fly-to", Icons.layers, () => const StylesDemo()),
    ("Markers", "Clusters (5k), canvas icons (2k), moving vehicles, draggable pins with snap-to-road, collision labels, info windows, pulse/drop/bounce, lasso select", Icons.place, () => const MarkersDemo()),
    ("Draw & measure", "Points, lines, polygons, rectangles, circles, freehand, vertex editing, measure distance/area, undo/redo, GeoJSON, annotated screenshots", Icons.draw, () => const DrawDemo()),
    ("Data visualisation", "Heatmap, hexbin, choropleth + legend, flow arcs, speed-coloured & animated lines, hatch fills, text along roads, Voronoi, hulls, buffers, unions", Icons.insights, () => const DataVizDemo()),
    ("Location & tracking", "Blue dot + heading, follow modes, Kalman smoothing, track recorder + GPX, polygon geofences, speed alert, playback with time slider", Icons.my_location, () => const LocationDemo()),
    ("Search & places", "Autocomplete, search, reverse geocoding, nearby places, saved lists, recents, share links, paste any map link, offline Persian search", Icons.search, () => const SearchDemo()),
    ("Routing & navigation", "Car/bike/foot routes, alternatives, steps (EN/FA), elevation profile, turn-by-turn simulation, isochrones, best stop order, offline router", Icons.directions, () => const RoutingDemo()),
    ("Offline", "Download regions with pause/resume, along-route packs, cache size, offline-only mode, PMTiles archives (file / URL / bundled)", Icons.download_for_offline, () => const OfflineDemo()),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(title: const Text("Maps")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          UTextBodySmall(
            "Everything is pure Dart on top of flutter_map. Online parts use free public servers that are fine for testing; read MAP_SERVICES.md in the package root before shipping.",
            maxLines: 5,
            color: scheme.onSurfaceVariant,
          ).pSymmetric(horizontal: 4, vertical: 8),
          for (final (String title, String subtitle, IconData icon, Widget Function() page) in _demos)
            Card(
              child: ListTile(
                leading: Icon(icon, color: scheme.primary),
                title: Text(title),
                subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => UNavigator.push<void>(page()),
              ),
            ),
        ],
      ),
    );
  }
}
