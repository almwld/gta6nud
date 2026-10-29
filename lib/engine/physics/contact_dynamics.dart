import 'package:vector_math/vector_math_64.dart' as v;

/// Contact impulse result for two bodies with velocities expressed in world space.
/// This utility is intended for a rigid-body/IK adapter; mesh positions alone
/// do not contain enough information to infer velocity or angular response.
class ContactImpulse {
  const ContactImpulse({
    required this.impulseOnA,
    required this.impulseOnB,
    required this.normalImpulse,
    required this.tangentImpulse,
  });

  final v.Vector3 impulseOnA;
  final v.Vector3 impulseOnB;
  final double normalImpulse;
  final double tangentImpulse;
}

/// Coulomb-friction and normal-damping response for a single contact.
///
/// [normalAToB] points from body A toward body B. Inverse masses are zero for
/// pinned bodies. This computes impulses but does not mutate caller velocities.
class ContactDynamics {
  ContactDynamics._();

  static ContactImpulse solveImpulse({
    required v.Vector3 relativeVelocityBMinusA,
    required v.Vector3 normalAToB,
    required double inverseMassA,
    required double inverseMassB,
    double frictionCoefficient = 0.4,
    double restitution = 0,
    double damping = 0.05,
  }) {
    for (final value in [
      ...relativeVelocityBMinusA.storage,
      ...normalAToB.storage,
      inverseMassA,
      inverseMassB,
      frictionCoefficient,
      restitution,
      damping,
    ]) {
      if (!value.isFinite) {
        throw ArgumentError('Contact parameters must be finite.');
      }
    }
    if (inverseMassA < 0 || inverseMassB < 0 ||
        inverseMassA + inverseMassB <= 0) {
      throw ArgumentError('Inverse masses must be non-negative and not both zero.');
    }
    if (frictionCoefficient < 0 || restitution < 0 || restitution > 1 ||
        damping < 0 || damping > 1) {
      throw ArgumentError('Friction/damping must be non-negative; restitution and damping must be in [0, 1].');
    }
    final normal = normalAToB.clone();
    if (normal.length2 < 1e-20) {
      throw ArgumentError('Contact normal must be non-zero.');
    }
    normal.normalize();

    final inverseMassSum = inverseMassA + inverseMassB;
    final normalVelocity = relativeVelocityBMinusA.dot(normal);
    var normalImpulse = 0.0;
    if (normalVelocity < 0) {
      normalImpulse = -(1 + restitution) * normalVelocity / inverseMassSum;
      // Damping reduces the impulse response without reversing its direction.
      normalImpulse *= (1 - damping);
    }

    final tangentVelocity = relativeVelocityBMinusA -
        normal * normalVelocity;
    var tangentImpulse = 0.0;
    var impulse = normal * normalImpulse;
    final tangentSpeed = tangentVelocity.length;
    if (tangentSpeed > 1e-12 && normalImpulse > 0) {
      final unconstrained = tangentSpeed / inverseMassSum;
      tangentImpulse = unconstrained.clamp(
        0.0,
        frictionCoefficient * normalImpulse,
      ).toDouble();
      impulse -= tangentVelocity / tangentSpeed * tangentImpulse;
    }

    return ContactImpulse(
      impulseOnA: -impulse,
      impulseOnB: impulse,
      normalImpulse: normalImpulse,
      tangentImpulse: tangentImpulse,
    );
  }
}
