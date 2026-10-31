/// Axis-aligned bounding box in world-space coordinates.
///
/// The box is immutable and rejects non-finite or inverted bounds at creation.
class Aabb3 {
  Aabb3({
    required this.minX,
    required this.minY,
    required this.minZ,
    required this.maxX,
    required this.maxY,
    required this.maxZ,
  }) {
    final values = <double>[minX, minY, minZ, maxX, maxY, maxZ];
    if (values.any((value) => !value.isFinite)) {
      throw ArgumentError('AABB coordinates must be finite.');
    }
    if (minX > maxX || minY > maxY || minZ > maxZ) {
      throw ArgumentError('AABB minimum coordinates must not exceed maxima.');
    }
  }

  final double minX;
  final double minY;
  final double minZ;
  final double maxX;
  final double maxY;
  final double maxZ;

  double get width => maxX - minX;
  double get height => maxY - minY;
  double get depth => maxZ - minZ;

  bool overlaps(Aabb3 other) =>
      minX <= other.maxX &&
      maxX >= other.minX &&
      minY <= other.maxY &&
      maxY >= other.minY &&
      minZ <= other.maxZ &&
      maxZ >= other.minZ;

  bool containsPoint(double x, double y, double z) =>
      x >= minX && x <= maxX &&
      y >= minY && y <= maxY &&
      z >= minZ && z <= maxZ;

  Aabb3 expanded(double margin) {
    if (!margin.isFinite || margin < 0) {
      throw ArgumentError.value(margin, 'margin', 'Must be finite and non-negative.');
    }
    return Aabb3(
      minX: minX - margin,
      minY: minY - margin,
      minZ: minZ - margin,
      maxX: maxX + margin,
      maxY: maxY + margin,
      maxZ: maxZ + margin,
    );
  }

  Aabb3 union(Aabb3 other) => Aabb3(
        minX: minX < other.minX ? minX : other.minX,
        minY: minY < other.minY ? minY : other.minY,
        minZ: minZ < other.minZ ? minZ : other.minZ,
        maxX: maxX > other.maxX ? maxX : other.maxX,
        maxY: maxY > other.maxY ? maxY : other.maxY,
        maxZ: maxZ > other.maxZ ? maxZ : other.maxZ,
      );
}
