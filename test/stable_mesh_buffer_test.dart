import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/engine/physics/stable_mesh_buffer.dart';

void main() {
  group('StableMeshBuffer', () {
    test('keeps rest positions unchanged across repeated displacements', () {
      final source = Float32List.fromList(<double>[1, 2, 3, -1, -2, -3]);
      final mesh = StableMeshBuffer(source);

      mesh.applyDisplacement(0, dx: 0.5, dy: -0.25, dz: 2);
      mesh.applyDisplacement(0, dx: 0.25, dy: 0.5, dz: -1);

      expect(mesh.restPositions, orderedEquals(<double>[1, 2, 3, -1, -2, -3]));
      expect(mesh.currentPositions[0], closeTo(1.25, 1e-6));
      expect(mesh.currentPositions[1], closeTo(2.5, 1e-6));
      expect(mesh.currentPositions[2], closeTo(2, 1e-6));
    });

    test('reset restores rest pose and clears velocities', () {
      final mesh = StableMeshBuffer(Float32List.fromList(<double>[0, 1, 2]));
      mesh.applyDisplacement(0, dx: 3, dy: 4, dz: 5);
      mesh.velocities.setAll(0, <double>[6, 7, 8]);

      mesh.resetToRest();

      expect(mesh.currentPositions, orderedEquals(<double>[0, 1, 2]));
      expect(mesh.velocities, orderedEquals(<double>[0, 0, 0]));
    });

    test('rejects malformed and non-finite source data', () {
      expect(
        () => StableMeshBuffer(Float32List.fromList(<double>[1, 2])),
        throwsArgumentError,
      );
      expect(
        () => StableMeshBuffer(Float32List.fromList(<double>[1, double.nan, 3])),
        throwsArgumentError,
      );
    });

    test('rejects out-of-range vertex and non-finite displacement', () {
      final mesh = StableMeshBuffer(Float32List.fromList(<double>[0, 0, 0]));
      expect(() => mesh.applyDisplacement(1, dx: 1), throwsRangeError);
      expect(
        () => mesh.applyDisplacement(0, dx: double.infinity),
        throwsArgumentError,
      );
    });
  });
}
