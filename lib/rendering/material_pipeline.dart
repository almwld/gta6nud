import 'package:flutter/foundation.dart';

@immutable
class CharacterMaterialState {
  const CharacterMaterialState({
    required this.activity,
    required this.temperature,
    required this.sweat,
    required this.warmth,
  });

  final double activity;
  final double temperature;
  final double sweat;
  final double warmth;
}

/// Computes one consistent material/effect state for a character.
///
/// The renderer can consume this state regardless of whether the underlying
/// model is a 2D sprite or a GLB material implementation.
class MaterialPipeline {
  const MaterialPipeline();

  CharacterMaterialState updateCharacterMaterial({
    required double activityLevel,
    double temperature = 0.5,
  }) {
    final activity = activityLevel.clamp(0.0, 1.0).toDouble();
    final temp = temperature.clamp(0.0, 1.0).toDouble();

    return CharacterMaterialState(
      activity: activity,
      temperature: temp,
      sweat: (activity * (0.6 + temp * 0.6)).clamp(0.0, 1.0).toDouble(),
      warmth: ((activity * 0.65) + (temp * 0.35)).clamp(0.0, 1.0).toDouble(),
    );
  }
}
