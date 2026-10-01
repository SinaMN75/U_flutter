import "dart:math" as math;

import "package:u/utilities.dart";

/// Static 2-D KD tree on plain x/y numbers (used by the clustering engines).
class UKdTree {
  UKdTree(List<double> xs, List<double> ys, {this.nodeSize = 64})
    : _ids = List<int>.generate(xs.length, (int i) => i),
      _x = List<double>.of(xs),
      _y = List<double>.of(ys) {
    _sort(0, _ids.length - 1, 0);
  }

  final int nodeSize;
  final List<int> _ids;
  final List<double> _x;
  final List<double> _y;

  void _sort(int left, int right, int axis) {
    if (right - left <= nodeSize) return;
    final int m = (left + right) >> 1;
    _select(m, left, right, axis);
    _sort(left, m - 1, 1 - axis);
    _sort(m + 1, right, 1 - axis);
  }

  void _select(int k, int left, int right, int axis) {
    final List<double> coords = axis == 0 ? _x : _y;
    while (right > left) {
      final double pivot = coords[k];
      int i = left;
      int j = right;
      _swap(left, k);
      if (coords[right] > pivot) _swap(left, right);
      while (i < j) {
        _swap(i, j);
        i++;
        j--;
        while (coords[i] < pivot) {
          i++;
        }
        while (coords[j] > pivot) {
          j--;
        }
      }
      if (coords[left] == pivot) {
        _swap(left, j);
      } else {
        j++;
        _swap(j, right);
      }
      if (j <= k) left = j + 1;
      if (k <= j) right = j - 1;
    }
  }

  void _swap(int i, int j) {
    final int id = _ids[i];
    _ids[i] = _ids[j];
    _ids[j] = id;
    final double x = _x[i];
    _x[i] = _x[j];
    _x[j] = x;
    final double y = _y[i];
    _y[i] = _y[j];
    _y[j] = y;
  }

  /// Original indexes inside a box.
  List<int> range(double minX, double minY, double maxX, double maxY) {
    final List<int> result = <int>[];
    final List<int> stack = <int>[0, _ids.length - 1, 0];
    while (stack.isNotEmpty) {
      final int axis = stack.removeLast();
      final int right = stack.removeLast();
      final int left = stack.removeLast();
      if (right - left <= nodeSize) {
        for (int i = left; i <= right; i++) {
          if (_x[i] >= minX && _x[i] <= maxX && _y[i] >= minY && _y[i] <= maxY) result.add(_ids[i]);
        }
        continue;
      }
      final int m = (left + right) >> 1;
      final double x = _x[m];
      final double y = _y[m];
      if (x >= minX && x <= maxX && y >= minY && y <= maxY) result.add(_ids[m]);
      if (axis == 0 ? minX <= x : minY <= y) stack.addAll(<int>[left, m - 1, 1 - axis]);
      if (axis == 0 ? maxX >= x : maxY >= y) stack.addAll(<int>[m + 1, right, 1 - axis]);
    }
    return result;
  }

  /// Original indexes within [r] (same units as x/y) of a point.
  List<int> within(double qx, double qy, double r) {
    final List<int> result = <int>[];
    final double r2 = r * r;
    final List<int> stack = <int>[0, _ids.length - 1, 0];
    while (stack.isNotEmpty) {
      final int axis = stack.removeLast();
      final int right = stack.removeLast();
      final int left = stack.removeLast();
      if (right - left <= nodeSize) {
        for (int i = left; i <= right; i++) {
          final double dx = _x[i] - qx;
          final double dy = _y[i] - qy;
          if (dx * dx + dy * dy <= r2) result.add(_ids[i]);
        }
        continue;
      }
      final int m = (left + right) >> 1;
      final double x = _x[m];
      final double y = _y[m];
      final double dx = x - qx;
      final double dy = y - qy;
      if (dx * dx + dy * dy <= r2) result.add(_ids[m]);
      if (axis == 0 ? qx - r <= x : qy - r <= y) stack.addAll(<int>[left, m - 1, 1 - axis]);
      if (axis == 0 ? qx + r >= x : qy + r >= y) stack.addAll(<int>[m + 1, right, 1 - axis]);
    }
    return result;
  }
}

/// Fast static index of point items: box queries, radius queries and nearest neighbours. Build once, query often.
class UGeoKdIndex<T> {
  UGeoKdIndex(List<T> items, LatLng Function(T item) pointOf)
    : items = List<T>.unmodifiable(items),
      _points = items.map(pointOf).toList() {
    _tree = UKdTree(_points.map((LatLng p) => p.longitude).toList(), _points.map((LatLng p) => p.latitude).toList());
  }

  final List<T> items;
  final List<LatLng> _points;
  late final UKdTree _tree;

  /// Items inside a box.
  List<T> inBounds(LatLngBounds b) => _tree.range(b.west, b.south, b.east, b.north).map((int i) => items[i]).toList();

