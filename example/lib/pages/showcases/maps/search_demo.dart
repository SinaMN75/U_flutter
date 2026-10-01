import "package:u/utilities.dart";

import "maps_page.dart";

/// Search, reverse geocoding, nearby places, saved places, links and an offline index.
class SearchDemo extends StatefulWidget {
  const SearchDemo({super.key});

  @override
  State<SearchDemo> createState() => _SearchDemoState();
}

class _SearchDemoState extends State<SearchDemo> {
  final MapController _map = MapController();
  final UMapPopupController _popup = UMapPopupController();
  final TextEditingController _offlineQuery = TextEditingController();
  final UMapSearchIndex<String> _index = UMapSearchIndex<String>()
    ..add("azadi", kTehran, <String>["برج آزادی", "Azadi Tower"], category: "landmark")
    ..add("milad", const LatLng(35.7448, 51.3753), <String>["برج میلاد", "Milad Tower"], category: "landmark")
    ..add("bazaar", const LatLng(35.6750, 51.4200), <String>["بازار بزرگ تهران", "Grand Bazaar"], category: "shopping")
    ..add("tabiat", const LatLng(35.7536, 51.4210), <String>["پل طبیعت", "Tabiat Bridge"], category: "landmark")
    ..add("golestan", const LatLng(35.6800, 51.4204), <String>["کاخ گلستان", "Golestan Palace"], category: "museum")
    ..add("darband", const LatLng(35.8247, 51.4270), <String>["دربند", "Darband"], category: "park");
  List<UMapPlace> _places = <UMapPlace>[];
  List<UMapSearchHit<String>> _offline = <UMapSearchHit<String>>[];
  UMapPoiCategory _category = UMapPoiCategory.cafe;
  bool _busy = false;

  @override
  void dispose() {
    _map.dispose();
    _popup.dispose();
    _offlineQuery.dispose();
    super.dispose();
  }

  void _show(UMapPlace p) {
    unawaited(_map.flyTo(p.point, zoom: 16));
    _popup.show(
      p.point,
      (BuildContext context) => UMapInfoWindow(
        title: p.label,
        subtitle: p.displayName ?? p.tags["opening_hours"],
        onClose: _popup.hide,
        actions: <Widget>[
          TextButton(onPressed: () => UMaps.savePlace(p, list: "Favourites"), child: const Text("Save")),
          TextButton(onPressed: () => UMaps.share(p.point, label: p.label), child: const Text("Share")),
          TextButton(onPressed: () => UMaps.openInMapsApp(p.point, label: p.label), child: const Text("Open in app")),
        ],
      ),
    );
  }

  Future<void> _reverse(LatLng p) async {
    final UMapPlace? place = await tryMap<UMapPlace?>(() => UMaps.reverse(p));
    if (place != null) _show(place);
  }

  Future<void> _nearby() async {
    setState(() => _busy = true);
    final List<UMapPlace>? found = await tryMap(() => UMaps.nearby(_map.camera.center, <UMapPoiCategory>[_category], persianNames: true));
    setState(() {
      _busy = false;
      _places = found ?? <UMapPlace>[];
    });
    if (_places.isNotEmpty) unawaited(_map.fitPoints(_places.map((UMapPlace p) => p.point).toList()));
  }

  Future<void> _pasteLink() async {
    final String? text = await UClipboard.getText();
    final (LatLng, double?)? hit = text == null ? null : UMaps.parseLink(text, reference: _map.camera.center);
    if (hit == null) return UToast.info(message: "No location found in the clipboard");
    _show(UMapPlace(name: "Pasted location", point: hit.$1, displayName: UGeo.toDms(hit.$1)));
  }

  @override
  Widget build(BuildContext context) => MapDemoScaffold(
    title: "Search & places",
    actions: <Widget>[
      IconButton(tooltip: "Paste a map link", icon: const Icon(Icons.link), onPressed: _pasteLink),
      IconButton(
        tooltip: "Saved places",
        icon: const Icon(Icons.bookmarks_outlined),
        onPressed: () async {
          final List<(String, Color, UMapPlace)> saved = await UMaps.savedPlaces();
          setState(() => _places = saved.map(((String, Color, UMapPlace) e) => e.$3).toList());
        },
      ),
    ],
    map: UMap(
      controller: _map,
      center: kTehran,
      zoom: 13,
      onLongPress: (_, LatLng p) => _reverse(p),
      onTap: (_, _) => _popup.hide(),
      layers: <Widget>[
        MarkerLayer(
          markers: <Marker>[
            for (final UMapPlace p in _places)
              Marker(
                point: p.point,
                width: 34,
                height: 34,
                alignment: Alignment.topCenter,
                child: GestureDetector(onTap: () => _show(p), child: Icon(_category.icon, color: const Color(0xFF6A1B9A))),
              ),
          ],
        ),
      ],
      topLayers: <Widget>[UMapPopupLayer(controller: _popup)],
      controls: <Widget>[
        Positioned(left: 12, right: 12, top: 12, child: UMapSearchBar(near: kTehran, hint: "Search (try “میدان آزادی” or a Plus Code)", onSelected: _show)),
      ],
    ),
    panel: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        const Text("Long-press the map for its address. Pick a category for places around the centre (Overpass).", style: TextStyle(fontSize: 12)),
        Row(
          children: <Widget>[
            Expanded(
              child: MapChips<UMapPoiCategory>(values: UMapPoiCategory.values, selected: _category, label: (UMapPoiCategory c) => c.persian, onSelected: (UMapPoiCategory c) => setState(() => _category = c)),
            ),
            IconButton(icon: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore), onPressed: _nearby),
          ],
        ),
        TextField(
          controller: _offlineQuery,
          decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.offline_bolt_outlined), hintText: "Offline search (typos, ي/ی, ك/ک ok): ازادي, milad towr…"),
          onChanged: (String q) => setState(() => _offline = _index.search(q, near: _map.camera.center)),
        ),
        for (final UMapSearchHit<String> h in _offline.take(4))
          ListTile(
            dense: true,
            title: Text(h.item),
            subtitle: Text("score ${h.score.toStringAsFixed(2)} · ${UMaps.formatDistance(h.distance ?? 0, persian: true)}"),
            onTap: () => _show(UMapPlace(name: h.item, point: h.point, source: "offline")),
          ),
      ],
    ),
  );
}
