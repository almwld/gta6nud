import 'dart:math';
import 'package:flutter/material.dart';

enum BodyAnimationType { idle, breathing, thrusting, receiving, climaxing, recovering }

class AnimationKeyframe {
  final double time;
  final double hipAngle;
  final double spineCurve;
  final double shoulderTilt;
  final double headTilt;
  final double mouthOpen;
  final double eyeSquint;

  AnimationKeyframe({
    required this.time,
    this.hipAngle = 0,
    this.spineCurve = 0,
    this.shoulderTilt = 0,
    this.headTilt = 0,
    this.mouthOpen = 0,
    this.eyeSquint = 0,
  });
}

class AnimationSequence {
  final BodyAnimationType type;
  final List<AnimationKeyframe> keyframes;
  final double duration;
  final bool loops;

  AnimationSequence({
    required this.type,
    required this.keyframes,
    required this.duration,
    this.loops = true,
  });
}

class BodyAnimationController extends ChangeNotifier {
  BodyAnimationType _currentType = BodyAnimationType.idle;
  AnimationSequence? _currentSequence;
  double _currentTime = 0;
  double _speedMultiplier = 1.0;
  bool _isPlaying = false;
  double _blendFactor = 0;

  double _hipAngle = 0;
  double _spineCurve = 0;
  double _shoulderTilt = 0;
  double _headTilt = 0;
  double _mouthOpen = 0;
  double _eyeSquint = 0;

  final Map<BodyAnimationType, AnimationSequence> _sequences = {};

  BodyAnimationController() {
    _buildDefaultSequences();
  }

  void _buildDefaultSequences() {
    _sequences[BodyAnimationType.breathing] = AnimationSequence(
      type: BodyAnimationType.breathing,
      duration: 4.0,
      loops: true,
      keyframes: [
        AnimationKeyframe(time: 0, spineCurve: 0, shoulderTilt: 0),
        AnimationKeyframe(time: 2, spineCurve: 0.1, shoulderTilt: 0.05),
        AnimationKeyframe(time: 4, spineCurve: 0, shoulderTilt: 0),
      ],
    );

    _sequences[BodyAnimationType.thrusting] = AnimationSequence(
      type: BodyAnimationType.thrusting,
      duration: 0.5,
      loops: true,
      keyframes: [
        AnimationKeyframe(time: 0, hipAngle: -0.2, spineCurve: 0.1),
        AnimationKeyframe(time: 0.25, hipAngle: 0.3, spineCurve: -0.2),
        AnimationKeyframe(time: 0.5, hipAngle: -0.2, spineCurve: 0.1),
      ],
    );

    _sequences[BodyAnimationType.receiving] = AnimationSequence(
      type: BodyAnimationType.receiving,
      duration: 0.5,
      loops: true,
      keyframes: [
        AnimationKeyframe(time: 0, spineCurve: -0.1, headTilt: 0, mouthOpen: 0.1),
        AnimationKeyframe(time: 0.25, spineCurve: 0.2, headTilt: 0.1, mouthOpen: 0.4),
        AnimationKeyframe(time: 0.5, spineCurve: -0.1, headTilt: 0, mouthOpen: 0.1),
      ],
    );

    _sequences[BodyAnimationType.climaxing] = AnimationSequence(
      type: BodyAnimationType.climaxing,
      duration: 3.0,
      loops: false,
      keyframes: [
        AnimationKeyframe(time: 0, spineCurve: 0, mouthOpen: 0.1, eyeSquint: 0),
        AnimationKeyframe(time: 0.5, spineCurve: 0.4, mouthOpen: 0.8, eyeSquint: 0.7),
        AnimationKeyframe(time: 1.5, spineCurve: 0.3, mouthOpen: 0.6, eyeSquint: 0.5),
        AnimationKeyframe(time: 2.5, spineCurve: 0.1, mouthOpen: 0.3, eyeSquint: 0.2),
        AnimationKeyframe(time: 3.0, spineCurve: 0, mouthOpen: 0.1, eyeSquint: 0),
      ],
    );

    _sequences[BodyAnimationType.recovering] = AnimationSequence(
      type: BodyAnimationType.recovering,
      duration: 5.0,
      loops: false,
      keyframes: [
        AnimationKeyframe(time: 0, spineCurve: 0.1, shoulderTilt: 0.05, headTilt: 0.1, mouthOpen: 0.2, eyeSquint: 0.3),
        AnimationKeyframe(time: 3, spineCurve: 0.05, shoulderTilt: 0.02, headTilt: 0.05, mouthOpen: 0.1, eyeSquint: 0.1),
        AnimationKeyframe(time: 5, spineCurve: 0, shoulderTilt: 0, headTilt: 0, mouthOpen: 0, eyeSquint: 0),
      ],
    );
  }