  /// Items within [meters] of a point.
  List<T> within(LatLng center, double meters) {
    final double dLat = meters / 111320.0;
    final double dLng = meters / (111320.0 * math.max(0.01, math.cos(center.latitude * math.pi / 180)));
    return _tree
        .range(center.longitude - dLng, center.latitude - dLat, center.longitude + dLng, center.latitude + dLat)
        .where((int i) => UGeoMath.distance(center, _points[i]) <= meters)
        .map((int i) => items[i])
        .toList();
  }

  /// The [k] nearest items (closest first), optionally no farther than [maxMeters].
  List<T> nearest(LatLng center, {int k = 1, double? maxMeters}) {
    if (items.isEmpty) return <T>[];
    double radius = maxMeters ?? 500;
    while (true) {
      final List<int> found = _rangeIndexes(center, radius);
      if (found.length >= k || (maxMeters != null && radius >= maxMeters) || radius > 2.1e7) {
        found.sort((int a, int b) => UGeoMath.distance(center, _points[a]).compareTo(UGeoMath.distance(center, _points[b])));
        return found.where((int i) => maxMeters == null || UGeoMath.distance(center, _points[i]) <= maxMeters).take(k).map((int i) => items[i]).toList();
      }
      radius *= 4;
      if (maxMeters != null) radius = math.min(radius, maxMeters);
    }
  }

  List<int> _rangeIndexes(LatLng c, double meters) {
    final double dLat = meters / 111320.0;
    final double dLng = meters / (111320.0 * math.max(0.01, math.cos(c.latitude * math.pi / 180)));
    return _tree.range(c.longitude - dLng, c.latitude - dLat, c.longitude + dLng, c.latitude + dLat).where((int i) => UGeoMath.distance(c, _points[i]) <= meters).toList();
  }
}

/// Static R-tree of items with a box (shapes, features): fast "what is here" queries for thousands of shapes.
class UGeoRTree<T> {
  UGeoRTree(List<T> items, LatLngBounds Function(T item) boundsOf, {int nodeSize = 16}) {
    final List<_RNode<T>> leaves = <_RNode<T>>[for (final T item in items) _RNode<T>.leaf(item, _rect(boundsOf(item)))];
    _root = leaves.isEmpty ? null : _pack(leaves, nodeSize);
    length = items.length;
  }

  _RNode<T>? _root;

  /// Number of items.
  late final int length;

  static Rect _rect(LatLngBounds b) => Rect.fromLTRB(b.west, b.south, b.east, b.north);

  static _RNode<T> _pack<T>(List<_RNode<T>> nodes, int size) {
    List<_RNode<T>> level = nodes;
    while (level.length > 1) {
      final int slices = math.sqrt((level.length / size).ceil()).ceil();
      level.sort((_RNode<T> a, _RNode<T> b) => a.box.center.dx.compareTo(b.box.center.dx));
      final int perSlice = (level.length / slices).ceil();
      final List<_RNode<T>> next = <_RNode<T>>[];
      for (int s = 0; s < level.length; s += perSlice) {
        final List<_RNode<T>> slice = level.sublist(s, math.min(level.length, s + perSlice))..sort((_RNode<T> a, _RNode<T> b) => a.box.center.dy.compareTo(b.box.center.dy));
        for (int i = 0; i < slice.length; i += size) {
          next.add(_RNode<T>.branch(slice.sublist(i, math.min(slice.length, i + size))));
        }
      }
      level = next;
    }
    return level.first;
  }

  /// Items whose box overlaps [bounds].
  List<T> search(LatLngBounds bounds) {
    final Rect q = _rect(bounds);
    final List<T> out = <T>[];
    final List<_RNode<T>> stack = <_RNode<T>>[if (_root != null) _root!];
    while (stack.isNotEmpty) {
      final _RNode<T> n = stack.removeLast();
      if (!n.box.overlaps(q) && !_touches(n.box, q)) continue;
      if (n.isLeaf) {
        out.add(n.item as T);
      } else {
        stack.addAll(n.children);
      }
    }
    return out;
  }

  static bool _touches(Rect a, Rect b) => a.left <= b.right && b.left <= a.right && a.top <= b.bottom && b.top <= a.bottom;

  /// Items whose box contains a point (filter further with exact geometry).
  List<T> at(LatLng p) => search(LatLngBounds(p, p));

  /// Items by box distance to a point (closest first).
  List<T> nearest(LatLng p, {int k = 1}) {
    final double scale = math.cos(p.latitude * math.pi / 180);
    double boxDistance(Rect r) {
      final double dx = math.max(0, math.max(r.left - p.longitude, p.longitude - r.right)) * scale;
      final double dy = math.max(0, math.max(r.top - p.latitude, p.latitude - r.bottom));
      return dx * dx + dy * dy;
    }

    final UGeoHeap<(double, _RNode<T>)> heap = UGeoHeap<(double, _RNode<T>)>(((double, _RNode<T>) a, (double, _RNode<T>) b) => a.$1.compareTo(b.$1));
    if (_root != null) heap.push((boxDistance(_root!.box), _root!));
    final List<T> out = <T>[];
    while (heap.isNotEmpty && out.length < k) {
      final (double _, _RNode<T> n) = heap.pop();
      if (n.isLeaf) {
        out.add(n.item as T);
      } else {
        for (final _RNode<T> c in n.children) {
          heap.push((boxDistance(c.box), c));
        }
      }
    }
    return out;
  }
}

