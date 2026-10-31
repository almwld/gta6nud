import 'dart:typed_data';

/// Owns immutable-by-convention rest coordinates and mutable simulation buffers.
///
/// Coordinates use packed XYZ layout. Callers must not mutate [restPositions]
/// after construction; all deformation is written relative to this baseline.
class StableMeshBuffer {
  StableMeshBuffer(Float32List source)
      : restPositions = Float32List.fromList(source),
        currentPositions = Float32List.fromList(source),
        velocities = Float32List(source.length) {
    if (source.length % 3 != 0) {
      throw ArgumentError.value(
        source.length,
        'source.length',
        'Vertex data must contain packed XYZ triples.',
      );
    }
    for (var i = 0; i < source.length; i++) {
      if (!source[i].isFinite) {
        throw ArgumentError('source contains a non-finite value at index $i.');
      }
    }
  }

  /// Baseline positions. Treat this buffer as read-only after construction.
  final Float32List restPositions;

  /// Current world/local positions consumed by solvers and renderers.
  final Float32List currentPositions;

  /// Per-coordinate velocity buffer, initially zero.
  final Float32List velocities;

  int get vertexCount => restPositions.length ~/ 3;

  /// Restore the complete mesh and clear all simulation velocity.
  void resetToRest() {
    currentPositions.setAll(0, restPositions);
    velocities.fillRange(0, velocities.length, 0.0);
  }

  /// Set one vertex from its rest position plus a relative displacement.
  void applyDisplacement(
    int vertexIndex, {
    double dx = 0.0,
    double dy = 0.0,
    double dz = 0.0,
  }) {
    if (vertexIndex < 0 || vertexIndex >= vertexCount) {
      throw RangeError.index(vertexIndex, restPositions, 'vertexIndex');
    }
    if (!dx.isFinite || !dy.isFinite || !dz.isFinite) {
      throw ArgumentError('Displacements must be finite.');
    }
    final i = vertexIndex * 3;
    currentPositions[i] = restPositions[i] + dx;
    currentPositions[i + 1] = restPositions[i + 1] + dy;
    currentPositions[i + 2] = restPositions[i + 2] + dz;
  }

  /// Rebuild current positions from rest coordinates and a packed XYZ offset.
  void applyDisplacements(Float32List offsets) {
    if (offsets.length != restPositions.length) {
      throw ArgumentError.value(
        offsets.length,
        'offsets.length',
        'Must match the packed rest-position buffer length.',
      );
    }
    for (var i = 0; i < offsets.length; i++) {
      if (!offsets[i].isFinite) {
        throw ArgumentError('offsets contains a non-finite value at index $i.');
      }
      currentPositions[i] = restPositions[i] + offsets[i];
    }
  }
}
