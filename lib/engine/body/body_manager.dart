import 'package:flutter/material.dart';
import 'package:gta6hub/engine/body/live_body_renderer.dart';
import 'package:gta6hub/engine/body/body_motion_engine.dart';

class BodyManager extends ChangeNotifier {
  final LiveBodyRenderer _renderer = LiveBodyRenderer();
  double _arousal = 0;
  double _pleasure = 0;
  bool _isInitialized = true;
  Offset? _lastTouch;

  BodyManager() {
    _isInitialized = true;
  }

  void update(double deltaTime) {
    _renderer.update(deltaTime, _arousal);
    notifyListeners();
  }

  void render(Canvas canvas, Size screenSize) {
    _renderer.render(canvas, screenSize);
  }

  void setArousal(double value) {
    _arousal = value.clamp(0.0, 1.0);
  }

  void setPleasure(double value) {
    _pleasure = value.clamp(0.0, 1.0);
  }

  void touchAt(Offset globalPosition, Size screenSize) {
    _renderer.touchAt(globalPosition, screenSize);
    _lastTouch = globalPosition;
  }

  void startThrusting() {}
  void startReceiving() {}
  void triggerClimax() => setArousal(1.0);
  void recover() => setArousal(0.0);
  void reset() => setArousal(0.0);

  bool get isInitialized => _isInitialized;
  double get arousal => _arousal;
  double get pleasure => _pleasure;
  LiveBodyRenderer get renderer => _renderer;

  @override
  void dispose() {
    super.dispose();
  }
}
