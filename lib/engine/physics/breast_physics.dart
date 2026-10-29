import 'package:vector_math/vector_math_64.dart' as v;
import 'soft_body_physics.dart';

/// Four-node spring-mass secondary-motion model (two nodes per side).
///
/// The caller supplies anchor positions and optional body colliders; this class
/// does not assume a model skeleton or a particular renderer.
class BreastPhysics {
  BreastPhysics({
    v.Vector3? leftAnchor,
    v.Vector3? rightAnchor,
    this.nodeSpacing = 0.06,
    this.damping = 0.12,
    v.Vector3? gravity,
  }) {
    if (!nodeSpacing.isFinite || nodeSpacing <= 0) {
      throw ArgumentError.value(nodeSpacing, 'nodeSpacing');
    }
    if (!damping.isFinite || damping < 0 || damping > 1) {
      throw ArgumentError.value(damping, 'damping', 'Must be in [0, 1].');
    }
    final left = (leftAnchor ?? v.Vector3(-0.1, 0, 0)).clone();
    final right = (rightAnchor ?? v.Vector3(0.1, 0, 0)).clone();
    final particles = <SoftBodyParticle>[
      SoftBodyParticle(position: left, inverseMass: 0), // left anchor
      SoftBodyParticle(position: left + v.Vector3(0, -nodeSpacing, 0)),
      SoftBodyParticle(position: left + v.Vector3(0, -nodeSpacing * 2, 0)),
      SoftBodyParticle(position: right, inverseMass: 0), // right anchor
      SoftBodyParticle(position: right + v.Vector3(0, -nodeSpacing, 0)),
      SoftBodyParticle(position: right + v.Vector3(0, -nodeSpacing * 2, 0)),
    ];
    final constraints = <SpringConstraint>[
      SpringConstraint(a: 0, b: 1, restLength: nodeSpacing, stiffness: 0.72),
      SpringConstraint(a: 1, b: 2, restLength: nodeSpacing, stiffness: 0.82),
      SpringConstraint(a: 0, b: 2, restLength: nodeSpacing * 2, stiffness: 0.28),
      SpringConstraint(a: 3, b: 4, restLength: nodeSpacing, stiffness: 0.72),
      SpringConstraint(a: 4, b: 5, restLength: nodeSpacing, stiffness: 0.82),
      SpringConstraint(a: 3, b: 5, restLength: nodeSpacing * 2, stiffness: 0.28),
    ];
    _simulation = SoftBodyPhysics(
      particles: particles,
      constraints: constraints,
      damping: damping,
      gravity: gravity ?? v.Vector3(0, -9.81, 0),
      solverIterations: 6,
    );
  }

  final double nodeSpacing;
  final double damping;
  late final SoftBodyPhysics _simulation;

  List<SoftBodyParticle> get leftNodes =>
      List.unmodifiable(_simulation.particles.sublist(1, 3));
  List<SoftBodyParticle> get rightNodes =>
      List.unmodifiable(_simulation.particles.sublist(4, 6));

  void update(double deltaTime, {List<PhysicsSphere> bodyColliders = const []}) {
    _simulation.update(deltaTime, colliders: bodyColliders);
  }

  void setAnchors({required v.Vector3 left, required v.Vector3 right}) {
    _setPinned(0, left);
    _setPinned(3, right);
  }

  void _setPinned(int index, v.Vector3 position) {
    final particle = _simulation.particles[index];
    particle.position.setFrom(position);
    particle.previousPosition.setFrom(position);
  }
}
