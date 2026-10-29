import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/engine/physics/soft_body_contact_solver.dart';

void main() {
  group('SoftBodyContactSolver', () {
    test('separates overlapping points and reports the contact', () {
      final upper = Float32List.fromList([0.0, 0.0, 0.0]);
      final lower = Float32List.fromList([0.5, 0.0, 0.0]);

      final result = SoftBodyContactSolver.solve(
        upperPositions: upper,
        lowerPositions: lower,
        contactThreshold: 1.0,
        stiffness: 1.0,
      );

      expect(result.contacts, 1);
      expect(result.maxPenetration, closeTo(0.5, 1e-6));
      final distance = (upper[0] - lower[0]).abs();
      expect(distance, closeTo(1.0, 1e-6));
    });

    test('supports a pinned lower point set', () {
      final upper = Float32List.fromList([0.0, 0.0, 0.0]);
      final lower = Float32List.fromList([0.25, 0.0, 0.0]);

      SoftBodyContactSolver.solve(
        upperPositions: upper,
        lowerPositions: lower,
        contactThreshold: 1.0,
        stiffness: 1.0,
        upperWeight: 1.0,
        lowerWeight: 0.0,
      );

      expect(lower[0], closeTo(0.25, 1e-6));
      expect(upper[0], lessThan(0.0));
    });

    test('handles coincident points without producing NaN', () {
      final upper = Float32List.fromList([0.0, 0.0, 0.0]);
      final lower = Float32List.fromList([0.0, 0.0, 0.0]);

      final result = SoftBodyContactSolver.solve(
        upperPositions: upper,
        lowerPositions: lower,
        contactThreshold: 0.5,
      );

      expect(result.contacts, 1);
      expect(upper.every((value) => value.isFinite), isTrue);
      expect(lower.every((value) => value.isFinite), isTrue);
    });

    test('returns no contacts for separated point sets', () {
      final upper = Float32List.fromList([0.0, 0.0, 0.0]);
      final lower = Float32List.fromList([2.0, 0.0, 0.0]);

      final result = SoftBodyContactSolver.solve(
        upperPositions: upper,
        lowerPositions: lower,
        contactThreshold: 1.0,
      );

      expect(result.contacts, 0);
      expect(upper, orderedEquals([0.0, 0.0, 0.0]));
      expect(lower, orderedEquals([2.0, 0.0, 0.0]));
    });

    test('rejects malformed packed XYZ data', () {
      expect(
        () => SoftBodyContactSolver.solve(
          upperPositions: Float32List.fromList([0.0, 1.0]),
          lowerPositions: Float32List.fromList([0.0, 0.0, 0.0]),
          contactThreshold: 1.0,
        ),
        throwsArgumentError,
      );
    });
  });
}
