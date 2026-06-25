import 'dart:math';
import 'package:flutter/material.dart';

class BodyPhysicsState {
  Offset position;
  Offset velocity;
  double rotation;
  double angularVelocity;
  double scale;
  double tension;
  double compression;
  double impactForce;
  bool isColliding;

  BodyPhysicsState({
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.rotation = 0,
    this.angularVelocity = 0,
    this.scale = 1.0,
    this.tension = 0,
    this.compression = 0,
    this.impactForce = 0,
    this.isColliding = false,
  });
}

class BodyContactPoint {
  final String name;
  final Offset localPosition;
  double pressure;
  double friction;
  double temperature;
  bool isActive;

  BodyContactPoint({
    required this.name,
    required this.localPosition,
    this.pressure = 0,
    this.friction = 0,
    this.temperature = 36.5,
    this.isActive = false,
  });
}

class BodyPhysicsController extends ChangeNotifier {
  final BodyPhysicsState _state = BodyPhysicsState();
  final List<BodyContactPoint> _contactPoints = [];
  final Random _random = Random();

  static const double gravity = 980;
  static const double damping = 0.95;
  static const double springConstant = 500;

  BodyPhysicsController() {
    _initContactPoints();
  }

  void _initContactPoints() {
    _contactPoints.addAll([
      BodyContactPoint(name: 'lips', localPosition: Offset(0, -0.85)),
      BodyContactPoint(name: 'neck', localPosition: Offset(0, -0.7)),
      BodyContactPoint(name: 'chest', localPosition: Offset(0, -0.5)),
      BodyContactPoint(name: 'belly', localPosition: Offset(0, -0.2)),
      BodyContactPoint(name: 'groin', localPosition: Offset(0, 0.1)),
      BodyContactPoint(name: 'thigh_left', localPosition: Offset(-0.15, 0.3)),
      BodyContactPoint(name: 'thigh_right', localPosition: Offset(0.15, 0.3)),
    ]);
  }

  void applyForce(Offset force) {
    _state.velocity += force;
    notifyListeners();
  }

  void applyImpulseAtPoint(String pointName, Offset impulse) {
    final point = _contactPoints.firstWhere(
      (p) => p.name == pointName,
      orElse: () => BodyContactPoint(name: pointName, localPosition: Offset.zero),
    );
    point.pressure = (point.pressure + impulse.distance).clamp(0, 1);
    point.isActive = true;
    _state.velocity += impulse * 0.1;
    _state.compression = (_state.compression + 0.1).clamp(0, 1);
    notifyListeners();
  }

  void update(double deltaTime) {
    _state.velocity += Offset(0, gravity * deltaTime);
    _state.velocity *= damping;
    _state.position += _state.velocity * deltaTime;
    _state.compression *= 0.9;
    _state.tension *= 0.9;
    _state.impactForce *= 0.8;
    for (final point in _contactPoints) {
      if (!point.isActive) {
        point.pressure *= 0.8;
        point.friction *= 0.9;
        point.temperature += (36.5 - point.temperature) * 0.1;
      }
      point.isActive = false;
    }
    notifyListeners();
  }

  void applyShake(double intensity) {
    final shakeX = (_random.nextDouble() - 0.5) * intensity * 20;
    final shakeY = (_random.nextDouble() - 0.5) * intensity * 20;
    _state.position += Offset(shakeX, shakeY);
    _state.tension = (_state.tension + intensity).clamp(0, 1);
    notifyListeners();
  }

  void reset() {
    _state.position = Offset.zero;
    _state.velocity = Offset.zero;
    _state.rotation = 0;
    _state.angularVelocity = 0;
    _state.scale = 1.0;
    _state.tension = 0;
    _state.compression = 0;
    _state.impactForce = 0;
    _state.isColliding = false;
    for (final point in _contactPoints) {
      point.pressure = 0;
      point.friction = 0;
      point.temperature = 36.5;
      point.isActive = false;
    }
    notifyListeners();
  }

  BodyPhysicsState get state => _state;
  List<BodyContactPoint> get contactPoints => _contactPoints;
  Offset get position => _state.position;
  Offset get velocity => _state.velocity;
  double get compression => _state.compression;
  double get tension => _state.tension;
  double get impactForce => _state.impactForce;
  bool get isColliding => _state.isColliding;

  BodyContactPoint? getContactPoint(String name) {
    try { return _contactPoints.firstWhere((p) => p.name == name); } catch (_) { return null; }
  }

  void heatPoint(String pointName, double amount) {
    final point = getContactPoint(pointName);
    if (point != null) {
      point.temperature = (point.temperature + amount).clamp(36.0, 42.0);
    }
  }
}
