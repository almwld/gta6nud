import 'package:flutter/material.dart';
import 'package:gta6hub/engine/engine_integrator.dart';
import 'package:gta6hub/ui/game_painter.dart';

class GameScreen extends StatelessWidget {
  final EngineIntegrator engine;

  const GameScreen({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // طبقة المحرك (الرسوم والفيزياء)
          CustomPaint(
            painter: GamePainter(
              engine: engine,
              arousal: engine.manager.receiverPleasure,
            ),
            size: Size.infinite,
          ),
          // طبقة الـ HUD (الأزرار والعدادات التي صممتها)
          // هنا يمكنك استدعاء الـ HUD الخاص بك
        ],
      ),
    );
  }
}
