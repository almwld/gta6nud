import 'dart:math';
import 'package:flutter/material.dart';

class FluidDroplet {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  double life;
  bool isStuck;
  bool isMerged;
  Color color;
  double surfaceFriction;

  FluidDroplet({
    required this.position,
    required this.velocity,
    this.size = 4.0,
    this.opacity = 1.0,
    this.life = 1.0,
    this.isStuck = false,
    this.isMerged = false,
    this.color = Colors.white,
    this.surfaceFriction = 0.0,
  });
}

class FluidOutputSystem {
  final List<FluidDroplet> _droplets = [];
  final Random _random = Random();

  double _gravity = 380;
  double _cohesionDistance = 30;
  double _mergeChance = 0.6;
  int _maxDroplets = 250;
  double _surfaceTension = 0.15;

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
      final speed = force * (120 + _random.nextDouble() * 400);

      _droplets.add(FluidDroplet(
        position: origin + Offset((_random.nextDouble() - 0.5) * 6, (_random.nextDouble() - 0.5) * 6),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        size: 1.5 + _random.nextDouble() * 5.5 * force,
        opacity: 0.8 + _random.nextDouble() * 0.2,
        life: 0.7 + _random.nextDouble() * 0.3,
        color: color,
        surfaceFriction: 0.1 + _random.nextDouble() * 0.3,
      ));
    }

    while (_droplets.length > _maxDroplets) {
      _droplets.removeAt(0);
    }
  }

  void emitOrgasmWaves({
    required Offset origin,
    required Offset direction,
    int waves = 5,
    double force = 1.0,
  }) {
    for (int wave = 0; wave < waves; wave++) {
      final waveForce = force * (1.0 - wave * 0.12);
      final waveCount = (50 - wave * 8).clamp(8, 50);
      final waveAngle = (_random.nextDouble() - 0.5) * 0.35 * wave;
      final waveDir = Offset(
        direction.dx * cos(waveAngle) - direction.dy * sin(waveAngle),
        direction.dx * sin(waveAngle) + direction.dy * cos(waveAngle),
      );
      emitSpray(origin: origin + Offset(0, -wave * 1.5), direction: waveDir, force: waveForce, count: waveCount, spreadAngle: 0.25 + wave * 0.06);
    }
  }

  void update(double deltaTime, Size screenSize) {
    // === التماسك: دمج القطرات القريبة ===
    _applyCohesion(screenSize);

    for (final droplet in _droplets) {
      if (droplet.isMerged) continue;

      if (droplet.isStuck) {
        droplet.life -= deltaTime * 0.12;
        droplet.opacity = droplet.life.clamp(0.0, 1.0);
        // الانزلاق البطيء للقطرات الملتصقة
        droplet.velocity *= 0.95;
        droplet.position += droplet.velocity * deltaTime * 0.1;
        continue;
      }

      // الجاذبية
      droplet.velocity += Offset(0, _gravity * deltaTime);
      // مقاومة الهواء
      droplet.velocity *= (1.0 - 2.2 * deltaTime);
      // تحديث الموقع
      droplet.position += droplet.velocity * deltaTime;
      // تقليل العمر
      droplet.life -= deltaTime * 0.22;
      droplet.opacity = droplet.life.clamp(0.0, 1.0);

      // الالتصاق بالأسفل مع انزلاق
      if (droplet.position.dy >= screenSize.height - 5) {
        droplet.position = Offset(droplet.position.dx, screenSize.height - 5);
        droplet.velocity = Offset(droplet.velocity.dx * droplet.surfaceFriction, 0);
        if (droplet.velocity.distance < 15) {
          droplet.isStuck = true;
        }
      }

      // الالتصاق بالجوانب
      if (droplet.position.dx <= 5 || droplet.position.dx >= screenSize.width - 5) {
        droplet.velocity = Offset(-droplet.velocity.dx * droplet.surfaceFriction, droplet.velocity.dy * 0.7);
        droplet.position = Offset(droplet.position.dx.clamp(5, screenSize.width - 5), droplet.position.dy);
      }

      // الالتصاق بالأعلى
      if (droplet.position.dy <= 5) {
        droplet.position = Offset(droplet.position.dx, 5);
        droplet.velocity = Offset(droplet.velocity.dx * droplet.surfaceFriction, 0);
        if (droplet.velocity.distance < 15) droplet.isStuck = true;
      }
    }

    // إزالة المدمجة والميتة
    _droplets.removeWhere((d) => d.isMerged || d.life <= 0);
  }

  void _applyCohesion(Size screenSize) {
    for (int i = 0; i < _droplets.length; i++) {
      if (_droplets[i].isStuck || _droplets[i].isMerged) continue;
      for (int j = i + 1; j < _droplets.length; j++) {
        if (_droplets[j].isStuck || _droplets[j].isMerged) continue;
        final distance = (_droplets[i].position - _droplets[j].position).distance;
        if (distance < _cohesionDistance && _random.nextDouble() < _mergeChance * 0.05) {
          // دمج القطرتين
          _droplets[i].size = sqrt(_droplets[i].size * _droplets[i].size + _droplets[j].size * _droplets[j].size);
          _droplets[i].velocity = (_droplets[i].velocity + _droplets[j].velocity) * 0.5;
          _droplets[i].life = max(_droplets[i].life, _droplets[j].life);
          _droplets[j].isMerged = true;
        }
      }
    }
  }

  void render(Canvas canvas) {
    for (final droplet in _droplets) {
      if (droplet.isMerged) continue;
      final paint = Paint()
        ..color = droplet.color.withOpacity(droplet.opacity)
        ..maskFilter = droplet.isStuck ? null : const MaskFilter.blur(BlurStyle.normal, 1.2);

      if (droplet.isStuck) {
        // بقعة بيضاوية مع انسياب
        final width = droplet.size * 3.5 * (1.0 + droplet.surfaceFriction);
        final height = droplet.size * 1.8;
        canvas.drawOval(Rect.fromCenter(center: droplet.position, width: width, height: height), paint..style = PaintingStyle.fill);
      } else {
        canvas.drawCircle(droplet.position, droplet.size, paint);
      }
    }
  }

  int get activeDroplets => _droplets.where((d) => !d.isMerged && d.life > 0.1).length;
  int get totalDroplets => _droplets.length;
  void clear() => _droplets.clear();
  void setGravity(double g) => _gravity = g;
  void setMaxDroplets(int max) => _maxDroplets = max;
}
