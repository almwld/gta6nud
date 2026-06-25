import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gta6hub/engine/body/body_motion_engine.dart';

class BodyZone {
  final String name;
  final List<Offset> polygon;
  double sensitivity;
  double arousal;
  bool isBeingTouched;
  double touchPressure;

  BodyZone({
    required this.name,
    required this.polygon,
    this.sensitivity = 0.5,
    this.arousal = 0.0,
    this.isBeingTouched = false,
    this.touchPressure = 0.0,
  });

  bool containsPoint(Offset point, Size screenSize) {
    final absPolygon = polygon.map((p) => Offset(p.dx * screenSize.width, p.dy * screenSize.height)).toList();
    return _isPointInPolygon(point, absPolygon);
  }

  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          point.dx < (polygon[j].dx - polygon[i].dx) * (point.dy - polygon[i].dy) / (polygon[j].dy - polygon[i].dy) + polygon[i].dx) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}

class LiveBodyRenderer {
  final List<BodyZone> _zones = [];
  final BodyMotionEngine _motion = BodyMotionEngine();
  double _globalArousal = 0.0;
  double _time = 0.0;

  LiveBodyRenderer() {
    _initZones();
  }

  void _initZones() {
    _zones.addAll([
      BodyZone(name: 'head', polygon: [Offset(0.35, 0.0), Offset(0.65, 0.0), Offset(0.7, 0.18), Offset(0.3, 0.18)], sensitivity: 0.3),
      BodyZone(name: 'neck', polygon: [Offset(0.42, 0.16), Offset(0.58, 0.16), Offset(0.56, 0.22), Offset(0.44, 0.22)], sensitivity: 0.6),
      BodyZone(name: 'chest', polygon: [Offset(0.22, 0.22), Offset(0.78, 0.22), Offset(0.82, 0.42), Offset(0.18, 0.42)], sensitivity: 0.7),
      BodyZone(name: 'belly', polygon: [Offset(0.22, 0.42), Offset(0.78, 0.42), Offset(0.74, 0.58), Offset(0.26, 0.58)], sensitivity: 0.5),
      BodyZone(name: 'groin', polygon: [Offset(0.3, 0.55), Offset(0.7, 0.55), Offset(0.72, 0.68), Offset(0.28, 0.68)], sensitivity: 0.95),
      BodyZone(name: 'left_thigh', polygon: [Offset(0.2, 0.66), Offset(0.48, 0.66), Offset(0.45, 0.88), Offset(0.18, 0.88)], sensitivity: 0.6),
      BodyZone(name: 'right_thigh', polygon: [Offset(0.52, 0.66), Offset(0.8, 0.66), Offset(0.82, 0.88), Offset(0.55, 0.88)], sensitivity: 0.6),
      BodyZone(name: 'left_arm', polygon: [Offset(0.1, 0.22), Offset(0.2, 0.22), Offset(0.18, 0.55), Offset(0.08, 0.55)], sensitivity: 0.4),
      BodyZone(name: 'right_arm', polygon: [Offset(0.8, 0.22), Offset(0.9, 0.22), Offset(0.92, 0.55), Offset(0.82, 0.55)], sensitivity: 0.4),
    ]);
  }

  void update(double deltaTime, double arousal) {
    _time += deltaTime;
    _globalArousal = arousal.clamp(0.0, 1.0);
    _motion.update(deltaTime, arousal);
    for (final zone in _zones) {
      if (!zone.isBeingTouched) {
        zone.arousal *= 0.92;
        zone.touchPressure *= 0.85;
      }
      zone.isBeingTouched = false;
    }
  }

  void touchAt(Offset globalPosition, Size screenSize) {
    for (final zone in _zones) {
      if (zone.containsPoint(globalPosition, screenSize)) {
        zone.isBeingTouched = true;
        zone.touchPressure = (zone.touchPressure + 0.2).clamp(0.0, 1.0);
        zone.arousal = (zone.arousal + zone.sensitivity * 0.15).clamp(0.0, 1.0);
      }
    }
  }

  BodyZone? get mostArousedZone {
    if (_zones.isEmpty) return null;
    return _zones.reduce((a, b) => a.arousal > b.arousal ? a : b);
  }

  double get globalArousal => _globalArousal;

