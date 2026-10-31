import 'dart:typed_data';

import 'package:vector_math/vector_math_64.dart' as v;

import 'soft_body_contact_solver.dart';

/// Adapts local-space mesh vertices to the existing world-space contact solver.
///
/// This performs vertex-proximity contact, not triangle-triangle collision.
/// Vertex buffers are edited in-place and remain in each mesh's local space.
class MultiBodyContactSolver {
  MultiBodyContactSolver._();

  static ContactSolveResult resolvePosesContact({
    required Float32List meshAPositions,
    required Float32List meshBPositions,
    required v.Matrix4 transformA,
    required v.Matrix4 transformB,
    required double contactThreshold,
    double stiffness = 0.5,
    double weightA = 0.5,
    double weightB = 0.5,
    int maxContacts = 20000,
  }) {
    _validatePositions(meshAPositions, 'meshAPositions');
    _validatePositions(meshBPositions, 'meshBPositions');
    _validateTransform(transformA, 'transformA');
    _validateTransform(transformB, 'transformB');

    final worldA = _toWorld(meshAPositions, transformA);
    final worldB = _toWorld(meshBPositions, transformB);

    final result = SoftBodyContactSolver.solve(
      upperPositions: worldA,
      lowerPositions: worldB,
      contactThreshold: contactThreshold,
      stiffness: stiffness,
      upperWeight: weightA,
      lowerWeight: weightB,
      maxContacts: maxContacts,
    );

    // The base solver corrects world-space points. Convert those corrections
    // back to local space before writing into the caller-owned mesh buffers.
    final inverseA = transformA.clone()..invert();
    final inverseB = transformB.clone()..invert();
    _copyWorldToLocal(worldA, meshAPositions, inverseA);
    _copyWorldToLocal(worldB, meshBPositions, inverseB);
    return result;
  }

  static Float32List _toWorld(Float32List local, v.Matrix4 transform) {
    final world = Float32List(local.length);
    final point = v.Vector3.zero();
    for (var i = 0; i < local.length; i += 3) {
      point.setValues(local[i], local[i + 1], local[i + 2]);
      transform.transform3(point);
      world[i] = point.x;
      world[i + 1] = point.y;
      world[i + 2] = point.z;
    }
    return world;
  }

  static void _copyWorldToLocal(
    Float32List world,
    Float32List local,
    v.Matrix4 inverse,
  ) {
    final point = v.Vector3.zero();
    for (var i = 0; i < world.length; i += 3) {
      point.setValues(world[i], world[i + 1], world[i + 2]);
      inverse.transform3(point);
      local[i] = point.x;
      local[i + 1] = point.y;
      local[i + 2] = point.z;
    }
  }

  static void _validatePositions(Float32List positions, String name) {
    if (positions.length % 3 != 0) {
      throw ArgumentError('$name length must be divisible by 3 (packed XYZ).');
    }
    for (var i = 0; i < positions.length; i++) {
      if (!positions[i].isFinite) {
        throw ArgumentError('$name contains a non-finite value at index $i.');
      }
    }
  }

  static void _validateTransform(v.Matrix4 matrix, String name) {
    for (var i = 0; i < 16; i++) {
      if (!matrix.storage[i].isFinite) {
        throw ArgumentError('$name contains a non-finite value at index $i.');
      }
    }
    if (matrix.determinant().abs() < 1e-12) {
      throw ArgumentError('$name must be invertible.');
    }
  }
}
