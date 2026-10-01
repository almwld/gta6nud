import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Generic lightweight 2D body-physics controller.
///
/// Keeps the simulation state self-contained and exposes only neutral
/// position/velocity/rotation primitives for rendering and animation systems.
class BodyPhysicsController extends ChangeNotifier {
  static const double gravity = 1200.0;
  static const double damping = 0.92;
  static const double springConstant = 700.0;

  Offset _position = Offset.zero;
  Offset _velocity = Offset.zero;
  double _rotation = 0.0;

  Offset get position => _position;
  Offset get velocity => _velocity;
  double get rotation => _rotation;

  void update(double deltaTime, {Offset force = Offset.zero}) {
    if (deltaTime <= 0) return;

    final acceleration = Offset(
      force.dx,
      force.dy + gravity,
    );

    _velocity += acceleration * deltaTime;
    _velocity *= damping;
    _position += _velocity * deltaTime;
    _rotation += _velocity.dx * 0.01 * deltaTime;

    notifyListeners();
  }

  void applyForce(Offset force, {double deltaTime = 1.0}) {
    if (deltaTime <= 0) return;
    _velocity += force * deltaTime;
    notifyListeners();
  }

  void applyImpulse(Offset impulse) {
    _velocity += impulse;
    notifyListeners();
  }

  void reset() {
    _position = Offset.zero;
    _velocity = Offset.zero;
    _rotation = 0.0;
    notifyListeners();
  }
}