  void render(Canvas canvas, Size screenSize) {
    final w = screenSize.width;
    final h = screenSize.height;
    
    final breathY = _motion.breathOffset * h;
    final tremorX = _motion.tremorOffset * w * 0.02;
    final tremorY = _motion.tremorOffset * h * 0.02;
    final hipSway = _motion.hipSway * w;
    
    final cx = w / 2 + tremorX + hipSway;
    final baseY = h * 0.05 + breathY + tremorY;

    // === تأثير Subsurface Scattering (توهج تحت الجلد) ===
    _drawSSSGlow(canvas, screenSize);

    _drawHead(canvas, Offset(cx, baseY), w * 0.13);
    _drawNeck(canvas, Offset(cx, baseY + h * 0.12), w * 0.07, h * 0.06);
    final shoulderY = baseY + h * 0.18 + _motion.shoulderShrug * h;
    _drawShoulders(canvas, Offset(cx, shoulderY), w * 0.38);
    final chestBreathExpand = 1.0 + _motion.breathOffset * 0.5;
    final chestTop = shoulderY + h * 0.02;
    final chestBottom = shoulderY + h * 0.18;
    _drawChest(canvas, Offset(cx, chestTop), Offset(cx, chestBottom), w * 0.22 * chestBreathExpand, w * 0.32 * chestBreathExpand);
    final bellyBottom = chestBottom + h * 0.16;
    _drawBelly(canvas, Offset(cx, chestBottom), Offset(cx + hipSway * 0.5, bellyBottom), w * 0.3);
    _drawGroin(canvas, Offset(cx + hipSway * 0.5, bellyBottom + h * 0.02), w * 0.14, h * 0.1);
    if (_globalArousal > 0.2) {
      _drawPenis(canvas, Offset(cx + hipSway * 0.5, bellyBottom + h * 0.06), w * 0.04 * _motion.erectionPulse, h * 0.15 * _motion.erectionPulse, _motion.erectionAngle);
    }
    _drawThighs(canvas, Offset(cx + hipSway * 0.5, bellyBottom + h * 0.08), w * 0.12, h * 0.32);
    _drawArms(canvas, Offset(cx, shoulderY), w * 0.38, h * 0.32);
    _drawZones(canvas, screenSize);
  }

  /// تأثير توهج تحت الجلد (Subsurface Scattering)
  void _drawSSSGlow(Canvas canvas, Size screenSize) {
    if (_globalArousal < 0.2) return;
    final glowOpacity = (_globalArousal - 0.2) * 0.3;
    final center = Offset(screenSize.width / 2, screenSize.height * 0.35);
    final glowRadius = screenSize.width * 0.5 * (1.0 + _globalArousal * 0.3);
    
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.6,
        colors: [
          const Color(0xFFFF6B6B).withOpacity(glowOpacity * 0.6),
          const Color(0xFFFF4444).withOpacity(glowOpacity * 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
    
    canvas.drawCircle(center, glowRadius, glowPaint);
  }

  void _drawHead(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center + Offset(2, 2), radius, Paint()..color = const Color(0xFFD4A878));
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFE8C0A0));
    final hlPaint = Paint()
      ..shader = RadialGradient(colors: [const Color(0xFFF0D8C0).withOpacity(0.6), Colors.transparent])
          .createShader(Rect.fromCircle(center: center - Offset(radius * 0.3, radius * 0.3), radius: radius));
    canvas.drawCircle(center, radius, hlPaint);

