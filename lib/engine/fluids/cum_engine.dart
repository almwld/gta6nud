import 'dart:math';
import 'package:flutter/material.dart';

class CumParticle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  double life;
  bool isStuck;
  Offset? stuckPosition;

  CumParticle({
    required this.position,
    required this.velocity,
    this.size = 4.0,
    this.opacity = 1.0,
    this.life = 1.0,
    this.isStuck = false,
    this.stuckPosition,
  });
}

class CumEngine {
  final List<CumParticle> _particles = [];
  final Random _random = Random();

  List<CumParticle> emitBurst({
    required Offset origin,
    required Offset direction,
    double force = 1.0,
    double volume = 5.0,
    int particleCount = 50,
  }) {
    final newParticles = <CumParticle>[];
    for (int i = 0; i < particleCount; i++) {
      final spreadAngle = (_random.nextDouble() - 0.5) * 0.8;
      final baseAngle = atan2(direction.dy, direction.dx);
      final angle = baseAngle + spreadAngle;
      final speed = force * (200 + _random.nextDouble() * 400);
      final distFromCenter = _random.nextDouble();
      final size = 3.0 + (1.0 - distFromCenter) * 5.0;
      final particle = CumParticle(
        position: origin + Offset((_random.nextDouble() - 0.5) * 10, (_random.nextDouble() - 0.5) * 10),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        size: size,
        opacity: 0.9 + _random.nextDouble() * 0.1,
        life: 1.0,
      );
      newParticles.add(particle);
    }
    _particles.addAll(newParticles);
    return newParticles;
  }

  void update(double deltaTime, Size screenSize) {
    final gravity = Offset(0, 300);
    for (final particle in _particles) {
      if (particle.isStuck) continue;
      particle.velocity += gravity * deltaTime;
      particle.velocity *= (1.0 - 2.0 * deltaTime);
      particle.position += particle.velocity * deltaTime;
      particle.life -= deltaTime * 0.3;
      particle.opacity = particle.life;
      if (particle.position.dy > screenSize.height * 0.9 ||
          particle.position.dx < 0 ||
          particle.position.dx > screenSize.width) {
        particle.isStuck = true;
        particle.stuckPosition = particle.position;
        particle.velocity = Offset.zero;
      }
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  void render(Canvas canvas) {
    for (final particle in _particles) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..maskFilter = particle.isStuck ? null : const MaskFilter.blur(BlurStyle.normal, 2);
      if (particle.isStuck && particle.stuckPosition != null) {
        canvas.drawCircle(particle.stuckPosition!, particle.size * 1.5, paint..style = PaintingStyle.fill);
      } else {
        canvas.drawCircle(particle.position, particle.size, paint);
      }
    }
  }

  int get particleCount => _particles.length;
  void clear() => _particles.clear();
}
