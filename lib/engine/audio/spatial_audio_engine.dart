import 'package:audioplayers/audioplayers.dart';

class SpatialAudioEngine {
  final AudioPlayer _heartbeatPlayer = AudioPlayer();
  final AudioPlayer _breathingPlayer = AudioPlayer();
  final AudioPlayer _moanPlayer = AudioPlayer();
  final AudioPlayer _screamPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _wetPlayer = AudioPlayer();

  bool _isInitialized = false;
  double _masterVolume = 1.0;
  double _currentArousal = 0.0;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _heartbeatPlayer.setReleaseMode(ReleaseMode.loop);
      await _breathingPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);

      await _heartbeatPlayer.play(AssetSource('audio/heartbeat.mp3'));
      await _heartbeatPlayer.setVolume(0.3);
      await _breathingPlayer.play(AssetSource('audio/breathing.mp3'));
      await _breathingPlayer.setVolume(0.2);
      await _ambientPlayer.play(AssetSource('audio/ambient.mp3'));
      await _ambientPlayer.setVolume(0.15);

      _isInitialized = true;
    } catch (e) {
      _isInitialized = true;
    }
  }

  void updateArousal(double arousal) {
    _currentArousal = arousal.clamp(0.0, 1.0);
    final a = _currentArousal;
    _heartbeatPlayer.setPlaybackRate(1.0 + a * 2.5);
    _heartbeatPlayer.setVolume((0.3 + a * 0.6) * _masterVolume);
    _breathingPlayer.setPlaybackRate(1.0 + a * 1.5);
    _breathingPlayer.setVolume((0.2 + a * 0.7) * _masterVolume);
    _ambientPlayer.setVolume((0.15 + a * 0.3) * _masterVolume);
  }

  Future<void> playMoan({double volume = 0.8, double speed = 50.0}) async {
    try {
      final key = _currentArousal > 0.7 ? 'audio/moan_high.mp3' : 'audio/moan_low.mp3';
      await _moanPlayer.stop();
      await _moanPlayer.play(AssetSource(key));
      await _moanPlayer.setVolume((volume * _masterVolume).clamp(0.0, 1.0));
      await _moanPlayer.setPlaybackRate((speed / 50.0).clamp(0.8, 1.5));
    } catch (_) {}
  }

  Future<void> playScream() async {
    try {
      await _ambientPlayer.setVolume(0.05);
      await _breathingPlayer.setVolume(0.1);
      await _screamPlayer.stop();
      await _screamPlayer.play(AssetSource('audio/scream.mp3'));
      await _screamPlayer.setVolume(_masterVolume);
      Future.delayed(const Duration(seconds: 2), () => updateArousal(_currentArousal));
    } catch (_) {}
  }

  Future<void> playWetSound({double volume = 0.5, double speed = 1.0}) async {
    try {
      await _wetPlayer.stop();
      await _wetPlayer.play(AssetSource('audio/wet.mp3'));
      await _wetPlayer.setVolume((volume * _masterVolume).clamp(0.0, 1.0));
      await _wetPlayer.setPlaybackRate(speed);
    } catch (_) {}
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    updateArousal(_currentArousal);
  }

  Future<void> dispose() async {
    await _heartbeatPlayer.dispose();
    await _breathingPlayer.dispose();
    await _moanPlayer.dispose();
    await _screamPlayer.dispose();
    await _ambientPlayer.dispose();
    await _wetPlayer.dispose();
  }
}
