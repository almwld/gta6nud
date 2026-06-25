import 'dart:math';
import 'package:flutter/material.dart';

/// نقطة حرارية (بصمة لمس)
class HeatPoint {
  Offset position;
  double intensity;
  double radius;
  double life;
  double age;

  HeatPoint({
    required this.position,
    this.intensity = 1.0,
    this.radius = 40.0,
    this.life = 2.0,
    this.age = 0,
  });
}

/// نظام البصمة الحرارية على الجلد
class HeatmapRenderer {
  final List<HeatPoint> _points = [];
  final Random _random = Random();

  /// إضافة بصمة حرارية
  void addTouchPoint(Offset position, {double intensity = 1.0, double radius = 40.0}) {
    _points.add(HeatPoint(
      position: position,
      intensity: intensity.clamp(0.0, 1.0),
      radius: radius,
      life: 1.5 + intensity * 2.5,
    ));

    // إضافة نقاط فرعية للواقعية
    for (int i = 0; i < 3; i++) {
      _points.add(HeatPoint(
        position: position + Offset(
          (_random.nextDouble() - 0.5) * radius * 0.5,
          (_random.nextDouble() - 0.5) * radius * 0.5,
        ),
        intensity: intensity * 0.5,
        radius: radius * 0.4,
        life: 1.0 + _random.nextDouble() * 1.5,
      ));
    }

    // تنظيف النقاط القديمة
    while (_points.length > 50) {
      _points.removeAt(0);
    }
  }

  /// تحديث النقاط
  void update(double deltaTime) {
    for (final point in _points) {
      point.age += deltaTime;
      point.intensity *= 0.995;
      point.radius += deltaTime * 8.0;
    }
    _points.removeWhere((p) => p.age >= p.life);
  }

  /// رسم تأثير الحرارة على Canvas
  void render(Canvas canvas, Size screenSize) {
    for (final point in _points) {
      final progress = (point.age / point.life).clamp(0.0, 1.0);
      final currentIntensity = point.intensity * (1.0 - progress * progress);

      if (currentIntensity < 0.01) continue;

      // تدرج البصمة
      final glowPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            const Color(0xFFFF2A6D).withOpacity(currentIntensity * 0.6),
            const Color(0xFFFF4444).withOpacity(currentIntensity * 0.3),
            const Color(0xFFFF6B6B).withOpacity(currentIntensity * 0.1),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: point.position, radius: point.radius));

      canvas.drawCircle(point.position, point.radius, glowPaint);

      // حلقة خارجية (انتشار الحرارة)
      if (currentIntensity > 0.3) {
        final outerRing = Paint()
          ..color = const Color(0xFFFF2A6D).withOpacity(currentIntensity * 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(point.position, point.radius * 1.3, outerRing);
      }
    }
  }

  int get activePoints => _points.length;
  void clear() => _points.clear();
}
