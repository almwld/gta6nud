import 'package:flutter/foundation.dart';

import '../core/consent_system.dart';
import '../core/emotional_arc.dart';

enum InteractionType { touch, kiss, embrace, gaze, whisper, withdraw }

enum InteractionIntensity { gentle, medium }

enum InteractionTarget { face, eyes, hand, shoulder, ear, personalSpace }

enum InteractionShot { detail, closeUp, medium, wide, overShoulder }

/// A declarative, non-explicit interaction request.
@immutable
class IntimateInteraction {
  const IntimateInteraction({
    required this.type,
    required this.target,
    required this.duration,
    this.intensity = InteractionIntensity.gentle,
    this.dialogue,
    this.shotHint,
  });

  final InteractionType type;
  final InteractionTarget target;
  final Duration duration;
  final InteractionIntensity intensity;
  final String? dialogue;
  final InteractionShot? shotHint;
}

/// Host applications map this command to their real animation, camera and
/// dialogue APIs. This package deliberately does not pretend those APIs exist.
@immutable
class InteractionCommand {
  const InteractionCommand({
    required this.type,
    required this.target,
    required this.intensity,
    required this.duration,
    required this.shotHint,
    this.dialogue,
  });

  final InteractionType type;
  final InteractionTarget target;
  final InteractionIntensity intensity;
  final Duration duration;
  final InteractionShot shotHint;
  final String? dialogue;
}

typedef InteractionDispatcher = Future<void> Function(
  InteractionCommand command,
);

@immutable
class InteractionResult {
  const InteractionResult({
    required this.success,
    this.connectionDelta = 0,
    this.trustDelta = 0,
    this.comfortDelta = 0,
    this.reaction,
    this.nextSuggested,
  });

  final bool success;
  final double connectionDelta;
  final double trustDelta;
  final double comfortDelta;
  final String? reaction;
  final InteractionType? nextSuggested;
}

/// Coordinates consent, narrative state and host-dispatched scene actions.
///
/// It contains no explicit sexual actions and never invents character/camera
/// methods. The app supplies [dispatch] to connect real supported APIs.
class IntimateInteractionSystem {
  IntimateInteractionSystem({
    required this.consent,
    required this.arc,
    required this.dispatch,
  });

  final ConsentSystem consent;
  final EmotionalArc arc;
  final InteractionDispatcher dispatch;

  double _connectionLevel = 0;
  double _trustLevel = 0.5;
  double _comfortLevel = 0.7;
  final List<InteractionType> _history = <InteractionType>[];

  Future<InteractionResult> perform(IntimateInteraction interaction) async {
    if (interaction.duration <= Duration.zero) {
      return const InteractionResult(
        success: false,
        reaction: 'Duration must be greater than zero.',
      );
    }

    final command = InteractionCommand(
      type: interaction.type,
      target: interaction.target,
      intensity: interaction.intensity,
      duration: _scaledDuration(interaction),
      shotHint: interaction.shotHint ?? _defaultShot(interaction.type),
      dialogue: interaction.dialogue,
    );

    if (interaction.type == InteractionType.withdraw) {
      // Consent is revoked before any host callback can run.
      await consent.withdraw();
      try {
        await dispatch(command);
      } catch (_) {
        return const InteractionResult(
          success: false,
          reaction: 'Consent withdrawn; host stop handler failed.',
        );
      }
      _history.add(InteractionType.withdraw);
      return const InteractionResult(
        success: true,
        connectionDelta: 0,
        trustDelta: 0.05,
        comfortDelta: 0.1,
        reaction: 'Space and boundaries respected.',
        nextSuggested: InteractionType.gaze,
      );
    }

    final action = _consentActionFor(interaction.type);
    if (action == null || !await consent.request(action)) {
      return const InteractionResult(
        success: false,
        reaction: 'Consent not granted; no interaction was dispatched.',
      );
    }

    try {
      await dispatch(command);
    } catch (_) {
      // Do not update emotional metrics or history if the host action failed.
      return const InteractionResult(
        success: false,
        reaction: 'The host could not perform the requested interaction.',
      );
    }

    final deltas = _deltasFor(interaction.type);
    _connectionLevel = (_connectionLevel + deltas.$1).clamp(0.0, 1.0).toDouble();
    _trustLevel = (_trustLevel + deltas.$2).clamp(0.0, 1.0).toDouble();
    _comfortLevel = (_comfortLevel + deltas.$3).clamp(0.0, 1.0).toDouble();
    _history.add(interaction.type);

    return InteractionResult(
      success: true,
      connectionDelta: deltas.$1,
      trustDelta: deltas.$2,
      comfortDelta: deltas.$3,
      reaction: _reactionFor(interaction.type),
      nextSuggested: _nextFor(interaction.type),
    );
  }

