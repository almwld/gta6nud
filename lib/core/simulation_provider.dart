import 'package:flutter/material.dart';

enum SimulationState { idle, active, peak, recovering }

class SimulationProvider extends ChangeNotifier {
  double _arousal = 0;
  double _thrustSpeed = 0;
  double _thrustDepth = 0;
  String _currentPosition = 'missionary';
  bool _autoMode = false;
  SimulationState _currentState = SimulationState.idle;
  double _time = 0;

  double get arousal => _arousal;
  double get thrustSpeed => _thrustSpeed;
  double get thrustDepth => _thrustDepth;
  String get currentPosition => _currentPosition;
  bool get autoMode => _autoMode;
  SimulationState get currentState => _currentState;

  void update(double delta) {
    _time += delta;
    if (_autoMode) {
      _thrustSpeed = 30 + 40 * (_time % 5) / 5;
      _thrustDepth = 50 + 30 * (_time % 3) / 3;
    }
    _arousal = (_arousal + _thrustSpeed * delta * 0.01).clamp(0.0, 100.0);
    if (_arousal > 90) {
      _currentState = SimulationState.peak;
    } else if (_arousal > 30) {
      _currentState = SimulationState.active;
    } else if (_arousal > 5) {
      _currentState = SimulationState.recovering;
    } else {
      _currentState = SimulationState.idle;
    }
    notifyListeners();
  }

  void setSpeedDirect(double speed) => _thrustSpeed = speed.clamp(0, 100);
  void setDepthDirect(double depth) => _thrustDepth = depth.clamp(0, 100);
  void changePosition(String pos) => _currentPosition = pos;
  void setAutoMode(bool mode) => _autoMode = mode;
}