class _RNode<T> {
  _RNode.leaf(this.item, this.box) : children = const <Never>[], isLeaf = true;

  _RNode.branch(this.children) : item = null, isLeaf = false, box = children.map((_RNode<T> c) => c.box).reduce((Rect a, Rect b) => a.expandToInclude(b));

  final T? item;
  final Rect box;
  final List<_RNode<T>> children;
  final bool isLeaf;
}

/// Growable index of point items: add/remove any time (live vehicles, user pins) and query by box or radius.
class UGeoQuadtree<T> {
  UGeoQuadtree({this.capacity = 8, this.maxDepth = 18}) : _root = _QNode<T>(const Rect.fromLTRB(-180, -90, 180, 90), 0);

  final int capacity;
  final int maxDepth;
  final _QNode<T> _root;
  int _length = 0;

  /// Number of items.
  int get length => _length;

  /// Adds an item at a point.
  void add(T item, LatLng point) {
    _root.insert(item, point, capacity, maxDepth);
    _length++;
  }

  /// Removes an item (matched with ==) at its point; true when found.
  bool remove(T item, LatLng point) {
    final bool done = _root.remove(item, point);
    if (done) _length--;
    return done;
  }

  /// Moves an item from one point to another.
  void move(T item, LatLng from, LatLng to) {
    remove(item, from);
    add(item, to);
  }

  /// Removes everything.
  void clear() {
    _root
      ..items.clear()
      ..children = null;
    _length = 0;
  }

  /// Items inside a box.
  List<T> inBounds(LatLngBounds b) {
    final List<T> out = <T>[];
    _root.query(Rect.fromLTRB(b.west, b.south, b.east, b.north), out);
    return out;
  }

  /// Items within [meters] of a point.
  List<T> within(LatLng center, double meters) {
    final double dLat = meters / 111320.0;
    final double dLng = meters / (111320.0 * math.max(0.01, math.cos(center.latitude * math.pi / 180)));
    final List<(T, LatLng)> found = <(T, LatLng)>[];
    _root.queryWithPoints(Rect.fromLTRB(center.longitude - dLng, center.latitude - dLat, center.longitude + dLng, center.latitude + dLat), found);
    return found.where(((T, LatLng) e) => UGeoMath.distance(center, e.$2) <= meters).map(((T, LatLng) e) => e.$1).toList();
  }
}

class _QNode<T> {
  _QNode(this.box, this.depth);

  final Rect box;
  final int depth;
  final List<(T, LatLng)> items = <(T, LatLng)>[];
  List<_QNode<T>>? children;

  bool _contains(Rect r, LatLng p) => p.longitude >= r.left && p.longitude <= r.right && p.latitude >= r.top && p.latitude <= r.bottom;

  void insert(T item, LatLng p, int capacity, int maxDepth) {
    if (children != null) {
      for (final _QNode<T> c in children!) {
        if (_contains(c.box, p)) return c.insert(item, p, capacity, maxDepth);
      }
    }
    items.add((item, p));
    if (children == null && items.length > capacity && depth < maxDepth) {
      final double mx = box.center.dx;
      final double my = box.center.dy;
      children = <_QNode<T>>[
        _QNode<T>(Rect.fromLTRB(box.left, box.top, mx, my), depth + 1),
        _QNode<T>(Rect.fromLTRB(mx, box.top, box.right, my), depth + 1),
        _QNode<T>(Rect.fromLTRB(box.left, my, mx, box.bottom), depth + 1),
        _QNode<T>(Rect.fromLTRB(mx, my, box.right, box.bottom), depth + 1),
      ];
      final List<(T, LatLng)> old = List<(T, LatLng)>.of(items);
      items.clear();
      for (final (T i, LatLng q) in old) {
        insert(i, q, capacity, maxDepth);
      }
    }
  }

  bool remove(T item, LatLng p) {
    final int index = items.indexWhere(((T, LatLng) e) => e.$1 == item);
    if (index >= 0) {
      items.removeAt(index);
      return true;
    }
    for (final _QNode<T> c in children ?? <_QNode<T>>[]) {
      if (_contains(c.box, p) && c.remove(item, p)) return true;
    }
    return false;
  }

  void query(Rect r, List<T> out) {
    if (!(box.left <= r.right && r.left <= box.right && box.top <= r.bottom && r.top <= box.bottom)) return;
    for (final (T i, LatLng p) in items) {
      if (_contains(r, p)) out.add(i);
    }
    for (final _QNode<T> c in children ?? <_QNode<T>>[]) {
      c.query(r, out);
    }
  }

  void queryWithPoints(Rect r, List<(T, LatLng)> out) {
    if (!(box.left <= r.right && r.left <= box.right && box.top <= r.bottom && r.top <= box.bottom)) return;
    for (final (T, LatLng) e in items) {
      if (_contains(r, e.$2)) out.add(e);
    }
    for (final _QNode<T> c in children ?? <_QNode<T>>[]) {
      c.queryWithPoints(r, out);
    }
  }
}
