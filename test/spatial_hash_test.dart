import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/engine/physics/aabb.dart';
import 'package:gta6hub/engine/physics/spatial_hash.dart';

Aabb3 box(double x0, double x1, {double y0 = 0, double y1 = 1}) => Aabb3(
      minX: x0,
      minY: y0,
      minZ: 0,
      maxX: x1,
      maxY: y1,
      maxZ: 1,
    );

void main() {
  group('Aabb3', () {
    test('detects overlap including touching boundaries', () {
      expect(box(0, 1).overlaps(box(1, 2)), isTrue);
      expect(box(0, 1).overlaps(box(1.01, 2)), isFalse);
    });

    test('expands and unions bounds', () {
      final expanded = box(0, 1).expanded(0.5);
      expect(expanded.minX, -0.5);
      expect(expanded.maxX, 1.5);
      final merged = box(0, 1).union(box(2, 3));
      expect(merged.minX, 0);
      expect(merged.maxX, 3);
    });

    test('rejects invalid coordinates', () {
      expect(() => box(2, 1), throwsArgumentError);
      expect(
        () => Aabb3(minX: 0, minY: 0, minZ: 0, maxX: double.nan, maxY: 1, maxZ: 1),
        throwsArgumentError,
      );
    });
  });

  group('SpatialHash3D', () {
    test('returns unique overlapping candidates across negative cells', () {
      final hash = SpatialHash3D<int>(cellSize: 1);
      hash.insert(1, box(-1.5, 0.5));
      hash.insert(2, box(0.4, 1.4));
      hash.insert(3, box(2, 3));
      expect(hash.query(box(0, 0.6)).toSet(), <int>{1, 2});
    });

    test('replaces and removes existing entries', () {
      final hash = SpatialHash3D<String>(cellSize: 1);
      hash.insert('body', box(0, 1));
      hash.insert('body', box(4, 5));
      expect(hash.query(box(0, 1)), isEmpty);
      expect(hash.query(box(4, 5)), <String>['body']);
      expect(hash.remove('body'), isTrue);
      expect(hash.remove('body'), isFalse);
      expect(hash.length, 0);
    });

    test('guards against pathological cell coverage', () {
      final hash = SpatialHash3D<int>(cellSize: 0.01, maxCellsPerItem: 8);
      expect(() => hash.insert(1, box(0, 10)), throwsArgumentError);
      expect(hash.length, 0);
    });
  });
}
