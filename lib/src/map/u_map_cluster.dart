import "dart:math" as math;

import "package:u/utilities.dart";

/// A cluster (several items) or a single item at some zoom.
class UMapCluster<T> {
  const UMapCluster({required this.id, required this.point, required this.count, this.item, this.expansionZoom = 0, this.parentId});

  /// Stable id within a zoom (single items: −(index+1)).
  final int id;
  final LatLng point;
  final int count;

  /// The item when this is not a cluster.
  final T? item;

  /// Zoom at which this cluster splits.
  final int expansionZoom;

  /// The cluster this one merges into one zoom out (for split/merge animations).
  final int? parentId;

  bool get isCluster => count > 1;
}

class _CPoint {
  _CPoint(this.x, this.y, this.count, this.id, this.zoom, {this.index = -1});

  final double x;
  final double y;
  final int count;
  final int id;
  final int index;
  int zoom;
  int parent = -1;
  int expansion = 0;
}

/// Hierarchical marker clustering (Supercluster algorithm): build once, ask for clusters in view at any zoom in microseconds.
class UMapClusterIndex<T> {
  UMapClusterIndex(List<T> items, LatLng Function(T item) pointOf, {this.radius = 60, this.minZoom = 0, this.maxZoom = 17, this.extent = 256, this.minPoints = 2})
    : items = List<T>.unmodifiable(items) {
    final List<_CPoint> pts = <_CPoint>[
      for (int i = 0; i < items.length; i++) _CPoint(_lngX(pointOf(items[i]).longitude), _latY(pointOf(items[i]).latitude), 1, -(i + 1), maxZoom + 1, index: i),
    ];
    _levels[maxZoom + 1] = (pts, _tree(pts));
    for (int z = maxZoom; z >= minZoom; z--) {
      final List<_CPoint> next = _cluster(_levels[z + 1]!.$1, _levels[z + 1]!.$2, z);
      _levels[z] = (next, _tree(next));
    }
  }

  final List<T> items;

  /// Cluster radius in screen pixels.
  final double radius;
  final int minZoom;
  final int maxZoom;
  final int extent;
  final int minPoints;
  final Map<int, (List<_CPoint>, UKdTree)> _levels = <int, (List<_CPoint>, UKdTree)>{};
  final Map<int, _CPoint> _byId = <int, _CPoint>{};

  static double _lngX(double lng) => lng / 360 + 0.5;

  static double _latY(double lat) {
    final double s = math.sin(lat.clamp(-85.0511, 85.0511) * math.pi / 180);
    final double y = 0.5 - 0.25 * math.log((1 + s) / (1 - s)) / math.pi;
    return y.clamp(0, 1);
  }

  static double _xLng(double x) => (x - 0.5) * 360;

  static double _yLat(double y) => 360 * math.atan(math.exp((180 - y * 360) * math.pi / 180)) / math.pi - 90;

  static UKdTree _tree(List<_CPoint> pts) => UKdTree(pts.map((_CPoint p) => p.x).toList(), pts.map((_CPoint p) => p.y).toList());

  List<_CPoint> _cluster(List<_CPoint> points, UKdTree tree, int zoom) {
    final double r = radius / (extent * math.pow(2, zoom));
    final List<_CPoint> out = <_CPoint>[];
    for (int i = 0; i < points.length; i++) {
      final _CPoint p = points[i];
      if (p.zoom <= zoom) continue;
      p.zoom = zoom;
      final List<int> neighbors = tree.within(p.x, p.y, r);
      int count = p.count;
      for (final int n in neighbors) {
        if (points[n].zoom > zoom) count += points[n].count;
      }
      if (count >= minPoints && count > p.count) {
        double wx = p.x * p.count;
        double wy = p.y * p.count;
        final int id = i * 64 + zoom + 1;
        for (final int n in neighbors) {
          final _CPoint b = points[n];
          if (b.zoom <= zoom) continue;
          b.zoom = zoom;
          wx += b.x * b.count;
          wy += b.y * b.count;
          b.parent = id;
        }
        p.parent = id;
        final _CPoint c = _CPoint(wx / count, wy / count, count, id, maxZoom + 1)..expansion = zoom + 1;
        _byId[id] = c;
        out.add(c);
      } else {
        out.add(p);
      }
    }
    return out;
  }

  /// Clusters and single items inside [bounds] at [zoom].
  List<UMapCluster<T>> clusters(LatLngBounds bounds, double zoom) {
    final int z = zoom.floor().clamp(minZoom, maxZoom + 1);
    final (List<_CPoint> pts, UKdTree tree) = _levels[z]!;
    final List<int> ids = tree.range(_lngX(bounds.west), _latY(bounds.north), _lngX(bounds.east), _latY(bounds.south));
    return ids.map((int i) {
      final _CPoint p = pts[i];
      return UMapCluster<T>(
        id: p.id,
        point: UGeoMath.safe(_yLat(p.y), _xLng(p.x)),
        count: p.count,
        item: p.index >= 0 ? items[p.index] : null,
        expansionZoom: p.count > 1 ? p.expansion : maxZoom + 1,
        parentId: p.parent >= 0 ? p.parent : null,
      );
    }).toList();
  }

  /// Every item inside a cluster.
  List<T> leaves(int clusterId) {
    final List<T> out = <T>[];
    void walk(int id, int childLevel) {
      if (childLevel > maxZoom + 1) return;
      for (final _CPoint p in _levels[childLevel]!.$1) {
        if (p.parent != id) continue;
        if (p.index >= 0) {
          out.add(items[p.index]);
        } else if (p.id != id) {
          walk(p.id, p.expansion);
        }
      }
    }

    final _CPoint? c = _byId[clusterId];
    if (c != null) walk(clusterId, c.expansion);
    return out;
  }
}
