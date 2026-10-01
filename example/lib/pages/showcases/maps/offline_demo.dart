import "package:u/utilities.dart";

import "maps_page.dart";

/// Offline region downloads, the tile cache, offline-only mode and PMTiles archives.
class OfflineDemo extends StatefulWidget {
  const OfflineDemo({super.key});

  @override
  State<OfflineDemo> createState() => _OfflineDemoState();
}

class _OfflineDemoState extends State<OfflineDemo> {
  final MapController _map = MapController();
  final TextEditingController _pmtilesUrl = TextEditingController();
  UMapTileSource _source = UMapTileSource.sentinel2;
  UMapRegionDownload? _download;
  UMapDownloadProgress? _progress;
  List<UMapRegion> _regions = <UMapRegion>[];
  int _cache = 0;
  bool _offlineOnly = false;
  int _maxZoom = 14;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _download?.cancel();
    _map.dispose();
    _pmtilesUrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final List<UMapRegion> regions = await UMaps.regions();
    final int cache = await UMaps.cacheSize();
    if (mounted) {
      setState(() {
        _regions = regions;
        _cache = cache;
      });
    }
  }

  Future<void> _start() async {
    final UMapRegionDownload d = UMaps.downloadRegion(source: _source, bounds: _map.camera.visibleBounds, minZoom: _map.camera.zoom.floor().clamp(0, _maxZoom), maxZoom: _maxZoom, name: "Area ${_regions.length + 1}");
    setState(() => _download = d);
    d.progress.listen((UMapDownloadProgress p) => setState(() => _progress = p));
    await tryMap(d.start);
    setState(() => _download = null);
    await _refresh();
  }

  Future<void> _openPmtiles() async {
    final String url = _pmtilesUrl.text.trim();
    if (url.isEmpty) return;
    final UPmTiles? archive = await tryMap(() => UMaps.pmtilesFromUrl(url));
    if (archive == null) return;
    setState(() => _source = UMapTileSource.pmtiles(archive, id: "pmtiles_${url.hashCode.toUnsigned(32)}"));
    unawaited(_map.flyTo(archive.header.center, zoom: archive.header.centerZoom.toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    final (int tiles, int bytes) = UMaps.estimate(_source, _map.camera.visibleBounds, _map.camera.zoom.floor().clamp(0, _maxZoom), _maxZoom);
    return MapDemoScaffold(
      title: "Offline",
      map: UMap(
        controller: _map,
        center: kTehran,
        zoom: 11,
        source: _source.format == UMapTileFormat.vector ? null : _source,
        vectorStyle: _source.format == UMapTileFormat.vector ? UMapVectorStyle.light() : null,
        vectorSource: _source.format == UMapTileFormat.vector ? _source : null,
        offlineOnly: _offlineOnly,
        onPositionChanged: (_, _) => setState(() {}),
        layers: <Widget>[
          PolygonLayer<Object>(
            polygons: <Polygon<Object>>[
              for (final UMapRegion r in _regions.where((UMapRegion r) => r.sourceId == _source.id))
                Polygon<Object>(points: r.polygon ?? UGeoMath.boundsRing(r.box), borderColor: Colors.green, borderStrokeWidth: 2, color: Colors.green.withValues(alpha: 0.08)),
            ],
          ),
        ],
      ),
      panel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: <Widget>[
          MapChips<UMapTileSource>(
            values: <UMapTileSource>{UMapTileSource.sentinel2, UMapTileSource.terrarium, UMapTileSource.openStreetMap, UMapTileSource.openFreeMap, _source}.toList(),
            selected: _source,
            label: (UMapTileSource s) => "${s.name}${s.bulkDownload ? " ✓" : ""}",
            onSelected: (UMapTileSource s) => setState(() => _source = s),
          ),
          Text(
            _source.bulkDownload ? "${_source.name} allows offline packs (${_source.policy.name})." : "⚠ ${_source.name}: ${_source.note ?? "bulk download not allowed"} — downloading will be refused.",
            style: const TextStyle(fontSize: 12),
          ),
          Row(
            children: <Widget>[
              Text("Max zoom $_maxZoom", style: const TextStyle(fontSize: 12)),
              Expanded(child: Slider(value: _maxZoom.toDouble(), min: 8, max: 17, divisions: 9, onChanged: (double v) => setState(() => _maxZoom = v.round()))),
              Text("$tiles tiles ≈ ${(bytes / 1048576).toStringAsFixed(1)} MB", style: const TextStyle(fontSize: 12)),
            ],
          ),
          if (_download == null)
            FilledButton.icon(icon: const Icon(Icons.download), label: const Text("Download visible area"), onPressed: _start)
          else
            Row(
              children: <Widget>[
                Expanded(child: LinearProgressIndicator(value: _progress?.fraction)),
                const SizedBox(width: 8),
                Text("${_progress?.done ?? 0}/${_progress?.total ?? tiles}", style: const TextStyle(fontSize: 12)),
                IconButton(
                  icon: Icon(_download!.isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: () => setState(() => _download!.isPaused ? _download!.resume() : _download!.pause()),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: _download!.cancel),
              ],
            ),
          SwitchListTile(dense: true, title: const Text("Offline only (no network)"), value: _offlineOnly, onChanged: (bool v) => setState(() => _offlineOnly = v)),
          Row(
            children: <Widget>[
              Text("Cache ${(_cache / 1048576).toStringAsFixed(1)} MB", style: const TextStyle(fontSize: 12)),
              TextButton(
                onPressed: () async {
                  await UMaps.clearCache();
                  await _refresh();
                },
                child: const Text("Clear cache"),
              ),
            ],
          ),
          for (final UMapRegion r in _regions)
            ListTile(
              dense: true,
              leading: Icon(r.complete ? Icons.offline_pin : Icons.downloading),
              title: Text("${r.name} · ${r.sourceId}"),
              subtitle: Text("${r.tiles} tiles · ${(r.bytes / 1048576).toStringAsFixed(1)} MB · z${r.minZoom}–${r.maxZoom}"),
              onTap: () => _map.fitBoundsAnimated(r.box),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await UMaps.deleteRegion(r.id);
                  await _refresh();
                },
              ),
            ),
          TextField(
            controller: _pmtilesUrl,
            decoration: InputDecoration(
              isDense: true,
              hintText: "URL of a .pmtiles file (raster, or OpenMapTiles vector)",
              suffixIcon: IconButton(icon: const Icon(Icons.open_in_browser), onPressed: _openPmtiles),
            ),
          ),
        ],
      ),
    );
  }
}
