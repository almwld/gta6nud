import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import 'package:gta6hub/engine/physics/multi_body_contact_solver.dart';

void main() {
  group('MultiBodyContactSolver', () {
    test('resolves contact in world space and writes back local coordinates', () {
      final meshA = Float32List.fromList([0, 0, 0]);
      final meshB = Float32List.fromList([0, 0, 0]);
      final transformA = v.Matrix4.translationValues(1, 0, 0);
      final transformB = v.Matrix4.translationValues(1.05, 0, 0);

      final result = MultiBodyContactSolver.resolvePosesContact(
        meshAPositions: meshA,
        meshBPositions: meshB,
        transformA: transformA,
        transformB: transformB,
        contactThreshold: 0.2,
        stiffness: 1,
      );

      final worldA = v.Vector3(meshA[0], meshA[1], meshA[2]);
      final worldB = v.Vector3(meshB[0], meshB[1], meshB[2]);
      transformA.transform3(worldA);
      transformB.transform3(worldB);

      expect(result.contacts, 1);
      expect(worldA.distanceTo(worldB), greaterThan(0.05));
      expect(meshA.every((value) => value.isFinite), isTrue);
      expect(meshB.every((value) => value.isFinite), isTrue);
    });

    test('supports rotation and unequal correction weights', () {
      final meshA = Float32List.fromList([0, 0, 0]);
      final meshB = Float32List.fromList([0, 0, 0]);
      final transformA = v.Matrix4.identity()
        ..translate(0.0, 0.0, 0.0)
        ..rotateZ(0.7);
      final transformB = v.Matrix4.translationValues(0.1, 0, 0);

      MultiBodyContactSolver.resolvePosesContact(
        meshAPositions: meshA,
        meshBPositions: meshB,
        transformA: transformA,
        transformB: transformB,
        contactThreshold: 0.3,
        stiffness: 1,
        weightA: 0.1,
        weightB: 0.9,
      );

      expect(meshA.any((value) => value.abs() > 1e-6), isTrue);
      expect(meshB.any((value) => value.abs() > 1e-6), isTrue);
    });

    test('rejects non-invertible transforms', () {
      expect(
        () => MultiBodyContactSolver.resolvePosesContact(
          meshAPositions: Float32List.fromList([0, 0, 0]),
          meshBPositions: Float32List.fromList([0, 0, 0]),
          transformA: v.Matrix4.zero(),
          transformB: v.Matrix4.identity(),
          contactThreshold: 0.1,
        ),
        throwsArgumentError,
      );
    });
  });
}
