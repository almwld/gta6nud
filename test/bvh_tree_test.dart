import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/engine/physics/aabb.dart';
import 'package:gta6hub/engine/physics/bvh_tree.dart';

Aabb3 bounds(double x) => Aabb3(
      minX: x,
      minY: 0,
      minZ: 0,
      maxX: x + 0.5,
      maxY: 0.5,
      maxZ: 0.5,
    );

void main() {
  group('BvhTree', () {
    test('returns only overlapping leaves after median splits', () {
      final tree = BvhTree<int>(leafSize: 1);
      tree.rebuild(<int, Aabb3>{
        for (var i = 0; i < 20; i++) i: bounds(i.toDouble() * 2),
      });
      expect(tree.length, 20);
      expect(tree.query(bounds(8.1)).toSet(), <int>{4});
      expect(tree.query(bounds(100)), isEmpty);
    });

    test('supports empty rebuild and replacement rebuild', () {
      final tree = BvhTree<String>();
      tree.rebuild(<String, Aabb3>{'old': bounds(0)});
      tree.rebuild(<String, Aabb3>{});
      expect(tree.length, 0);
      expect(tree.query(bounds(0)), isEmpty);
      tree.rebuild(<String, Aabb3>{'new': bounds(5)});
      expect(tree.query(bounds(5)), <String>['new']);
    });

    test('rejects invalid leaf size', () {
      expect(() => BvhTree<int>(leafSize: 0), throwsArgumentError);
    });
  });
}
