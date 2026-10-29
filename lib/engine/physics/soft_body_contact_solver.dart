import 'dart:math' as math;
import 'dart:typed_data';

/// Result of one vertex-based soft-body contact pass.
class ContactSolveResult {
  const ContactSolveResult({
    required this.candidatePairs,
    required this.contacts,
    required this.maxPenetration,
  });

  /// Candidate vertex pairs tested after broad-phase filtering.
  final int candidatePairs;

  /// Pairs whose distance was below [contactThreshold].
  final int contacts;

  /// Largest penetration depth detected in this pass.
  final double maxPenetration;
}

/// Lightweight, allocation-conscious contact approximation for two point clouds.
///
/// Positions are packed XYZ coordinates in world space:
/// [x0, y0, z0, x1, y1, z1, ...].
///
/// A spatial hash avoids the O(n*m) all-pairs scan. Contact corrections are
/// accumulated and applied after detection, so iteration order does not mutate
/// positions while pairs are being examined.
///
/// This is a vertex-proximity solver, not triangle-mesh collision detection or
/// a physically calibrated tissue model. For production meshes, pair it with
/// triangle-level narrow phase and structural constraints.
class SoftBodyContactSolver {
  SoftBodyContactSolver._();

  /// Detect and resolve proximity between two independently movable point sets.
  ///
  /// [contactThreshold] is the minimum desired distance in world units.
  /// [stiffness] is clamped to [0, 1], representing the fraction of overlap
  /// corrected per pass. [upperWeight] and [lowerWeight] distribute correction
  /// between the two point sets; zero pins that set in place.
  static ContactSolveResult solve({
    required Float32List upperPositions,
    required Float32List lowerPositions,
    required double contactThreshold,
    double stiffness = 0.5,
    double upperWeight = 0.2,
    double lowerWeight = 0.8,
    int maxContacts = 20000,
  }) {
    _validatePositions(upperPositions, 'upperPositions');
    _validatePositions(lowerPositions, 'lowerPositions');
    if (!contactThreshold.isFinite || contactThreshold <= 0) {
      throw ArgumentError.value(contactThreshold, 'contactThreshold',
          'Must be finite and greater than zero.');
    }
    if (!stiffness.isFinite || !upperWeight.isFinite || !lowerWeight.isFinite) {
      throw ArgumentError('stiffness and weights must be finite.');
    }
    if (upperWeight < 0 || lowerWeight < 0 || upperWeight + lowerWeight <= 0) {
      throw ArgumentError('Weights must be non-negative and not both zero.');
    }
    if (maxContacts < 1) {
      throw ArgumentError.value(maxContacts, 'maxContacts', 'Must be positive.');
    }

    final upperCount = upperPositions.length ~/ 3;
    final lowerCount = lowerPositions.length ~/ 3;
    if (upperCount == 0 || lowerCount == 0) {
      return const ContactSolveResult(
        candidatePairs: 0,
        contacts: 0,
        maxPenetration: 0,
      );
    }

    final cellSize = contactThreshold;
    final grid = <_Cell, List<int>>{};
    for (var j = 0; j < lowerCount; j++) {
      final k = j * 3;
      final cell = _Cell(
        (lowerPositions[k] / cellSize).floor(),
        (lowerPositions[k + 1] / cellSize).floor(),
        (lowerPositions[k + 2] / cellSize).floor(),
      );
      (grid[cell] ??= <int>[]).add(j);
    }

    final upperDx = Float64List(upperCount);
    final upperDy = Float64List(upperCount);
    final upperDz = Float64List(upperCount);
    final upperHits = Int32List(upperCount);
    final lowerDx = Float64List(lowerCount);
    final lowerDy = Float64List(lowerCount);
    final lowerDz = Float64List(lowerCount);
    final lowerHits = Int32List(lowerCount);

    final safeStiffness = stiffness.clamp(0.0, 1.0).toDouble();
    final weightSum = upperWeight + lowerWeight;
    var candidatePairs = 0;
    var contacts = 0;
    var maxPenetration = 0.0;
    var capped = false;

    for (var i = 0; i < upperCount && !capped; i++) {
      final u = i * 3;
      final ux = upperPositions[u].toDouble();
      final uy = upperPositions[u + 1].toDouble();
      final uz = upperPositions[u + 2].toDouble();
      final cx = (ux / cellSize).floor();
      final cy = (uy / cellSize).floor();
      final cz = (uz / cellSize).floor();

      for (var ox = -1; ox <= 1 && !capped; ox++) {
        for (var oy = -1; oy <= 1 && !capped; oy++) {
          for (var oz = -1; oz <= 1 && !capped; oz++) {
            final bucket = grid[_Cell(cx + ox, cy + oy, cz + oz)];
            if (bucket == null) continue;

            for (final j in bucket) {
              candidatePairs++;
              final l = j * 3;
              final dx = ux - lowerPositions[l];
              final dy = uy - lowerPositions[l + 1];
              final dz = uz - lowerPositions[l + 2];
              final distanceSquared = dx * dx + dy * dy + dz * dz;
              final thresholdSquared = contactThreshold * contactThreshold;
              if (distanceSquared >= thresholdSquared) continue;

              if (contacts >= maxContacts) {
                capped = true;
                break;
              }

              final distance = math.sqrt(distanceSquared);
              final penetration = contactThreshold - distance;
              if (penetration > maxPenetration) {
                maxPenetration = penetration;
              }

              // Coincident points have no geometric normal. Use a deterministic
              // axis so they separate instead of producing NaN values.
              final nx = distance > 1e-12 ? dx / distance : 1.0;
              final ny = distance > 1e-12 ? dy / distance : 0.0;
              final nz = distance > 1e-12 ? dz / distance : 0.0;
              final correction = penetration * safeStiffness;
              final upperCorrection = correction * upperWeight / weightSum;
              final lowerCorrection = correction * lowerWeight / weightSum;

              upperDx[i] += nx * upperCorrection;
              upperDy[i] += ny * upperCorrection;
              upperDz[i] += nz * upperCorrection;
              upperHits[i]++;

              lowerDx[j] -= nx * lowerCorrection;
              lowerDy[j] -= ny * lowerCorrection;
              lowerDz[j] -= nz * lowerCorrection;
              lowerHits[j]++;
              contacts++;
            }
          }
        }
      }
    }

    // Average per-vertex corrections to avoid over-correcting dense clusters.
    for (var i = 0; i < upperCount; i++) {
      final hits = upperHits[i];
      if (hits == 0) continue;
      final k = i * 3;
      upperPositions[k] += upperDx[i] / hits;
      upperPositions[k + 1] += upperDy[i] / hits;
      upperPositions[k + 2] += upperDz[i] / hits;
    }
    for (var j = 0; j < lowerCount; j++) {
      final hits = lowerHits[j];
      if (hits == 0) continue;
      final k = j * 3;
      lowerPositions[k] += lowerDx[j] / hits;
      lowerPositions[k + 1] += lowerDy[j] / hits;
      lowerPositions[k + 2] += lowerDz[j] / hits;
    }

    return ContactSolveResult(
      candidatePairs: candidatePairs,
      contacts: contacts,
      maxPenetration: maxPenetration,
    );
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
}

class _Cell {
  const _Cell(this.x, this.y, this.z);

  final int x;
  final int y;
  final int z;

  @override
  bool operator ==(Object other) =>
      other is _Cell && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);
}
