import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import 'package:gta6hub/engine/physics/breast_physics.dart';
import 'package:gta6hub/engine/physics/soft_body_physics.dart';

void main() {
  group('BreastPhysics', () {
    test('provides two simulated nodes on each side', () {
      final physics = BreastPhysics();
      expect(physics.leftNodes, hasLength(2));
      expect(physics.rightNodes, hasLength(2));
    });

    test('anchors stay pinned while free nodes respond to gravity', () {
      final physics = BreastPhysics(
        leftAnchor: v.Vector3(-0.1, 0, 0),
        rightAnchor: v.Vector3(0.1, 0, 0),
      );
      final before = physics.leftNodes.first.position.clone();
      physics.update(1 / 60);
      expect(physics.leftNodes.first.position.y, lessThan(before.y));
      physics.setAnchors(left: v.Vector3(-0.2, 0, 0), right: v.Vector3(0.2, 0, 0));
      expect(physics.leftAnchorPosition.x, closeTo(-0.2, 1e-9));
      expect(physics.rightAnchorPosition.x, closeTo(0.2, 1e-9));
    });

    test('accepts body collision spheres', () {
      final physics = BreastPhysics();
      physics.update(1 / 60, bodyColliders: [
        PhysicsSphere(center: v.Vector3(-0.1, -0.06, 0), radius: 0.025),
      ]);
      expect(physics.leftNodes.every((node) => node.position.x.isFinite), isTrue);
    });
  });
}
