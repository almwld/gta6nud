import 'package:vector_math/vector_math_64.dart' as v;
import 'soft_body_physics.dart';

/// Lightweight spring-bone chain for secondary hair motion.
class HairPhysics {
  HairPhysics({
    v.Vector3? root,
    this.boneCount = 12,
    this.boneLength = 0.08,
    this.damping = 0.035,
    v.Vector3? gravity,
  }) {
    if (boneCount < 2 || boneCount > 64) {
      throw ArgumentError.value(boneCount, 'boneCount', 'Must be in [2, 64].');
    }
    if (!boneLength.isFinite || boneLength <= 0) {
      throw ArgumentError.value(boneLength, 'boneLength');
    }
    final origin = (root ?? v.Vector3.zero()).clone();
    final particles = <SoftBodyParticle>[];
    for (var i = 0; i < boneCount; i++) {
      particles.add(SoftBodyParticle(
        position: origin + v.Vector3(0, -boneLength * i, 0),
        inverseMass: i == 0 ? 0 : 1,
      ));
    }
    final constraints = <SpringConstraint>[];
    for (var i = 0; i < boneCount - 1; i++) {
      constraints.add(SpringConstraint(
        a: i,
        b: i + 1,
        restLength: boneLength,
        stiffness: 0.85,
      ));
    }
    // A small number of bend constraints reduce unrealistic folding.
    for (var i = 0; i < boneCount - 2; i++) {
      constraints.add(SpringConstraint(
        a: i,
        b: i + 2,
        restLength: boneLength * 2,
        stiffness: 0.25,
      ));
    }
    _simulation = SoftBodyPhysics(
      particles: particles,
      constraints: constraints,
      damping: damping,
      gravity: gravity ?? v.Vector3(0, -9.81, 0),
      solverIterations: 5,
    );
  }

  final int boneCount;
  final double boneLength;
  final double damping;
  late final SoftBodyPhysics _simulation;

  List<SoftBodyParticle> get bones => List.unmodifiable(_simulation.particles);

  void update(double deltaTime, {List<PhysicsSphere> bodyColliders = const []}) {
    _simulation.update(deltaTime, colliders: bodyColliders);
  }

  void setRoot(v.Vector3 root) {
    final particle = _simulation.particles.first;
    particle.position.setFrom(root);
    particle.previousPosition.setFrom(root);
  }
}
