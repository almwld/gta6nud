import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/core/consent_system.dart';
import 'package:gta6hub/core/emotional_arc.dart';
import 'package:gta6hub/interaction/intimate_interaction_system.dart';

void main() {
  IntimateInteraction sample({
    InteractionType type = InteractionType.gaze,
    Duration duration = const Duration(seconds: 1),
    InteractionIntensity intensity = InteractionIntensity.gentle,
  }) {
    return IntimateInteraction(
      type: type,
      target: InteractionTarget.eyes,
      duration: duration,
      intensity: intensity,
    );
  }

  test('does not dispatch without affirmative consent', () async {
    var dispatchCount = 0;
    final system = IntimateInteractionSystem(
      consent: ConsentSystem(prompt: (_) async => ConsentResponse.notNow),
      arc: EmotionalArc(),
      dispatch: (_) async => dispatchCount++,
    );

    final result = await system.perform(sample());
    expect(result.success, isFalse);
    expect(dispatchCount, 0);
    expect(system.history, isEmpty);
    expect(system.connectionLevel, 0);
  });

  test('dispatches approved action and scales gentle duration', () async {
    InteractionCommand? received;
    final system = IntimateInteractionSystem(
      consent: ConsentSystem(prompt: (_) async => ConsentResponse.yes),
      arc: EmotionalArc(),
      dispatch: (command) async => received = command,
    );

    final result = await system.perform(sample(type: InteractionType.gaze));

    expect(result.success, isTrue);
    expect(received, isNotNull);
    expect(received!.duration, const Duration(milliseconds: 1250));
    expect(received!.shotHint, InteractionShot.closeUp);
    expect(system.history, <InteractionType>[InteractionType.gaze]);
    expect(system.connectionLevel, greaterThan(0));
  });

  test('withdrawal revokes consent before dispatching stop command', () async {
    final consent = ConsentSystem(
      prompt: (_) async => ConsentResponse.yes,
    );
    expect(await consent.request(ConsentAction.gaze), isTrue);

    var withdrawnBeforeDispatch = false;
    final system = IntimateInteractionSystem(
      consent: consent,
      arc: EmotionalArc(),
      dispatch: (_) async {
        withdrawnBeforeDispatch = consent.isWithdrawn;
      },
    );

    final result = await system.perform(sample(
      type: InteractionType.withdraw,
      duration: const Duration(milliseconds: 1),
    ));

    expect(result.success, isTrue);
    expect(withdrawnBeforeDispatch, isTrue);
    expect(consent.isGranted(ConsentAction.gaze), isFalse);
    expect(system.history, <InteractionType>[InteractionType.withdraw]);
  });

  test('failed host dispatch does not change metrics or history', () async {
    final system = IntimateInteractionSystem(
      consent: ConsentSystem(prompt: (_) async => ConsentResponse.yes),
      arc: EmotionalArc(),
      dispatch: (_) async => throw StateError('animation adapter failed'),
    );

    final result = await system.perform(sample());
    expect(result.success, isFalse);
    expect(system.history, isEmpty);
    expect(system.connectionLevel, 0);
    expect(system.trustLevel, 0.5);
    expect(system.comfortLevel, 0.7);
  });

  test('rejects zero duration without asking for consent', () async {
    var prompted = false;
    final system = IntimateInteractionSystem(
      consent: ConsentSystem(prompt: (_) async {
        prompted = true;
        return ConsentResponse.yes;
      }),
      arc: EmotionalArc(),
      dispatch: (_) async {},
    );

    final result = await system.perform(sample(duration: Duration.zero));
    expect(result.success, isFalse);
    expect(prompted, isFalse);
  });
}
