import 'package:flutter/material.dart';
import 'package:gta6hub/engine/engine_integrator.dart';

class GamePainter extends CustomPainter {
  final EngineIntegrator engine;
  final double arousal;

  GamePainter({required this.engine, required this.arousal});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. تحديث المحرك وربطه بـ Canvas
    engine.render(canvas, size);
    
    // 2. رسم تأثيرات الجسيمات (السوائل) فوق الجسد
    engine.manager.cum.render(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
