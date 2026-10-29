import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import 'package:gta6hub/engine/physics/hair_physics.dart';
import 'package:gta6hub/engine/physics/soft_body_physics.dart';

void main() {
  group('HairPhysics', () {
    test('creates a 12-bone chain with a pinned root', () {
      final hair = HairPhysics(root: v.Vector3(1, 2, 3));
      expect(hair.bones, hasLength(12));
      hair.update(1 / 60);
      expect(hair.bones.first.position, v.Vector3(1, 2, 3));
      expect(hair.bones.every((bone) =>
          bone.position.x.isFinite && bone.position.y.isFinite &&
          bone.position.z.isFinite), isTrue);
    });

    test('supports body sphere collision', () {
      final hair = HairPhysics(root: v.Vector3.zero(), boneCount: 10);
      hair.setRoot(v.Vector3(0, 0, 0));
      hair.update(1 / 60, bodyColliders: [
        PhysicsSphere(center: v.Vector3(0, -0.08, 0), radius: 0.04),
      ]);
      expect(hair.bones.skip(1).every((bone) => bone.position.length.isFinite), isTrue);
    });

    test('rejects bone counts outside supported range', () {
      expect(() => HairPhysics(boneCount: 1), throwsArgumentError);
    });
  });
}
