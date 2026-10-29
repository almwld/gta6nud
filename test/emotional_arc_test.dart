import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/core/emotional_arc.dart';

void main() {
  test('advances through beats and reports normalized progress', () async {
    final arc = EmotionalArc();

    expect(arc.currentBeat, EmotionalBeat.hesitation);
    expect(arc.progress, 0);

    await arc.advance();
    expect(arc.currentBeat, EmotionalBeat.acceptance);
    expect(arc.progress, 0.25);

    await arc.advance();
    await arc.advance();
    expect(arc.currentBeat, EmotionalBeat.peak);
    expect(arc.isAtPeak, isTrue);
    expect(arc.isAtEnd, isFalse);

    await arc.advance();
    expect(arc.currentBeat, EmotionalBeat.aftermath);
    expect(arc.isAtPeak, isFalse);
    expect(arc.isAtEnd, isTrue);
    expect(arc.progress, 1);
  });

  test('retreat and reset do not move before the first beat', () async {
    final arc = EmotionalArc();

    await arc.retreat();
    expect(arc.currentBeat, EmotionalBeat.hesitation);
    expect(arc.progress, 0);

    await arc.advance();
    await arc.retreat();
    expect(arc.currentBeat, EmotionalBeat.hesitation);

    await arc.advance();
    await arc.reset();
    expect(arc.currentBeat, EmotionalBeat.hesitation);
  });

  test('notifies listener and preserves state if listener fails', () async {
    final seen = <EmotionalBeat>[];
    final arc = EmotionalArc(onBeatChanged: (beat) {
      seen.add(beat);
    });

    await arc.advance();
    expect(seen, <EmotionalBeat>[EmotionalBeat.acceptance]);

    final failing = EmotionalArc(onBeatChanged: (_) {
      throw StateError('listener failed');
    });
    await expectLater(failing.advance(), throwsStateError);
    expect(failing.currentBeat, EmotionalBeat.hesitation);
  });

  test('rejects empty or duplicate beat lists', () {
    expect(() => EmotionalArc(beats: const []), throwsArgumentError);
    expect(
      () => EmotionalArc(
        beats: const [EmotionalBeat.hesitation, EmotionalBeat.hesitation],
      ),
      throwsArgumentError,
    );
  });
}
