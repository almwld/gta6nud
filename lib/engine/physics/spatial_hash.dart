import 'aabb.dart';

/// Uniform-grid broad phase for 3D AABBs.
///
/// This structure only produces potentially overlapping pairs. Exact geometric
/// contact must be handled by a narrow-phase solver.
class SpatialHash3D<T> {
  SpatialHash3D({
    required this.cellSize,
    this.maxCellsPerItem = 4096,
  }) {
    if (!cellSize.isFinite || cellSize <= 0) {
      throw ArgumentError.value(cellSize, 'cellSize', 'Must be finite and positive.');
    }
    if (maxCellsPerItem < 1) {
      throw ArgumentError.value(maxCellsPerItem, 'maxCellsPerItem', 'Must be positive.');
    }
  }

  final double cellSize;
  final int maxCellsPerItem;
  final Map<_GridCell, Set<T>> _buckets = <_GridCell, Set<T>>{};
  final Map<T, Aabb3> _bounds = <T, Aabb3>{};
  final Map<T, List<_GridCell>> _itemCells = <T, List<_GridCell>>{};

  int get length => _bounds.length;
  bool contains(T item) => _bounds.containsKey(item);

  void insert(T item, Aabb3 bounds) {
    final cells = _cellsFor(bounds);
    remove(item);
    _bounds[item] = bounds;
    _itemCells[item] = cells;
    for (final cell in cells) {
      (_buckets[cell] ??= <T>{}).add(item);
    }
  }

  bool remove(T item) {
    final cells = _itemCells.remove(item);
    if (cells == null) return false;
    _bounds.remove(item);
    for (final cell in cells) {
      final bucket = _buckets[cell];
      bucket?.remove(item);
      if (bucket != null && bucket.isEmpty) _buckets.remove(cell);
    }
    return true;
  }

  /// Returns unique candidates whose stored AABBs actually overlap [query].
  List<T> query(Aabb3 query) {
    final candidates = <T>{};
    for (final cell in _cellsFor(query)) {
      candidates.addAll(_buckets[cell] ?? <T>{});
    }
    return candidates
        .where((item) => _bounds[item]!.overlaps(query))
        .toList(growable: false);
  }

  void clear() {
    _buckets.clear();
    _bounds.clear();
    _itemCells.clear();
  }

  List<_GridCell> _cellsFor(Aabb3 bounds) {
    int index(double coordinate) {
      final scaled = coordinate / cellSize;
      if (!scaled.isFinite) {
        throw ArgumentError('AABB coordinates exceed the spatial hash range.');
      }
      return scaled.floor();
    }

    final minX = index(bounds.minX);
    final minY = index(bounds.minY);
    final minZ = index(bounds.minZ);
    final maxX = index(bounds.maxX);
    final maxY = index(bounds.maxY);
    final maxZ = index(bounds.maxZ);
    final nx = maxX - minX + 1;
    final ny = maxY - minY + 1;
    final nz = maxZ - minZ + 1;
    if (nx <= 0 || ny <= 0 || nz <= 0 ||
        nx > maxCellsPerItem ||
        ny > maxCellsPerItem ~/ nx ||
        nz > maxCellsPerItem ~/ (nx * ny)) {
      throw ArgumentError('AABB spans more than $maxCellsPerItem grid cells.');
    }

    final cells = <_GridCell>[];
    for (var x = minX; x <= maxX; x++) {
      for (var y = minY; y <= maxY; y++) {
        for (var z = minZ; z <= maxZ; z++) {
          cells.add(_GridCell(x, y, z));
        }
      }
    }
    return cells;
  }
}

class _GridCell {
  const _GridCell(this.x, this.y, this.z);

  final int x;
  final int y;
  final int z;

  @override
  bool operator ==(Object other) =>
      other is _GridCell && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);
}
