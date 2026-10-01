import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Neutral character animation states shared by the character presentation layer.
enum CharacterAnimationState {
  idle,
  walk,
  run,
  fall,
}

/// Single state machine for character presentation transitions.
///
/// The controller owns transition decisions and exposes the current state to
/// renderers/adapters. It deliberately does not contain model-specific
/// animation names, so a GLB can map its clips without duplicating state logic.
class UnifiedAnimationController extends ChangeNotifier {
  CharacterAnimationState _currentState = CharacterAnimationState.idle;
  CharacterAnimationState? _previousState;
  double _transitionProgress = 1.0;

  CharacterAnimationState get currentState => _currentState;
  CharacterAnimationState? get previousState => _previousState;
  double get transitionProgress => _transitionProgress;
  bool get isTransitioning => _transitionProgress < 1.0;

  void transitionTo(
    CharacterAnimationState newState, {
    double duration = 0.2,
  }) {
    if (_currentState == newState) return;

    _previousState = _currentState;
    _currentState = newState;
    _transitionProgress = duration <= 0 ? 1.0 : 0.0;
    notifyListeners();
  }

  void updateFromInput(
    Offset velocity, {
    required bool isGrounded,
    double deltaTime = 0,
  }) {
    final next = !isGrounded
        ? CharacterAnimationState.fall
        : velocity.distance > 2.5
            ? CharacterAnimationState.run
            : velocity.distance > 0.1
                ? CharacterAnimationState.walk
                : CharacterAnimationState.idle;

    transitionTo(next);

    if (deltaTime > 0 && _transitionProgress < 1.0) {
      _transitionProgress =
          (_transitionProgress + deltaTime / 0.2).clamp(0.0, 1.0).toDouble();
      if (_transitionProgress >= 1.0) {
        _previousState = null;
      }
      notifyListeners();
    }
  }

  void update(double deltaTime, {double duration = 0.2}) {
    if (deltaTime <= 0 || _transitionProgress >= 1.0) return;
    final safeDuration = duration <= 0 ? 0.2 : duration;
    _transitionProgress =
        (_transitionProgress + deltaTime / safeDuration).clamp(0.0, 1.0).toDouble();
    if (_transitionProgress >= 1.0) {
      _previousState = null;
    }
    notifyListeners();
  }

  void reset() {
    _currentState = CharacterAnimationState.idle;
    _previousState = null;
    _transitionProgress = 1.0;
    notifyListeners();
  }
}
