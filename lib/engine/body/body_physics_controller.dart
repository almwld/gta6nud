import 'dart:math';
import 'package:flutter/material.dart';

// ... (باقي الكلاسات كما هي) ...

class BodyPhysicsController extends ChangeNotifier {
  // ... (المتغيرات كما هي) ...

  static const double gravity = 1200; // زيادة الجاذبية بنسبة 20% لتكون الحركة أثقل وأكثر واقعية
  static const double damping = 0.92; // تقليل التخميد قليلاً لاستمرار الزخم
  static const double springConstant = 700; // زيادة الصلابة لرد فعل أسرع

  // ... (باقي الدوال كما هي) ...

  void update(double deltaTime) {
    // تطبيق الجاذبية
    _state.velocity += Offset(0, gravity * deltaTime);
    // تخميد السرعة
    _state.velocity *= damping;
    // تحديث الموقع
    _state.position += _state.velocity * deltaTime;
    // تخميد أبطأ للضغط (ليبقى تأثير الانضغاط أطول)
    _state.compression *= 0.95;
    _state.tension *= 0.95;
    _state.impactForce *= 0.85;

    // ... (تحديث نقاط التلامس) ...
    notifyListeners();
  }
}
