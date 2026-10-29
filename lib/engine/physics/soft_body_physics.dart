import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as v;

/// A Verlet particle. Set [inverseMass] to zero to pin the particle.
class SoftBodyParticle {
  SoftBodyParticle({
    required v.Vector3 position,
    double inverseMass = 1,
  })  : position = position.clone(),
        previousPosition = position.clone(),
        inverseMass = inverseMass {
    if (!inverseMass.isFinite || inverseMass < 0) {
      throw ArgumentError.value(inverseMass, 'inverseMass');
    }
  }

  v.Vector3 position;
  v.Vector3 previousPosition;
  final double inverseMass;
}

/// Distance constraint between two particle indices.
class SpringConstraint {
  SpringConstraint({
    required this.a,
    required this.b,
    required this.restLength,
    this.stiffness = 1,
  }) {
    if (a < 0 || b < 0 || a == b) throw ArgumentError('Invalid particle indices.');
    if (!restLength.isFinite || restLength < 0) throw ArgumentError.value(restLength);
    if (!stiffness.isFinite || stiffness < 0 || stiffness > 1) {
      throw ArgumentError.value(stiffness, 'stiffness', 'Must be in [0, 1].');
    }
  }

  final int a;
  final int b;
  final double restLength;
  final double stiffness;
}

/// Spherical collider in world coordinates.
class PhysicsSphere {
  PhysicsSphere({required v.Vector3 center, required this.radius})
      : center = center.clone() {
    if (!radius.isFinite || radius < 0) throw ArgumentError.value(radius, 'radius');
  }
  final v.Vector3 center;
  final double radius;
}

/// Verlet integration with distance constraints, damping, gravity and sphere/floor collision.
class SoftBodyPhysics {
  SoftBodyPhysics({
    List<SoftBodyParticle>? particles,
    List<SpringConstraint>? constraints,
    v.Vector3? gravity,
    this.damping = 0.02,
    this.solverIterations = 4,
    this.floorHeight,
  })  : particles = particles ?? <SoftBodyParticle>[],
        constraints = constraints ?? <SpringConstraint>[],
        gravity = (gravity ?? v.Vector3(0, -9.81, 0)).clone() {
    _validateDamping(damping);
    if (solverIterations < 1) throw ArgumentError.value(solverIterations);
  }

  final List<SoftBodyParticle> particles;
  final List<SpringConstraint> constraints;
  final v.Vector3 gravity;
  final double damping;
  final int solverIterations;
  final double? floorHeight;

  void update(double deltaTime, {List<PhysicsSphere> colliders = const []}) {
    if (!deltaTime.isFinite || deltaTime <= 0) return;
    final dt = math.min(deltaTime, 1 / 20);
    final dt2 = dt * dt;
    final retention = (1 - damping).clamp(0.0, 1.0).toDouble();

    for (final particle in particles) {
      if (particle.inverseMass == 0) continue;
      final current = particle.position.clone();
      final velocity = (particle.position - particle.previousPosition) * retention;
      particle.position.setFrom(particle.position + velocity + gravity * dt2);
      particle.previousPosition.setFrom(current);
    }

    for (var iteration = 0; iteration < solverIterations; iteration++) {
      for (final constraint in constraints) {
        if (constraint.a >= particles.length || constraint.b >= particles.length) {
          throw StateError('Spring constraint references a missing particle.');
        }
        final a = particles[constraint.a];
        final b = particles[constraint.b];
        final delta = b.position - a.position;
        final distance = delta.length;
        final inverseMassSum = a.inverseMass + b.inverseMass;
        if (distance < 1e-9 || inverseMassSum <= 0) continue;
        final correction = delta * (((distance - constraint.restLength) /
            distance) * constraint.stiffness / inverseMassSum);
        if (a.inverseMass > 0) {
          a.position.add(correction * a.inverseMass);
        }
        if (b.inverseMass > 0) {
          b.position.sub(correction * b.inverseMass);
        }
      }
      _resolveCollisions(colliders);
    }
  }

  void _resolveCollisions(List<PhysicsSphere> colliders) {
    for (final particle in particles) {
      if (particle.inverseMass == 0) continue;
      for (final collider in colliders) {
        final delta = particle.position - collider.center;
        final distance = delta.length;
        if (distance >= collider.radius) continue;
        if (distance < 1e-9) {
          particle.position.x += collider.radius;
        } else {
          particle.position.setFrom(
            collider.center + delta * (collider.radius / distance),
          );
        }
      }
      final floor = floorHeight;
      if (floor != null && particle.position.y < floor) {
        particle.position.y = floor;
      }
    }
  }

  static void _validateDamping(double value) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw ArgumentError.value(value, 'damping', 'Must be in [0, 1].');
    }
  }
}