  void play(BodyAnimationType type, {double speed = 1.0}) {
    if (_currentType == type && _isPlaying) return;
    _currentType = type;
    _currentSequence = _sequences[type];
    _currentTime = 0;
    _speedMultiplier = speed;
    _isPlaying = true;
    _blendFactor = 0;
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    notifyListeners();
  }

  void idle() => play(BodyAnimationType.idle);

  void update(double deltaTime) {
    if (!_isPlaying || _currentSequence == null) return;
    _currentTime += deltaTime * _speedMultiplier;
    if (_currentTime >= _currentSequence!.duration) {
      if (_currentSequence!.loops) {
        _currentTime = 0;
      } else {
        _isPlaying = false;
        _currentType = BodyAnimationType.idle;
        notifyListeners();
        return;
      }
    }
    _blendFactor = (_blendFactor + deltaTime * 5).clamp(0.0, 1.0);
    _interpolateKeyframes();
    notifyListeners();
  }

  void _interpolateKeyframes() {
    if (_currentSequence == null || _currentSequence!.keyframes.isEmpty) return;
    final keyframes = _currentSequence!.keyframes;
    if (keyframes.length == 1) { _applyKeyframe(keyframes.first); return; }
    AnimationKeyframe? prev, next;
    for (int i = 0; i < keyframes.length - 1; i++) {
      if (_currentTime >= keyframes[i].time && _currentTime <= keyframes[i + 1].time) {
        prev = keyframes[i];
        next = keyframes[i + 1];
        break;
      }
    }
    if (prev == null || next == null) { _applyKeyframe(keyframes.last); return; }
    final segmentDuration = next.time - prev.time;
    final t = segmentDuration > 0 ? (_currentTime - prev.time) / segmentDuration : 0;
    _hipAngle = _lerp(prev.hipAngle, next.hipAngle, t);
    _spineCurve = _lerp(prev.spineCurve, next.spineCurve, t);
    _shoulderTilt = _lerp(prev.shoulderTilt, next.shoulderTilt, t);
    _headTilt = _lerp(prev.headTilt, next.headTilt, t);
    _mouthOpen = _lerp(prev.mouthOpen, next.mouthOpen, t);
    _eyeSquint = _lerp(prev.eyeSquint, next.eyeSquint, t);
  }

  void _applyKeyframe(AnimationKeyframe kf) {
    _hipAngle = kf.hipAngle;
    _spineCurve = kf.spineCurve;
    _shoulderTilt = kf.shoulderTilt;
    _headTilt = kf.headTilt;
    _mouthOpen = kf.mouthOpen;
    _eyeSquint = kf.eyeSquint;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  BodyAnimationType get currentType => _currentType;
  bool get isPlaying => _isPlaying;
  double get hipAngle => _hipAngle * _blendFactor;
  double get spineCurve => _spineCurve * _blendFactor;
  double get shoulderTilt => _shoulderTilt * _blendFactor;
  double get headTilt => _headTilt * _blendFactor;
  double get mouthOpen => _mouthOpen * _blendFactor;
  double get eyeSquint => _eyeSquint * _blendFactor;
  double get currentTime => _currentTime;
  double get speedMultiplier => _speedMultiplier;

  void setSpeed(double speed) {
    _speedMultiplier = speed.clamp(0.1, 5.0);
    notifyListeners();
  }

  void addCustomSequence(AnimationSequence sequence) {
    _sequences[sequence.type] = sequence;
  }
}
