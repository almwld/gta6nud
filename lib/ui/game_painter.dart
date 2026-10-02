import 'package:flutter/material.dart';
import 'package:gta6hub/engine/engine_integrator.dart';

class GamePainter extends CustomPainter {
  final EngineIntegrator engine;

  GamePainter({required this.engine});

  @override
  void paint(Canvas canvas, Size size) {
    engine.render(canvas, size);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
