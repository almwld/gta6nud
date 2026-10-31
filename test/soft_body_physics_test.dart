import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import 'package:gta6hub/engine/physics/soft_body_physics.dart';

void main() {
  group('SoftBodyPhysics', () {
    test('Verlet integration applies gravity to movable particles', () {
      final particle = SoftBodyParticle(position: v.Vector3(0, 1, 0));
      final physics = SoftBodyPhysics(particles: [particle]);
      physics.update(0.1);
      expect(particle.position.y, lessThan(1));
      expect(particle.position.x, closeTo(0, 1e-9));
    });

    test('spring constraint preserves its rest length approximately', () {
      final a = SoftBodyParticle(position: v.Vector3.zero(), inverseMass: 0);
      final b = SoftBodyParticle(position: v.Vector3(2, 0, 0));
      final physics = SoftBodyPhysics(
        particles: [a, b],
        constraints: [SpringConstraint(a: 0, b: 1, restLength: 1)],
        gravity: v.Vector3.zero(),
        damping: 0,
        solverIterations: 8,
      );
      physics.update(1 / 60);
      expect(a.position.distanceTo(b.position), closeTo(1, 1e-5));
    });

    test('sphere and floor collisions prevent penetration', () {
      final particle = SoftBodyParticle(position: v.Vector3(0.1, 0.1, 0));
      final physics = SoftBodyPhysics(
        particles: [particle],
        gravity: v.Vector3.zero(),
        floorHeight: 0,
      );
      physics.update(1 / 60, colliders: [
        PhysicsSphere(center: v.Vector3.zero(), radius: 0.5),
      ]);
      expect(particle.position.y, greaterThanOrEqualTo(0));
      expect(particle.position.length, greaterThanOrEqualTo(0.5 - 1e-6));
    });

    test('rejects invalid spring stiffness', () {
      expect(
        () => SpringConstraint(a: 0, b: 1, restLength: 1, stiffness: 2),
        throwsArgumentError,
      );
    });
  });
}
