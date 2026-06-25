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
  double viscosity;
  List<Offset> trail;

  FluidDroplet({
    required this.position,
    required this.velocity,
    this.size = 4.0,
    this.opacity = 1.0,
    this.life = 1.0,
    this.isStuck = false,
    this.isMerged = false,
    this.color = Colors.white,
    this.surfaceFriction = 0.15,
    this.viscosity = 1.0,
    List<Offset>? trail,
  }) : trail = trail ?? [];
}

class FluidOutputSystem {
  final List<FluidDroplet> _droplets = [];
  final Random _random = Random();

  double _gravity = 380;
  double _cohesionDistance = 35;
  double _mergeChance = 0.5;
  int _maxDroplets = 250;
  double _globalViscosity = 1.0;

  void emitSpray({
    required Offset origin,
    required Offset direction,
    double force = 1.0,
    int count = 40,
    Color color = Colors.white,
    double spreadAngle = 0.5,
    double viscosity = 1.0,
  }) {
    for (int i = 0; i < count; i++) {
      final baseAngle = atan2(direction.dy, direction.dx);
      final angle = baseAngle + (_random.nextDouble() - 0.5) * spreadAngle * 2;
      // اللزوجة تقلل السرعة
      final speed = force * (120 + _random.nextDouble() * 400) / viscosity;

      _droplets.add(FluidDroplet(
        position: origin + Offset((_random.nextDouble() - 0.5) * 6, (_random.nextDouble() - 0.5) * 6),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        size: 1.5 + _random.nextDouble() * 5.5 * force,
        opacity: 0.8 + _random.nextDouble() * 0.2,
        life: 0.7 + _random.nextDouble() * 0.3,
        color: color,
        surfaceFriction: 0.1 + _random.nextDouble() * 0.3,
        viscosity: viscosity,
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
    double viscosity = 1.5,
  }) {
    _globalViscosity = viscosity;
    for (int wave = 0; wave < waves; wave++) {
      final waveForce = force * (1.0 - wave * 0.12);
      final waveCount = (50 - wave * 8).clamp(8, 50);
      final waveAngle = (_random.nextDouble() - 0.5) * 0.35 * wave;
      final waveDir = Offset(
        direction.dx * cos(waveAngle) - direction.dy * sin(waveAngle),
        direction.dx * sin(waveAngle) + direction.dy * cos(waveAngle),
      );
      emitSpray(
        origin: origin + Offset(0, -wave * 1.5),
        direction: waveDir,
        force: waveForce,
        count: waveCount,
        spreadAngle: 0.25 + wave * 0.06,
        viscosity: viscosity * (1.0 + wave * 0.2),
      );
    }
  }

  void update(double deltaTime, Size screenSize) {
    _applyCohesion(screenSize);

    for (final droplet in _droplets) {
      if (droplet.isMerged) continue;

      if (droplet.isStuck) {
        droplet.life -= deltaTime * 0.1;
        droplet.opacity = droplet.life.clamp(0.0, 1.0);
        droplet.velocity *= 0.92;
        droplet.position += droplet.velocity * deltaTime * 0.05;
        continue;
      }

      // الجاذبية مع اللزوجة
      droplet.velocity += Offset(0, _gravity * deltaTime / droplet.viscosity);
      // مقاومة الهواء مع اللزوجة
      droplet.velocity *= (1.0 - 2.5 * deltaTime / droplet.viscosity);
      // تحديث الموقع
      droplet.position += droplet.velocity * deltaTime;
      // إضافة نقطة للأثر
      droplet.trail.add(droplet.position);
      if (droplet.trail.length > 8) droplet.trail.removeAt(0);
      // تقليل العمر
      droplet.life -= deltaTime * 0.2;
      droplet.opacity = droplet.life.clamp(0.0, 1.0);

      // الالتصاق بالأسفل
      if (droplet.position.dy >= screenSize.height - 5) {
        droplet.position = Offset(droplet.position.dx, screenSize.height - 5);
        droplet.velocity = Offset(droplet.velocity.dx * droplet.surfaceFriction, 0);
        if (droplet.velocity.distance < 15) droplet.isStuck = true;
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

    _droplets.removeWhere((d) => d.isMerged || d.life <= 0);
  }

  void _applyCohesion(Size screenSize) {
    for (int i = 0; i < _droplets.length; i++) {
      if (_droplets[i].isStuck || _droplets[i].isMerged) continue;
      for (int j = i + 1; j < _droplets.length; j++) {
        if (_droplets[j].isStuck || _droplets[j].isMerged) continue;
        final distance = (_droplets[i].position - _droplets[j].position).distance;
        if (distance < _cohesionDistance && _random.nextDouble() < _mergeChance * 0.04) {
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

      // رسم الأثر
      if (droplet.trail.length > 1 && !droplet.isStuck) {
        final trailPaint = Paint()
          ..color = droplet.color.withOpacity(droplet.opacity * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = droplet.size * 0.4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        final trailPath = Path()..moveTo(droplet.trail.first.dx, droplet.trail.first.dy);
        for (int i = 1; i < droplet.trail.length; i++) {
          trailPath.lineTo(droplet.trail[i].dx, droplet.trail[i].dy);
        }
        canvas.drawPath(trailPath, trailPaint);
      }

      final paint = Paint()
        ..color = droplet.color.withOpacity(droplet.opacity)
        ..maskFilter = droplet.isStuck ? null : const MaskFilter.blur(BlurStyle.normal, 1.2);

      if (droplet.isStuck) {
        final width = droplet.size * 3.5 * (1.0 + droplet.surfaceFriction);
        final height = droplet.size * 1.8;
        canvas.drawOval(Rect.fromCenter(center: droplet.position, width: width, height: height), paint..style = PaintingStyle.fill);
        // لمعان خفيف
        final shinePaint = Paint()
          ..color = Colors.white.withOpacity(droplet.opacity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawOval(Rect.fromCenter(center: droplet.position + Offset(0, -height * 0.2), width: width * 0.3, height: height * 0.2), shinePaint);
      } else {
        canvas.drawCircle(droplet.position, droplet.size, paint);
        // لمعان
        canvas.drawCircle(droplet.position + Offset(-droplet.size * 0.2, -droplet.size * 0.3), droplet.size * 0.3, Paint()..color = Colors.white.withOpacity(droplet.opacity * 0.4));
      }
    }
  }

  int get activeDroplets => _droplets.where((d) => !d.isMerged && d.life > 0.1).length;
  int get totalDroplets => _droplets.length;
  void clear() => _droplets.clear();
  void setGravity(double g) => _gravity = g;
  void setMaxDroplets(int max) => _maxDroplets = max;
  double get globalViscosity => _globalViscosity;
  void setGlobalViscosity(double v) => _globalViscosity = v;
}