    final eyeY = center.dy - radius * 0.1;
    canvas.drawCircle(Offset(center.dx - radius * 0.35, eyeY), radius * 0.1, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx + radius * 0.35, eyeY), radius * 0.1, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx - radius * 0.35, eyeY), radius * 0.05, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(center.dx + radius * 0.35, eyeY), radius * 0.05, Paint()..color = Colors.black);

    final browPaint = Paint()..color = Colors.brown..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - radius * 0.45, eyeY - radius * 0.15), Offset(center.dx - radius * 0.2, eyeY - radius * 0.2), browPaint);
    canvas.drawLine(Offset(center.dx + radius * 0.45, eyeY - radius * 0.15), Offset(center.dx + radius * 0.2, eyeY - radius * 0.2), browPaint);

    final mouthY = center.dy + radius * 0.35;
    final mouthOpen = _globalArousal > 0.7 ? _globalArousal * radius * 0.3 : 0;
    final mouthPath = Path()
      ..moveTo(center.dx - radius * 0.3, mouthY)
      ..quadraticBezierTo(center.dx, mouthY + radius * 0.2 + mouthOpen, center.dx + radius * 0.3, mouthY);
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFFD08880)..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  void _drawNeck(Canvas canvas, Offset top, double width, double height) {
    final path = Path()
      ..moveTo(top.dx - width, top.dy)
      ..quadraticBezierTo(top.dx - width * 0.8, top.dy + height * 0.5, top.dx - width * 0.7, top.dy + height)
      ..lineTo(top.dx + width * 0.7, top.dy + height)
      ..quadraticBezierTo(top.dx + width * 0.8, top.dy + height * 0.5, top.dx + width, top.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE8C0A0));
    canvas.drawCircle(top + Offset(0, height * 0.4), width * 0.3, Paint()..color = const Color(0xFFD4A878).withOpacity(0.4));
  }

  void _drawShoulders(Canvas canvas, Offset center, double width) {
    final path = Path()
      ..moveTo(center.dx - width, center.dy)
      ..quadraticBezierTo(center.dx - width * 0.7, center.dy - width * 0.12, center.dx - width * 0.5, center.dy + width * 0.15)
      ..lineTo(center.dx + width * 0.5, center.dy + width * 0.15)
      ..quadraticBezierTo(center.dx + width * 0.7, center.dy - width * 0.12, center.dx + width, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE8C0A0));
  }

  void _drawChest(Canvas canvas, Offset top, Offset bottom, double topWidth, double bottomWidth) {
    final path = Path()
      ..moveTo(top.dx - topWidth, top.dy)
      ..quadraticBezierTo(top.dx - topWidth * 1.05, top.dy + (bottom.dy - top.dy) * 0.4, bottom.dx - bottomWidth, bottom.dy)
      ..lineTo(bottom.dx + bottomWidth, bottom.dy)
      ..quadraticBezierTo(top.dx + topWidth * 1.05, top.dy + (bottom.dy - top.dy) * 0.4, top.dx + topWidth, top.dy)
      ..close();
    
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFFF0D8C0), const Color(0xFFE8C0A0), const Color(0xFFD4A878)],
    ).createShader(Rect.fromLTRB(top.dx - topWidth, top.dy, top.dx + topWidth, bottom.dy));
    canvas.drawPath(path, Paint()..shader = gradient);

    final musclePath = Path()
      ..moveTo(top.dx - topWidth * 0.7, top.dy + (bottom.dy - top.dy) * 0.2)
      ..quadraticBezierTo(top.dx, top.dy + (bottom.dy - top.dy) * 0.1, top.dx + topWidth * 0.7, top.dy + (bottom.dy - top.dy) * 0.2);
    canvas.drawPath(musclePath, Paint()..color = const Color(0xFFD4A878).withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 2);

    final nippleY = top.dy + (bottom.dy - top.dy) * 0.35;
    _drawNipple(canvas, Offset(top.dx - topWidth * 0.38, nippleY));
    _drawNipple(canvas, Offset(top.dx + topWidth * 0.38, nippleY));
  }

  void _drawNipple(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFFC08870));
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFFC08870).withOpacity(0.7));
    canvas.drawCircle(center, 12, Paint()..color = const Color(0xFFC08870).withOpacity(0.2));
  }

  void _drawBelly(Canvas canvas, Offset top, Offset bottom, double width) {
    final path = Path()
      ..moveTo(top.dx - width, top.dy)
      ..quadraticBezierTo(top.dx - width * 0.9, top.dy + (bottom.dy - top.dy) * 0.5, bottom.dx - width * 0.75, bottom.dy)
      ..lineTo(bottom.dx + width * 0.75, bottom.dy)
      ..quadraticBezierTo(top.dx + width * 0.9, top.dy + (bottom.dy - top.dy) * 0.5, top.dx + width, top.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE8C0A0));
    canvas.drawCircle(Offset(bottom.dx, top.dy + (bottom.dy - top.dy) * 0.3), width * 0.1, Paint()..color = const Color(0xFFD4A878).withOpacity(0.5));
  }

  void _drawGroin(Canvas canvas, Offset center, double width, double height) {
    final path = Path()
      ..moveTo(center.dx - width, center.dy)
      ..quadraticBezierTo(center.dx - width * 0.6, center.dy + height * 0.6, center.dx, center.dy + height)
      ..quadraticBezierTo(center.dx + width * 0.6, center.dy + height * 0.6, center.dx + width, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFD4A878));
  }

  void _drawPenis(Canvas canvas, Offset base, double width, double height, double angle) {
    final tip = base + Offset(cos(angle) * height, sin(angle) * height);
    final path = Path()
      ..moveTo(base.dx - width, base.dy)
      ..quadraticBezierTo(base.dx - width * 0.5, tip.dy * 0.5, tip.dx - width * 0.3, tip.dy)
      ..lineTo(tip.dx + width * 0.3, tip.dy)
      ..quadraticBezierTo(base.dx + width * 0.5, tip.dy * 0.5, base.dx + width, base.dy)
      ..close();
    
    final shaftGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFFD4A090), const Color(0xFFC08080).withOpacity(0.8 + _globalArousal * 0.2)],
    ).createShader(Rect.fromLTRB(base.dx - width, base.dy, base.dx + width, tip.dy));
    canvas.drawPath(path, Paint()..shader = shaftGradient);
    canvas.drawCircle(tip, width * 1.5, Paint()..color = const Color(0xFFC06070));
  }

  void _drawThighs(Canvas canvas, Offset top, double width, double height) {
    for (int side = -1; side <= 1; side += 2) {
      final dx = side * width * 1.2;
      final path = Path()
        ..moveTo(top.dx + dx - width * 0.8, top.dy)
        ..quadraticBezierTo(top.dx + dx - width * 0.9, top.dy + height * 0.5, top.dx + dx - width * 0.6, top.dy + height)
        ..lineTo(top.dx + dx + width * 0.6, top.dy + height)
        ..quadraticBezierTo(top.dx + dx + width * 0.9, top.dy + height * 0.5, top.dx + dx + width * 0.8, top.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFE8C0A0));
    }
  }

  void _drawArms(Canvas canvas, Offset shoulderCenter, double shoulderWidth, double length) {
    for (int side = -1; side <= 1; side += 2) {
      final dx = side * shoulderWidth * 0.85;
      final path = Path()
        ..moveTo(shoulderCenter.dx + dx - shoulderWidth * 0.08, shoulderCenter.dy)
        ..quadraticBezierTo(shoulderCenter.dx + dx - shoulderWidth * 0.12, shoulderCenter.dy + length * 0.4, shoulderCenter.dx + dx - shoulderWidth * 0.06, shoulderCenter.dy + length)
        ..lineTo(shoulderCenter.dx + dx + shoulderWidth * 0.06, shoulderCenter.dy + length)
        ..quadraticBezierTo(shoulderCenter.dx + dx + shoulderWidth * 0.12, shoulderCenter.dy + length * 0.4, shoulderCenter.dx + dx + shoulderWidth * 0.08, shoulderCenter.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFE8C0A0));
      canvas.drawCircle(Offset(shoulderCenter.dx + dx, shoulderCenter.dy + length), shoulderWidth * 0.08, Paint()..color = const Color(0xFFE8C0A0));
    }
  }

  void _drawZones(Canvas canvas, Size screenSize) {
    for (final zone in _zones) {
      if (zone.arousal > 0.05 || zone.isBeingTouched) {
        final absPolygon = zone.polygon.map((p) => Offset(p.dx * screenSize.width, p.dy * screenSize.height)).toList();
        final path = Path()..moveTo(absPolygon.first.dx, absPolygon.first.dy);
        for (int i = 1; i < absPolygon.length; i++) {
          path.lineTo(absPolygon[i].dx, absPolygon[i].dy);
        }
        path.close();
        final opacity = zone.isBeingTouched ? 0.3 + zone.arousal * 0.4 : zone.arousal * 0.2;
        canvas.drawPath(path, Paint()..color = const Color(0xFFFF2A6D).withOpacity(opacity)..style = PaintingStyle.fill);
        canvas.drawPath(path, Paint()..color = const Color(0xFFFF2A6D).withOpacity(opacity + 0.1)..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }
  }
}
