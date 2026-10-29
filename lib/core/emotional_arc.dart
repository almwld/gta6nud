import 'dart:async';

/// A high-level emotional beat used by a scene director.
enum EmotionalBeat {
  hesitation,
  acceptance,
  passion,
  peak,
  aftermath,
}

typedef EmotionalBeatListener = FutureOr<void> Function(EmotionalBeat beat);

/// Deterministic, testable emotional progression for non-explicit scenes.
///
/// The arc describes narrative state only; it does not execute character
/// animation or imply consent for any interaction.
class EmotionalArc {
  EmotionalArc({
    List<EmotionalBeat> beats = const <EmotionalBeat>[
      EmotionalBeat.hesitation,
      EmotionalBeat.acceptance,
      EmotionalBeat.passion,
      EmotionalBeat.peak,
      EmotionalBeat.aftermath,
    ],
    EmotionalBeatListener? onBeatChanged,
  })  : _beats = List<EmotionalBeat>.unmodifiable(beats),
        _onBeatChanged = onBeatChanged {
    if (_beats.isEmpty) {
      throw ArgumentError.value(beats, 'beats', 'Must contain at least one beat.');
    }
    if (_beats.toSet().length != _beats.length) {
      throw ArgumentError.value(beats, 'beats', 'Each beat must appear only once.');
    }
  }

  final List<EmotionalBeat> _beats;
  final EmotionalBeatListener? _onBeatChanged;
  int _currentIndex = 0;

  Future<void> advance() async {
    if (_currentIndex >= _beats.length - 1) return;
    final nextIndex = _currentIndex + 1;
    await _notifyBeforeCommit(nextIndex);
    _currentIndex = nextIndex;
  }

  Future<void> retreat() async {
    if (_currentIndex <= 0) return;
    final nextIndex = _currentIndex - 1;
    await _notifyBeforeCommit(nextIndex);
    _currentIndex = nextIndex;
  }

  Future<void> reset() async {
    if (_currentIndex == 0) return;
    await _notifyBeforeCommit(0);
    _currentIndex = 0;
  }

  Future<void> _notifyBeforeCommit(int nextIndex) async {
    final listener = _onBeatChanged;
    if (listener != null) {
      await listener(_beats[nextIndex]);
    }
  }

  EmotionalBeat get currentBeat => _beats[_currentIndex];
  double get progress =>
      _beats.length == 1 ? 1.0 : _currentIndex / (_beats.length - 1);
  bool get isAtPeak => currentBeat == EmotionalBeat.peak;
  bool get isAtStart => _currentIndex == 0;
  bool get isAtEnd => _currentIndex == _beats.length - 1;
  List<EmotionalBeat> get beats => _beats;
}
