import 'aabb.dart';

/// Median-split bounding volume hierarchy for static or periodically rebuilt
/// broad-phase bounds. Update moving scenes by calling [rebuild].
class BvhTree<T> {
  BvhTree({this.leafSize = 4}) {
    if (leafSize < 1) {
      throw ArgumentError.value(leafSize, 'leafSize', 'Must be positive.');
    }
  }

  final int leafSize;
  _BvhNode<T>? _root;
  int get length => _count(_root);

  void rebuild(Map<T, Aabb3> boundsByItem) {
    final entries = boundsByItem.entries
        .map((entry) => _BvhEntry<T>(entry.key, entry.value))
        .toList(growable: false);
    _root = entries.isEmpty ? null : _build(entries);
  }

  List<T> query(Aabb3 bounds) {
    final result = <T>[];
    _query(_root, bounds, result);
    return result;
  }

  _BvhNode<T> _build(List<_BvhEntry<T>> entries) {
    var bounds = entries.first.bounds;
    for (var i = 1; i < entries.length; i++) {
      bounds = bounds.union(entries[i].bounds);
    }
    if (entries.length <= leafSize) {
      return _BvhNode<T>.leaf(bounds, entries);
    }

    final axis = bounds.width >= bounds.height && bounds.width >= bounds.depth
        ? 0
        : (bounds.height >= bounds.depth ? 1 : 2);
    entries.sort((a, b) => a.center(axis).compareTo(b.center(axis)));
    final middle = entries.length ~/ 2;
    final left = _build(entries.sublist(0, middle));
    final right = _build(entries.sublist(middle));
    return _BvhNode<T>.branch(bounds, left, right);
  }

  void _query(_BvhNode<T>? node, Aabb3 bounds, List<T> result) {
    if (node == null || !node.bounds.overlaps(bounds)) return;
    final entries = node.entries;
    if (entries != null) {
      for (final entry in entries) {
        if (entry.bounds.overlaps(bounds)) result.add(entry.item);
      }
      return;
    }
    _query(node.left, bounds, result);
    _query(node.right, bounds, result);
  }

  int _count(_BvhNode<T>? node) {
    if (node == null) return 0;
    if (node.entries != null) return node.entries!.length;
    return _count(node.left) + _count(node.right);
  }
}

class _BvhEntry<T> {
  const _BvhEntry(this.item, this.bounds);
  final T item;
  final Aabb3 bounds;

  double center(int axis) {
    switch (axis) {
      case 0:
        return (bounds.minX + bounds.maxX) * 0.5;
      case 1:
        return (bounds.minY + bounds.maxY) * 0.5;
      default:
        return (bounds.minZ + bounds.maxZ) * 0.5;
    }
  }
}

class _BvhNode<T> {
  const _BvhNode._(this.bounds, {this.entries, this.left, this.right});

  factory _BvhNode.leaf(Aabb3 bounds, List<_BvhEntry<T>> entries) =>
      _BvhNode<T>._(bounds, entries: List<_BvhEntry<T>>.unmodifiable(entries));

  factory _BvhNode.branch(
    Aabb3 bounds,
    _BvhNode<T> left,
    _BvhNode<T> right,
  ) =>
      _BvhNode<T>._(bounds, left: left, right: right);

  final Aabb3 bounds;
  final List<_BvhEntry<T>>? entries;
  final _BvhNode<T>? left;
  final _BvhNode<T>? right;
}
