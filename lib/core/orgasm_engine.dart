import 'dart:math';

enum OrgasmPhase { resting, building, plateau, approaching, climax, resolving }

class OrgasmState {
  final OrgasmPhase phase;
  final double intensity;
  final int waveCount;
  final double duration;
  OrgasmState({this.phase = OrgasmPhase.resting, this.intensity = 0.0, this.waveCount = 0, this.duration = 0.0});
}

class OrgasmEngine {
  OrgasmPhase _phase = OrgasmPhase.resting;
  double _excitement = 0.0;
  double _orgasmTimer = 0.0;
  int _waveCount = 0;
  double _peakIntensity = 0.0;

  static const double _excitementRiseRate = 0.3;
  static const double _excitementDecayRate = 0.5;
  static const double _orgasmThreshold = 0.95;
  static const double _plateauThreshold = 0.7;

  OrgasmState update(double pleasureInput, double deltaTime) {
    switch (_phase) {
      case OrgasmPhase.resting:
      case OrgasmPhase.building:
        _excitement += pleasureInput * _excitementRiseRate * deltaTime;
        _excitement = _excitement.clamp(0.0, 1.0);
        if (_excitement > _plateauThreshold && _excitement < _orgasmThreshold) {
          _phase = OrgasmPhase.plateau;
        } else if (_excitement >= _orgasmThreshold) {
          _triggerOrgasm();
        } else if (_excitement > 0.1) {
          _phase = OrgasmPhase.building;
        } else {
          _phase = OrgasmPhase.resting;
        }
        break;
      case OrgasmPhase.plateau:
        _excitement += pleasureInput * _excitementRiseRate * 0.3 * deltaTime;
        _excitement -= _excitementDecayRate * 0.1 * deltaTime;
        if (_excitement >= _orgasmThreshold) {
          _triggerOrgasm();
        } else if (_excitement < _plateauThreshold) {
          _phase = OrgasmPhase.building;
        }
        break;
      case OrgasmPhase.approaching:
        _excitement += 0.5 * deltaTime;
        if (_excitement >= 1.0) {
          _phase = OrgasmPhase.climax;
          _excitement = 1.0;
          _waveCount = 3 + Random().nextInt(6);
          _orgasmTimer = 0;
        }
        break;
      case OrgasmPhase.climax:
        _orgasmTimer += deltaTime;
        final waveDuration = 0.8;
        final currentWave = (_orgasmTimer / waveDuration).floor();
        if (currentWave >= _waveCount) {
          _phase = OrgasmPhase.resolving;
          _orgasmTimer = 0;
        } else {
          _peakIntensity = 1.0 - (currentWave / _waveCount) * 0.5;
          final wavePosition = (_orgasmTimer % waveDuration) / waveDuration;
          _peakIntensity *= sin(wavePosition * pi);
        }
        break;
      case OrgasmPhase.resolving:
        _excitement -= _excitementDecayRate * deltaTime;
        _peakIntensity *= 0.9;
        if (_excitement <= 0.05) {
          _phase = OrgasmPhase.resting;
          _excitement = 0.0;
          _peakIntensity = 0.0;
          _waveCount = 0;
        }
        break;
    }
    return OrgasmState(
      phase: _phase,
      intensity: _phase == OrgasmPhase.climax ? _peakIntensity : _excitement,
      waveCount: _waveCount,
      duration: _orgasmTimer,
    );
  }

  void _triggerOrgasm() {
    _phase = OrgasmPhase.approaching;
    _excitement = _orgasmThreshold;
  }

  bool get isInOrgasm => _phase == OrgasmPhase.climax;
  bool get isApproaching => _phase == OrgasmPhase.approaching;
  OrgasmPhase get phase => _phase;
  double get excitement => _excitement;
}
