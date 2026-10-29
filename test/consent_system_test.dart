import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/core/consent_system.dart';

void main() {
  test('does not grant consent until an affirmative response', () async {
    final consent = ConsentSystem(
      prompt: (_) async => ConsentResponse.notNow,
    );

    expect(consent.statusFor(ConsentAction.kiss), ConsentStatus.notAsked);
    expect(await consent.request(ConsentAction.kiss), isFalse);
    expect(consent.statusFor(ConsentAction.kiss), ConsentStatus.hesitant);
    expect(consent.isGranted(ConsentAction.kiss), isFalse);
  });

  test('grants only the approved action and remembers a refusal', () async {
    var calls = 0;
    final consent = ConsentSystem(prompt: (_) async {
      calls++;
      return ConsentResponse.no;
    });

    expect(await consent.request(ConsentAction.kiss), isFalse);
    expect(await consent.request(ConsentAction.kiss), isFalse);
    expect(calls, 1);
    expect(consent.statusFor(ConsentAction.kiss), ConsentStatus.refused);
  });

  test('timeout and prompt errors fail closed', () async {
    final timeoutConsent = ConsentSystem(
      responseTimeout: const Duration(milliseconds: 5),
      prompt: (_) => Completer<ConsentResponse?>().future,
    );
    expect(await timeoutConsent.request(ConsentAction.gentleTouch), isFalse);
    expect(
      timeoutConsent.statusFor(ConsentAction.gentleTouch),
      ConsentStatus.hesitant,
    );

    final errorConsent = ConsentSystem(
      prompt: (_) async => throw StateError('UI unavailable'),
    );
    expect(await errorConsent.request(ConsentAction.whisper), isFalse);
    expect(errorConsent.isGranted(ConsentAction.whisper), isFalse);
  });

  test('boundaries block actions and removing a boundary grants nothing', () async {
    final consent = ConsentSystem(
      prompt: (_) async => ConsentResponse.yes,
    );
    consent.setBoundary(ConsentAction.gaze);

    expect(await consent.request(ConsentAction.gaze), isFalse);
    expect(consent.statusFor(ConsentAction.gaze), ConsentStatus.blocked);

    consent.removeBoundary(ConsentAction.gaze);
    expect(consent.isGranted(ConsentAction.gaze), isFalse);
    expect(await consent.request(ConsentAction.gaze), isTrue);
  });

  test('withdrawal clears grants and calls the host stop hook', () async {
    var stopped = false;
    final consent = ConsentSystem(
      prompt: (_) async => ConsentResponse.yes,
      onWithdraw: () => stopped = true,
    );

    expect(await consent.request(ConsentAction.embrace), isTrue);
    await consent.withdraw();

    expect(stopped, isTrue);
    expect(consent.isWithdrawn, isTrue);
    expect(consent.grantedActions, isEmpty);
    expect(await consent.request(ConsentAction.embrace), isFalse);

    consent.resetForNewScene();
    expect(consent.isWithdrawn, isFalse);
    expect(consent.isGranted(ConsentAction.embrace), isFalse);
  });
}
