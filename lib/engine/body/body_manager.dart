import 'package:flutter/material.dart';
import 'package:gta6hub/engine/body/body_renderer.dart';
import 'package:gta6hub/engine/body/body_animation_controller.dart';
import 'package:gta6hub/engine/body/body_physics_controller.dart';
import 'package:gta6hub/engine/body/body_loader.dart';

class BodyManager extends ChangeNotifier {
  final BodyRenderer renderer;
  final BodyAnimationController animation;
  final BodyPhysicsController physics;
  final BodyLoader loader;

  double _arousal = 0;
  double _pleasure = 0;
  bool _isInitialized = false;

  BodyManager({
    required this.renderer,
    required this.animation,
    required this.physics,
    required this.loader,
  });

  Future<void> initialize() async {
    await renderer.loadAssets();
    renderer.buildSpriteFrames(rows: 4, cols: 4);
    _isInitialized = renderer.isLoaded;
    if (_isInitialized) {
      animation.play(BodyAnimationType.breathing, speed: 0.5);
    }
    notifyListeners();
  }

  void update(double deltaTime) {
    if (!_isInitialized) return;
    animation.update(deltaTime);
    physics.update(deltaTime);
    renderer.updateAnimation(deltaTime);
    if (animation.currentType == BodyAnimationType.breathing) {
      final breathRate = 0.5 + _arousal * 1.5;
      animation.setSpeed(breathRate);
    }
    notifyListeners();
  }

  void render(Canvas canvas, Size screenSize) {
    if (!_isInitialized) {
      _renderLoading(canvas, screenSize);
      return;
    }
    canvas.save();
    canvas.translate(screenSize.width / 2 + physics.position.dx, screenSize.height / 2 + physics.position.dy);
    canvas.rotate(physics.state.rotation);
    if (physics.tension > 0.1) {
      canvas.translate(physics.state.velocity.dx * 0.1, physics.state.velocity.dy * 0.1);
    }
    renderer.render(canvas, screenSize, _arousal);
    canvas.restore();
  }

  void _renderLoading(Canvas canvas, Size screenSize) {
    final paint = Paint()..color = const Color(0xFF0A0A0F);
    canvas.drawRect(Offset.zero & screenSize, paint);
    final textPainter = TextPainter(
      text: TextSpan(text: 'Loading Body Assets...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((screenSize.width - textPainter.width) / 2, screenSize.height / 2));
  }

  void setArousal(double value) {
    _arousal = value.clamp(0.0, 1.0);
    renderer.skinState.updateFromArousal(_arousal);
    notifyListeners();
  }

  void setPleasure(double value) {
    _pleasure = value.clamp(0.0, 1.0);
    if (_pleasure > 0.8 && animation.currentType != BodyAnimationType.climaxing) {
      animation.play(BodyAnimationType.climaxing);
    }
    notifyListeners();
  }

  void touchPoint(String pointName, double force) {
    physics.applyImpulseAtPoint(pointName, Offset(0, -force));
    physics.heatPoint(pointName, force * 2);
  }

  void startThrusting() => animation.play(BodyAnimationType.thrusting, speed: 1.0);
  void startReceiving() => animation.play(BodyAnimationType.receiving, speed: 1.0);

  void triggerClimax() {
    animation.play(BodyAnimationType.climaxing);
    physics.applyShake(1.0);
  }

  void recover() {
    animation.play(BodyAnimationType.recovering);
    physics.reset();
    setArousal(0);
    setPleasure(0);
  }

  void reset() {
    animation.stop();
    physics.reset();
    setArousal(0);
    setPleasure(0);
    animation.play(BodyAnimationType.breathing, speed: 0.5);
  }

  bool get isInitialized => _isInitialized;
  double get arousal => _arousal;
  double get pleasure => _pleasure;
  BodyRenderer get bodyRenderer => renderer;
  BodyAnimationController get bodyAnimation => animation;
  BodyPhysicsController get bodyPhysics => physics;

  @override
  void dispose() {
    renderer.dispose();
    animation.dispose();
    physics.dispose();
    super.dispose();
  }
}
