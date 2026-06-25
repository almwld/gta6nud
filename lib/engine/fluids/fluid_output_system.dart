import 'dart:math';
import 'package:flutter/material.dart';

/// قطرة سائل
class FluidDroplet {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  double life;
  bool isStuck;
  Color color;

  FluidDroplet({
    required this.position,
    required this.velocity,
    this.size = 4.0,
    this.opacity = 1.0,
    this.life = 1.0,
    this.isStuck = false,
    this.color = Colors.white,
  });
}

/// نظام الإخراج السائل المتكامل
class FluidOutputSystem {
  final List<FluidDroplet> _droplets = [];
  final Random _random = Random();
  
  // إعدادات
  double _gravity = 350;
  double _spreadAngle = 0.5; // راديان
  int _maxDroplets = 300;
  double _stickDamping = 0.3;

  /// إطلاق دفعة من السوائل من نقطة محددة
  void emitSpray({
    required Offset origin,
    required Offset direction,
    double force = 1.0,
    int count = 40,
    Color color = Colors.white,
    double spreadAngle = 0.5,
  }) {
    for (int i = 0; i < count; i++) {
      final baseAngle = atan2(direction.dy, direction.dx);
      final angle = baseAngle + (_random.nextDouble() - 0.5) * spreadAngle * 2;
      final speed = force * (150 + _random.nextDouble() * 350);
      
      _droplets.add(FluidDroplet(
        position: origin + Offset((_random.nextDouble() - 0.5) * 8, (_random.nextDouble() - 0.5) * 8),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        size: 2.0 + _random.nextDouble() * 5.0 * force,
        opacity: 0.8 + _random.nextDouble() * 0.2,
        life: 0.7 + _random.nextDouble() * 0.3,
        color: color,
      ));

      // إضافة قطرات ثانوية أصغر
      if (_random.nextDouble() < 0.4) {
        final secAngle = angle + (_random.nextDouble() - 0.5) * 0.3;
        final secSpeed = speed * 0.4;
        _droplets.add(FluidDroplet(
          position: origin,
          velocity: Offset(cos(secAngle) * secSpeed, sin(secAngle) * secSpeed),
          size: 1.0 + _random.nextDouble() * 2.0,
          opacity: 0.6 + _random.nextDouble() * 0.3,
          life: 0.5 + _random.nextDouble() * 0.3,
          color: color.withOpacity(0.7),
        ));
      }
    }

    // إزالة القطرات القديمة إذا تجاوزنا الحد
    while (_droplets.length > _maxDroplets) {
      _droplets.removeAt(0);
    }
  }

  /// إطلاق دفعات متزامنة مع موجات الذروة
  void emitOrgasmWaves({
    required Offset origin,
    required Offset direction,
    int waves = 5,
    double force = 1.0,
  }) {
    for (int wave = 0; wave < waves; wave++) {
      // كل موجة تأتي بقوة أقل قليلاً
      final waveForce = force * (1.0 - wave * 0.15);
      final waveCount = (40 - wave * 6).clamp(10, 40);
      
      // تأخير كل موجة (يتم التعامل معه عبر Ticker)
      // هنا نطلقها دفعة واحدة مع اختلاف بسيط في الزاوية
      final waveAngle = (_random.nextDouble() - 0.5) * 0.3 * wave;
      final waveDir = Offset(
        direction.dx * cos(waveAngle) - direction.dy * sin(waveAngle),
        direction.dx * sin(waveAngle) + direction.dy * cos(waveAngle),
      );
      
      emitSpray(
        origin: origin + Offset(0, -wave * 2.0),
        direction: waveDir,
        force: waveForce,
        count: waveCount,
        spreadAngle: 0.3 + wave * 0.05,
      );
    }
  }

  /// تحديث الفيزياء
  void update(double deltaTime, Size screenSize) {
    for (final droplet in _droplets) {
      if (droplet.isStuck) {
        // القطرة الملتصقة تتلاشى ببطء
        droplet.life -= deltaTime * 0.15;
        droplet.opacity = droplet.life.clamp(0.0, 1.0);
        continue;
      }

      // الجاذبية
      droplet.velocity += Offset(0, _gravity * deltaTime);
      
      // مقاومة الهواء
      droplet.velocity *= (1.0 - 1.8 * deltaTime);
      
      // تحديث الموقع
      droplet.position += droplet.velocity * deltaTime;
      
      // تقليل العمر
      droplet.life -= deltaTime * 0.25;
      droplet.opacity = droplet.life.clamp(0.0, 1.0);

      // الالتصاق بالأسفل
      if (droplet.position.dy >= screenSize.height - 5) {
        droplet.position = Offset(droplet.position.dx, screenSize.height - 5);
        droplet.velocity = Offset(droplet.velocity.dx * _stickDamping, 0);
        if (droplet.velocity.distance < 20) {
          droplet.isStuck = true;
        }
      }

      // الالتصاق بالجوانب
      if (droplet.position.dx <= 5 || droplet.position.dx >= screenSize.width - 5) {
        droplet.velocity = Offset(-droplet.velocity.dx * _stickDamping, droplet.velocity.dy);
        droplet.position = Offset(
          droplet.position.dx.clamp(5, screenSize.width - 5),
          droplet.position.dy,
        );
      }

      // الالتصاق بالأعلى
      if (droplet.position.dy <= 5) {
        droplet.position = Offset(droplet.position.dx, 5);
        droplet.velocity = Offset(droplet.velocity.dx * _stickDamping, 0);
        if (droplet.velocity.distance < 20) {
          droplet.isStuck = true;
        }
      }
    }

    // إزالة القطرات الميتة
    _droplets.removeWhere((d) => d.life <= 0);
  }

  /// رسم القطرات
  void render(Canvas canvas) {
    for (final droplet in _droplets) {
      final paint = Paint()
        ..color = droplet.color.withOpacity(droplet.opacity)
        ..maskFilter = droplet.isStuck
            ? null
            : const MaskFilter.blur(BlurStyle.normal, 1.5);

      if (droplet.isStuck) {
        // القطرة الملتصقة تتحول إلى بقعة بيضاوية
        canvas.drawOval(
          Rect.fromCenter(
            center: droplet.position,
            width: droplet.size * 3,
            height: droplet.size * 1.5,
          ),
          paint..style = PaintingStyle.fill,
        );
      } else {
        // القطرة الطائرة دائرية
        canvas.drawCircle(droplet.position, droplet.size, paint);
      }
    }
  }

  /// الحصول على عدد القطرات النشطة
  int get activeDroplets => _droplets.where((d) => d.life > 0.1).length;
  
  /// إجمالي القطرات
  int get totalDroplets => _droplets.length;

  /// مسح كل السوائل
  void clear() {
    _droplets.clear();
  }

  /// ضبط الجاذبية
  void setGravity(double g) => _gravity = g;
  
  /// ضبط أقصى عدد للقطرات
  void setMaxDroplets(int max) => _maxDroplets = max;
}
