import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gta6hub/engine/core/advanced_curves.dart';
import "package:gta6hub/engine/core/advanced_curves.dart";

class MotionState {
  double breathAmplitude;
  double breathRate;
  double tremorIntensity;
  double tremorFrequency;
  double erectionAngle;
  double erectionThrob;
  double hipSway;
  double spineCurve;
  double shoulderShrug;
  double heartbeatStrength;
  double orgasmPhase;

  MotionState({
    this.breathAmplitude = 0.3,
    this.breathRate = 0.4,
    this.tremorIntensity = 0.0,
    this.tremorFrequency = 8.0,
    this.erectionAngle = -0.3,
    this.erectionThrob = 0.0,
    this.hipSway = 0.0,
    this.spineCurve = 0.0,
    this.shoulderShrug = 0.0,
    this.heartbeatStrength = 0.2,
    this.orgasmPhase = 0.0,
  });
}

class BodyMotionEngine {
  MotionState _state = MotionState();
  double _time = 0;
  double _arousal = 0;
  double _orgasmTime = 0;
  bool _isInOrgasm = false;
  double _orgasmDuration = 3.0;
  double _prevArousal = 0;
  double _arousalVelocity = 0;

  void update(double deltaTime, double arousal) {
    _time += deltaTime;
    _prevArousal = _arousal;
    _arousal = arousal.clamp(0.0, 1.0);
    _arousalVelocity = (_arousal - _prevArousal) / deltaTime.clamp(0.001, 1.0);

    // اكتشاف الدخول في الذروة
    if (_arousal >= 0.95 && !_isInOrgasm) {
      _isInOrgasm = true;
      _orgasmTime = 0;
    }
    if (_isInOrgasm) {
      _orgasmTime += deltaTime;
      if (_orgasmTime > _orgasmDuration || _arousal < 0.3) {
        _isInOrgasm = false;
        _orgasmTime = 0;
      }
    }

    // === التنفس العضوي ===
    _state.breathRate = 0.3 + _arousal * 1.5;
    _state.breathAmplitude = 0.12 + _arousal * 0.45;
    if (_isInOrgasm) {
      _state.breathRate = 2.5;
      _state.breathAmplitude = 0.6;
    }

    // === الارتعاش العصبي ===
    _state.tremorIntensity = AdvancedCurves.smoothstep(0.5, 0.95, _arousal) * 0.5;
    _state.tremorFrequency = 6.0 + _arousal * 18.0;
    if (_isInOrgasm) {
      _state.tremorIntensity = AdvancedCurves.orgasmCurve(_orgasmTime, _orgasmDuration) * 0.8;
    }

    // === نبض القلب ===
    _state.heartbeatStrength = 0.1 + _arousal * 0.8;
    if (_isInOrgasm) {
      _state.heartbeatStrength = 1.0;
    }

    // === الانتصاب (EaseOutElastic) ===
    final erectionTarget = AdvancedCurves.erectionCurve(_arousal);
    _state.erectionAngle = -pi * 0.4 * erectionTarget;
    _state.erectionThrob = _isInOrgasm
        ? AdvancedCurves.orgasmCurve(_orgasmTime, _orgasmDuration) * 0.3
        : sin(_time * 6.0) * 0.05 * _arousal;

    // === تمايل الحوض ===
    _state.hipSway = AdvancedCurves.swayCurve(_time, 1.2, _arousal) * 0.04;

    // === العمود الفقري ===
    _state.spineCurve = AdvancedCurves.swayCurve(_time, 0.6, _arousal) * 0.025;

    // === هز الكتفين ===
    _state.shoulderShrug = AdvancedCurves.breathCurve(_time, _state.breathRate) * 0.02 * _arousal;
  }

  double get breathOffset {
    if (_isInOrgasm) {
      return AdvancedCurves.orgasmCurve(_orgasmTime, _orgasmDuration) * _state.breathAmplitude;
    }
    return AdvancedCurves.breathCurve(_time, _state.breathRate) * _state.breathAmplitude;
  }

  double get tremorOffset => AdvancedCurves.tremorCurve(_time, _state.tremorFrequency, _state.tremorIntensity);

  double get heartbeatPulse => AdvancedCurves.heartbeatCurve(_time, 60 + _arousal * 100);

  double get erectionAngle => _state.erectionAngle;

  double get erectionPulse {
    final base = 1.0 + _state.erectionThrob;
    final hb = heartbeatPulse * 0.05 * _arousal;
    return base + hb;
  }

  double get hipSway => _state.hipSway;
  double get spineCurve => _state.spineCurve;
  double get shoulderShrug => _state.shoulderShrug;
  double get arousal => _arousal;
  bool get isInOrgasm => _isInOrgasm;
  double get orgasmProgress => _isInOrgasm ? _orgasmTime / _orgasmDuration : 0;

  void reset() {
    _state = MotionState();
    _time = 0;
    _arousal = 0;
    _isInOrgasm = false;
    _orgasmTime = 0;
  }
}
