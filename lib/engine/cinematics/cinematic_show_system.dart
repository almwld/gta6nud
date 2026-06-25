import 'dart:math';
import 'package:flutter/material.dart';

class CinematicLayer {
  final CinematicEffect effect;
  final double startTime;
  final double endTime;
  final Map<String, dynamic> params;
  CinematicLayer({required this.effect, required this.startTime, required this.endTime, this.params = const {}});
}

enum CinematicEffect { screenShake, redFlash, whiteFlash, vignette, particleBurst, zoomPulse, glitch, slowMotion }

class CinematicScene {
  final String name;
  final double duration;
  final List<CinematicLayer> layers;
  CinematicScene({required this.name, required this.duration, required this.layers});
}

class CinematicShowSystem {
  CinematicScene? _currentScene;
  double _sceneTime = 0;
  bool _isPlaying = false;
  double _shakeIntensity = 0;
  double _redFlashOpacity = 0;
  double _whiteFlashOpacity = 0;
  double _vignetteOpacity = 0;
  double _zoomLevel = 1.0;
  double _glitchIntensity = 0;
  final Map<String, CinematicScene> _scenes = {};
  final Random _random = Random();

  CinematicShowSystem() {
    _scenes['climax'] = CinematicScene(name: 'Climax', duration: 3.0, layers: [
      CinematicLayer(effect: CinematicEffect.whiteFlash, startTime: 0.0, endTime: 0.15),
      CinematicLayer(effect: CinematicEffect.screenShake, startTime: 0.0, endTime: 0.8, params: {'intensity': 1.0}),
      CinematicLayer(effect: CinematicEffect.redFlash, startTime: 0.1, endTime: 0.5),
      CinematicLayer(effect: CinematicEffect.particleBurst, startTime: 0.0, endTime: 0.3, params: {'count': 100}),
      CinematicLayer(effect: CinematicEffect.vignette, startTime: 0.0, endTime: 1.0, params: {'maxOpacity': 0.8}),
      CinematicLayer(effect: CinematicEffect.zoomPulse, startTime: 0.0, endTime: 0.6, params: {'intensity': 1.5}),
      CinematicLayer(effect: CinematicEffect.glitch, startTime: 0.2, endTime: 0.4),
    ]);
    _scenes['arousal'] = CinematicScene(name: 'Arousal', duration: 2.0, layers: [
      CinematicLayer(effect: CinematicEffect.vignette, startTime: 0.0, endTime: 1.0, params: {'maxOpacity': 0.3}),
      CinematicLayer(effect: CinematicEffect.redFlash, startTime: 0.0, endTime: 1.0, params: {'maxOpacity': 0.2}),
      CinematicLayer(effect: CinematicEffect.screenShake, startTime: 0.0, endTime: 1.0, params: {'intensity': 0.2}),
    ]);
    _scenes['calm'] = CinematicScene(name: 'Calm', duration: 1.0, layers: [
      CinematicLayer(effect: CinematicEffect.vignette, startTime: 0.0, endTime: 1.0, params: {'maxOpacity': 0.1}),
    ]);
  }

  void play(String sceneName) {
    _currentScene = _scenes[sceneName];
    if (_currentScene != null) { _sceneTime = 0; _isPlaying = true; }
  }

  void stop() { _isPlaying = false; _currentScene = null; _reset(); }

  void _reset() {
    _shakeIntensity = 0; _redFlashOpacity = 0; _whiteFlashOpacity = 0;
    _vignetteOpacity = 0; _zoomLevel = 1.0; _glitchIntensity = 0;
  }

  void update(double deltaTime) {
    if (!_isPlaying || _currentScene == null) return;
    _sceneTime += deltaTime;
    final progress = (_sceneTime / _currentScene!.duration).clamp(0.0, 1.0);
    if (progress >= 1.0) { stop(); return; }
    _reset();
    for (final layer in _currentScene!.layers) {
      if (progress >= layer.startTime && progress <= layer.endTime) {
        final lp = (progress - layer.startTime) / (layer.endTime - layer.startTime);
        final intensity = lp < 0.3 ? lp / 0.3 : 1.0 - ((lp - 0.3) / 0.7);
        switch (layer.effect) {
          case CinematicEffect.screenShake: _shakeIntensity = intensity * (layer.params['intensity'] ?? 1.0); break;
          case CinematicEffect.redFlash: _redFlashOpacity = intensity * (layer.params['maxOpacity'] ?? 0.8); break;
          case CinematicEffect.whiteFlash: _whiteFlashOpacity = intensity * 0.9; break;
          case CinematicEffect.vignette: _vignetteOpacity = intensity * (layer.params['maxOpacity'] ?? 0.7); break;
          case CinematicEffect.zoomPulse: _zoomLevel = 1.0 + intensity * 0.08 * (layer.params['intensity'] ?? 1.0); break;
          case CinematicEffect.glitch: _glitchIntensity = intensity; break;
          default: break;
        }
      }
    }
  }

  void applyEffects(Canvas canvas, Size size) {
    if (!_isPlaying) return;
    if (_redFlashOpacity > 0) canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFF2A6D).withOpacity(_redFlashOpacity));
    if (_whiteFlashOpacity > 0) canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withOpacity(_whiteFlashOpacity));
    if (_vignetteOpacity > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..shader = RadialGradient(center: Alignment.center, radius: 0.8, colors: [Colors.transparent, Colors.black.withOpacity(_vignetteOpacity)]).createShader(Offset.zero & size));
    }
    if (_glitchIntensity > 0) {
      for (int i = 0; i < (_glitchIntensity * 10).toInt(); i++) {
        final y = _random.nextDouble() * size.height;
        canvas.drawRect(Rect.fromLTWH(0, y, size.width, _random.nextDouble() * 20), Paint()..color = const Color(0xFF00D4FF).withOpacity(_glitchIntensity * 0.3));
      }
    }
  }

  Offset applyShake(Offset pos) {
    if (_shakeIntensity <= 0) return pos;
    return pos + Offset((_random.nextDouble() - 0.5) * _shakeIntensity * 30, (_random.nextDouble() - 0.5) * _shakeIntensity * 30);
  }

  double get zoomLevel => _zoomLevel;
  bool get isPlaying => _isPlaying;
}