  Duration _scaledDuration(IntimateInteraction interaction) {
    final factor = interaction.intensity == InteractionIntensity.gentle
        ? 1.25
        : 1.0;
    return Duration(
      microseconds: (interaction.duration.inMicroseconds * factor).round(),
    );
  }

  ConsentAction? _consentActionFor(InteractionType type) {
    switch (type) {
      case InteractionType.touch:
        return ConsentAction.gentleTouch;
      case InteractionType.kiss:
        return ConsentAction.kiss;
      case InteractionType.embrace:
        return ConsentAction.embrace;
      case InteractionType.gaze:
        return ConsentAction.gaze;
      case InteractionType.whisper:
        return ConsentAction.whisper;
      case InteractionType.withdraw:
        return null;
    }
  }

  InteractionShot _defaultShot(InteractionType type) {
    switch (type) {
      case InteractionType.touch:
        return InteractionShot.detail;
      case InteractionType.kiss:
        return InteractionShot.closeUp;
      case InteractionType.embrace:
        return InteractionShot.wide;
      case InteractionType.gaze:
        return InteractionShot.closeUp;
      case InteractionType.whisper:
        return InteractionShot.overShoulder;
      case InteractionType.withdraw:
        return InteractionShot.medium;
    }
  }

  (double, double, double) _deltasFor(InteractionType type) {
    switch (type) {
      case InteractionType.touch:
        return (0.05, 0.03, 0.02);
      case InteractionType.kiss:
        return (0.08, 0.04, 0.03);
      case InteractionType.embrace:
        return (0.06, 0.05, 0.08);
      case InteractionType.gaze:
        return (0.04, 0.04, 0.02);
      case InteractionType.whisper:
        return (0.05, 0.04, 0.03);
      case InteractionType.withdraw:
        return (0, 0, 0);
    }
  }

  String _reactionFor(InteractionType type) {
    switch (type) {
      case InteractionType.touch:
        return 'A gentle moment.';
      case InteractionType.kiss:
        return 'A shared romantic moment.';
      case InteractionType.embrace:
        return 'Warmth and reassurance.';
      case InteractionType.gaze:
        return 'A quiet exchange of looks.';
      case InteractionType.whisper:
        return 'A quiet, personal conversation.';
      case InteractionType.withdraw:
        return 'Space and boundaries respected.';
    }
  }

  InteractionType? _nextFor(InteractionType type) {
    switch (type) {
      case InteractionType.touch:
        return InteractionType.gaze;
      case InteractionType.kiss:
        return InteractionType.embrace;
      case InteractionType.embrace:
        return InteractionType.whisper;
      case InteractionType.gaze:
        return InteractionType.whisper;
      case InteractionType.whisper:
        return InteractionType.gaze;
      case InteractionType.withdraw:
        return null;
    }
  }

  double get connectionLevel => _connectionLevel;
  double get trustLevel => _trustLevel;
  double get comfortLevel => _comfortLevel;
  List<InteractionType> get history =>
      List<InteractionType>.unmodifiable(_history);
}
