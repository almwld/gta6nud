import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gta6hub/engine/fluids/fluid_particle.dart';

class FluidSimulator {
  final List<FluidParticle> _particles = [];
  final Random _random = Random();
  int _maxParticles = 200; // حد أقصى للجسيمات لحماية الذاكرة

  void emitParticles(List<FluidParticle> newParticles) {
    _particles.addAll(newParticles);
    // إذا تجاوزنا الحد الأقصى، نحذف الجسيمات القديمة
    while (_particles.length > _maxParticles) {
      _particles.removeAt(0);
    }
  }

  void update(double deltaTime, {Size? screenSize}) {
    for (final p in _particles) {
      // تطبيق الجاذبية
      p.velocity += Offset(0, 250 * deltaTime);
      // تخميد السرعة
      p.velocity *= (1.0 - 1.5 * deltaTime);
      // تحديث الموقع
      p.position += p.velocity * deltaTime;
      // تقليل العمر
      p.life -= deltaTime * 0.4;
      
      // الالتصاق بالأسفل إذا تجاوزت حدود الشاشة
      if (screenSize != null) {
        if (p.position.dy > screenSize.height - 10) {
          p.position = Offset(p.position.dx, screenSize.height - 10);
          p.velocity = Offset(p.velocity.dx * 0.2, 0);
          p.life -= deltaTime; // تقليل العمر أسرع عند الالتصاق
        }
        // الالتصاق بالجوانب
        if (p.position.dx < 5 || p.position.dx > screenSize.width - 5) {
          p.velocity = Offset(-p.velocity.dx * 0.2, p.velocity.dy);
        }
      }
    }
    // إزالة الجسيمات الميتة
    _particles.removeWhere((p) => p.life <= 0);
  }

  void render(Canvas canvas) {
    for (final p in _particles) {
      final opacity = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(
        p.position,
        p.size,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }
}
