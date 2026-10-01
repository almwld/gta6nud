import 'package:flutter/foundation.dart';

/// Neutral runtime state consumed by character presentation systems.
class CharacterRuntimeState extends ChangeNotifier {
  double _activityLevel = 0.0;

  double get activityLevel => _activityLevel;

  void setActivityLevel(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    if ((next - _activityLevel).abs() < 0.0001) return;
    _activityLevel = next;
    notifyListeners();
  }

  void reset() {
    setActivityLevel(0.0);
  }
}
