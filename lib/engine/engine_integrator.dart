import 'package:flutter/material.dart';
import 'package:gta6hub/core/pleasure_manager.dart';
import 'package:gta6hub/engine/body/body_renderer.dart';
import 'package:gta6hub/engine/body/body_animation_controller.dart';
import 'package:gta6hub/engine/body/body_physics_controller.dart';

/// المحرك الموحد - يربط كل الأنظمة ببعضها
class EngineIntegrator {
  final PleasureManager manager;
  final BodyRenderer renderer;
  final BodyAnimationController animation;
  final BodyPhysicsController physics;

  EngineIntegrator({
    required this.manager,
    required this.renderer,
    required this.animation,
    required this.physics,
  });

  /// نبض المحرك (يُستدعى في كل إطار)
  void update(double deltaTime, Size size) {
    // 1. تحديث الفيزياء بناءً على المدخلات
    physics.update(deltaTime);

    // 2. تحديث الحركة بناءً على حالة الإثارة
    final arousal = manager.receiverPleasure;
    if (arousal > 0.9) {
      animation.play(BodyAnimationType.climaxing);
    } else if (arousal > 0.3) {
      animation.play(BodyAnimationType.thrusting);
    } else {
      animation.play(BodyAnimationType.breathing);
    }
    animation.update(deltaTime);

    // 3. تحديث حالة الجلد
    renderer.skinState.updateFromArousal(arousal);
  }

  /// الرسم (Rendering)
  void render(Canvas canvas, Size size) {
    // رسم الجسد مع تطبيق تأثيرات الحركة والفيزياء
    renderer.render(
      canvas, 
      size, 
      manager.receiverPleasure
    );
  }
}
