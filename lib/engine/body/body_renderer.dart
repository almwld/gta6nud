import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';

class SkinState {
  double redness;
  double sweat;
  double goosebumps;
  double warmth;

  SkinState({
    this.redness = 0.0,
    this.sweat = 0.0,
    this.goosebumps = 0.0,
    this.warmth = 0.0,
  });

  void updateFromArousal(double arousal) {
    redness = (arousal * 0.7).clamp(0.0, 1.0);
    sweat = (arousal * 1.2).clamp(0.0, 1.0);
    goosebumps = (arousal * 0.5).clamp(0.0, 1.0);
    warmth = (arousal * 0.8).clamp(0.0, 1.0);
  }
}

class BodyFrame {
  final Rect sourceRect;
  final Size bodySize;
  final double duration;

  BodyFrame({
    required this.sourceRect,
    required this.bodySize,
    this.duration = 0.016,
  });
}

class BodyRenderer {
  ui.Image? _skinTexture;
  ui.Image? _spriteSheet;
  final List<BodyFrame> _frames = [];
  int _currentFrame = 0;
  double _frameTimer = 0;
  double _bodyRotation = 0;
  SkinState skinState = SkinState();
  bool _isLoaded = false;

  Future<void> loadAssets() async {
    try {
      _skinTexture = await _loadImage('assets/body/skins/default_skin.png');
      _spriteSheet = await _loadImage('assets/body/animations/default_sprite.png');
      _isLoaded = _skinTexture != null || _spriteSheet != null;
    } catch (e) {
      _isLoaded = true; // استمرار بدون أصول
    }
  }

  Future<ui.Image?> _loadImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      return null;
    }
  }

  void buildSpriteFrames({int rows = 4, int cols = 4, double bodyWidth = 200, double bodyHeight = 400}) {
    _frames.clear();
    if (_spriteSheet == null) return;
    final frameWidth = _spriteSheet!.width / cols;
    final frameHeight = _spriteSheet!.height / rows;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        _frames.add(BodyFrame(
          sourceRect: Rect.fromLTWH(c * frameWidth, r * frameHeight, frameWidth, frameHeight),
          bodySize: Size(bodyWidth, bodyHeight),
        ));
      }
    }
  }

  void updateAnimation(double deltaTime) {
    if (_frames.isEmpty) return;
    _frameTimer += deltaTime;
    if (_frameTimer >= _frames[_currentFrame].duration) {
      _frameTimer = 0;
      _currentFrame = (_currentFrame + 1) % _frames.length;
    }
  }

  void render(Canvas canvas, Size screenSize, double arousal) {
    skinState.updateFromArousal(arousal);
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    final bodyWidth = screenSize.width * 0.6;
    final bodyHeight = screenSize.height * 0.7;
    final bodyRect = Rect.fromCenter(center: center, width: bodyWidth, height: bodyHeight);

    _renderSkinLayer(canvas, bodyRect);
    _renderRednessLayer(canvas, bodyRect);
    _renderSweatLayer(canvas, bodyRect);
    _renderWarmthLayer(canvas, bodyRect);
    _renderGoosebumpsLayer(canvas, bodyRect);
    _renderAnimationLayer(canvas, bodyRect);
  }

  void _renderSkinLayer(Canvas canvas, Rect rect) {
    if (_skinTexture != null) {
      canvas.drawImageRect(_skinTexture!, Rect.fromLTWH(0, 0, _skinTexture!.width.toDouble(), _skinTexture!.height.toDouble()), rect, Paint());
    } else {
      canvas.drawRect(rect, Paint()..color = const Color(0xFFE0C0A0));
    }
  }

  void _renderRednessLayer(Canvas canvas, Rect rect) {
    if (skinState.redness <= 0) return;
    canvas.drawRect(rect, Paint()..color = Colors.red.withOpacity(skinState.redness * 0.3)..blendMode = BlendMode.overlay);
    final chestRect = Rect.fromLTWH(rect.left + rect.width * 0.3, rect.top + rect.height * 0.2, rect.width * 0.4, rect.height * 0.3);
    final gradient = RadialGradient(center: Alignment.center, radius: 0.8, colors: [Colors.red.withOpacity(skinState.redness * 0.5), Colors.transparent]);
    canvas.drawRect(chestRect, Paint()..shader = gradient.createShader(chestRect));
  }

  void _renderSweatLayer(Canvas canvas, Rect rect) {
    if (skinState.sweat <= 0) return;
    canvas.drawRect(rect, Paint()..color = Colors.white.withOpacity(skinState.sweat * 0.4)..blendMode = BlendMode.softLight);
    final random = Random(42);
    for (int i = 0; i < (skinState.sweat * 30).toInt(); i++) {
      final x = rect.left + random.nextDouble() * rect.width;
      final y = rect.top + random.nextDouble() * rect.height;
      final size = 1.0 + random.nextDouble() * 3.0 * skinState.sweat;
      canvas.drawCircle(Offset(x, y), size, Paint()..color = Colors.white.withOpacity(skinState.sweat * 0.6));
    }
  }

  void _renderWarmthLayer(Canvas canvas, Rect rect) {
    if (skinState.warmth <= 0) return;
    canvas.drawRect(rect, Paint()..color = Colors.orange.withOpacity(skinState.warmth * 0.15)..blendMode = BlendMode.overlay);
  }

  void _renderGoosebumpsLayer(Canvas canvas, Rect rect) {
    if (skinState.goosebumps <= 0) return;
    final random = Random(123);
    for (int i = 0; i < (skinState.goosebumps * 50).toInt(); i++) {
      final x = rect.left + random.nextDouble() * rect.width;
      final y = rect.top + random.nextDouble() * rect.height;
      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = Colors.white.withOpacity(skinState.goosebumps * 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5));
    }
  }

  void _renderAnimationLayer(Canvas canvas, Rect rect) {
    if (_frames.isEmpty || _spriteSheet == null) return;
    canvas.drawImageRect(_spriteSheet!, _frames[_currentFrame].sourceRect, rect, Paint());
  }

  void rotateBody(double angle) => _bodyRotation = angle;

  void dispose() {
    _skinTexture?.dispose();
    _spriteSheet?.dispose();
    _frames.clear();
  }

  bool get isLoaded => _isLoaded;
  int get frameCount => _frames.length;
}
