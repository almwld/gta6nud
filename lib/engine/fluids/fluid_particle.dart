import 'package:flutter/material.dart';

class FluidParticle {
  Offset position;
  Offset velocity;
  double size;
  double life;

  FluidParticle({
    required this.position,
    required this.velocity,
    this.size = 3.0,
    this.life = 1.0,
  });
}
