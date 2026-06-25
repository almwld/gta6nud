import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gta6hub/engine/fluids/fluid_particle.dart';

class FluidSimulator {
  final List<FluidParticle> _particles = [];
  final Random _random = Random();

  void emitParticles(List<FluidParticle> newParticles) {
    _particles.addAll(newParticles);
  }

  void update(double deltaTime) {
    for (final p in _particles) {
      p.velocity += Offset(0, 200 * deltaTime);
      p.position += p.velocity * deltaTime;
      p.life -= deltaTime;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  void render(Canvas canvas) {
    for (final p in _particles) {
      canvas.drawCircle(p.position, p.size, Paint()..color = Colors.white.withOpacity(p.life));
    }
  }
}
