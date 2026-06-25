import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gta6hub/engine/fluids/fluid_particle.dart';

class FluidEmitter {
  final Random _random = Random();

  List<FluidParticle> emitCum(Offset origin, Offset direction, double force) {
    final particles = <FluidParticle>[];
    for (int i = 0; i < 30; i++) {
      final angle = atan2(direction.dy, direction.dx) + (_random.nextDouble() - 0.5) * 0.8;
      final speed = force * (100 + _random.nextDouble() * 200);
      particles.add(FluidParticle(
        position: origin + Offset((_random.nextDouble() - 0.5) * 10, (_random.nextDouble() - 0.5) * 10),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        size: 2 + _random.nextDouble() * 4,
        life: 0.8 + _random.nextDouble() * 0.2,
      ));
    }
    return particles;
  }
}
