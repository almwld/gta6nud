import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Neutral character animation states shared by the character presentation layer.
enum CharacterAnimationState {
  idle,
  walk,
  run,
  ability,
  /// Legacy alias retained for callers that used the original name.
  abilityUse,
  hit,
  fall,
  jump,
  dance,
}

/// Single state machine with normalized two-state crossfade weights.
class UnifiedAnimationController extends ChangeNotifier {
  static const double defaultTransitionDuration = 0.2;

  CharacterAnimationState _currentState = CharacterAnimationState.idle;
  CharacterAnimationState? _previousState;
  double _transitionProgress = 1.0;
  double _transitionDuration = defaultTransitionDuration;

  CharacterAnimationState get currentState => _currentState;
  CharacterAnimationState? get previousState => _previousState;
  double get transitionProgress => _transitionProgress;
  bool get isTransitioning => _transitionProgress < 1.0;

  /// Blend-tree weights for the active crossfade. The values always sum to one.
  Map<CharacterAnimationState, double> get blendWeights {
    if (_previousState == null || !isTransitioning) {
      return <CharacterAnimationState, double>{_currentState: 1.0};
    }
    return <CharacterAnimationState, double>{
      _previousState!: 1.0 - _transitionProgress,
      _currentState: _transitionProgress,
    };
  }

  void transitionTo(
    CharacterAnimationState newState, {
    double duration = defaultTransitionDuration,
  }) {
    if (_currentState == newState) return;
    if (!duration.isFinite) {
      throw ArgumentError.value(duration, 'duration', 'Must be finite.');
    }
    _previousState = _currentState;
    _currentState = newState;
    _transitionDuration = duration <= 0 ? 0 : duration;
    _transitionProgress = _transitionDuration == 0 ? 1.0 : 0.0;
    if (_transitionProgress >= 1) _previousState = null;
    notifyListeners();
  }

  void updateFromInput(
    Offset velocity, {
    required bool isGrounded,
    bool isAbilityActive = false,
    bool wasHit = false,
    double deltaTime = 0,
  }) {
    final next = wasHit
        ? CharacterAnimationState.hit
        : isAbilityActive
            ? CharacterAnimationState.ability
            : !isGrounded && velocity.dy < 0
                ? CharacterAnimationState.jump
                : !isGrounded
                    ? CharacterAnimationState.fall
                    : velocity.distance > 2.5
                        ? CharacterAnimationState.run
                        : velocity.distance > 0.1
                            ? CharacterAnimationState.walk
                            : CharacterAnimationState.idle;

    transitionTo(next);
    if (deltaTime > 0) update(deltaTime);
  }

  void update(double deltaTime, {double? duration}) {
    if (!deltaTime.isFinite || deltaTime <= 0 || !isTransitioning) return;
    final safeDuration = duration ?? _transitionDuration;
    if (!safeDuration.isFinite || safeDuration <= 0) {
      _transitionProgress = 1.0;
    } else {
      _transitionProgress = (_transitionProgress + deltaTime / safeDuration)
          .clamp(0.0, 1.0)
          .toDouble();
    }
    if (_transitionProgress >= 1.0) _previousState = null;
    notifyListeners();
  }

  void reset() {
    _currentState = CharacterAnimationState.idle;
    _previousState = null;
    _transitionProgress = 1.0;
    _transitionDuration = defaultTransitionDuration;
    notifyListeners();
  }
}
