import 'dart:math';
import 'package:flutter/material.dart';

/// محرك فيزياء الجسد - المسؤول عن محاكاة ردود الفعل
class BodyPhysicsController {
  final Random _random = Random();
  
  // بارامترات الفيزياء
  double mass = 1.0;
  double springStiffness = 0.5;
  double damping = 0.1;
  
  // حالة الحركة الحالية
  Offset position = Offset.zero;
  Offset velocity = Offset.zero;
  double rotation = 0.0;

  /// تحديث المحاكاة الفيزيائية (يُستدعى في كل إطار)
  void update(double deltaTime, {Offset force = Offset.zero}) {
    // 1. تطبيق القوة (Force = Mass * Acceleration)
    Offset acceleration = force / mass;
    
    // 2. تحديث السرعة والموقع (Integrator)
    velocity += acceleration * deltaTime;
    velocity *= (1.0 - damping); // الاحتكاك
    position += velocity * deltaTime;
    
    // 3. محاكاة التذبذب الطبيعي للجسد (Spring System)
    rotation += (velocity.dx * 0.01);
  }

  /// إحداث هزّة أو حركة مفاجئة (عند حدوث إيلاج أو حركة قوية)
  void applyImpact(Offset impactForce) {
    velocity += impactForce;
  }
}
