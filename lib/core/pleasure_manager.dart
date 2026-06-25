import 'package:flutter/material.dart';
import 'package:gta6hub/engine/physics/penetration_engine.dart';
import 'package:gta6hub/core/orgasm_engine.dart';
import 'package:gta6hub/engine/audio/spatial_audio_engine.dart';
import 'package:gta6hub/engine/fluids/cum_engine.dart';

class PleasureManager extends ChangeNotifier {
  final PenetrationEngine _penetration = PenetrationEngine();
  final OrgasmEngine _orgasm = OrgasmEngine();
  final CumEngine _cum = CumEngine();
  SpatialAudioEngine? _audio;

  double _thrustSpeed = 0;
  double _thrustDepth = 0;
  double _receiverPleasure = 0;
  double _giverPleasure = 0;
  OrgasmState _orgasmState = OrgasmState();
  bool _hasClimaxed = false;

  void setAudioEngine(SpatialAudioEngine audio) => _audio = audio;

  void update(double deltaTime, {Size? screenSize}) {
    final frame = _penetration.calculateFrame(
      thrustDepth: _thrustDepth / 100.0,
      thrustSpeed: _thrustSpeed,
      deltaTime: deltaTime,
    );
    _receiverPleasure = frame.receiverPleasure;
    _giverPleasure = frame.giverPleasure;
    _orgasmState = _orgasm.update(_receiverPleasure, deltaTime);

    if (_audio != null) {
      _audio!.updateArousal(_orgasm.excitement);
      if (frame.isFullyInserted && frame.speed > 10) {
        _audio!.playMoan(volume: frame.receiverPleasure, speed: frame.speed);
      }
      if (_orgasm.isInOrgasm && !_hasClimaxed) {
        _audio!.playScream();
        _hasClimaxed = true;
      }
      if (!_orgasm.isInOrgasm) _hasClimaxed = false;
    }

    if (_orgasm.isInOrgasm && _hasClimaxed) {
      if (screenSize != null && _orgasmState.waveCount > 0) {
        final center = Offset(screenSize.width / 2, screenSize.height / 2);
        final direction = const Offset(0, -1);
        _cum.emitBurst(
          origin: center,
          direction: direction,
          force: _penetration.penetrator.cumForce,
          volume: _penetration.penetrator.cumVolume,
        );
      }
    }
    if (screenSize != null) _cum.update(deltaTime, screenSize);
    notifyListeners();
  }

  void setThrustSpeed(double speed) => _thrustSpeed = speed;
  void setThrustDepth(double depth) => _thrustDepth = depth;

  double get receiverPleasure => _receiverPleasure;
  double get giverPleasure => _giverPleasure;
  OrgasmEngine get orgasm => _orgasm;
  CumEngine get cum => _cum;
  PenetrationEngine get penetration => _penetration;
}
