import 'package:flutter/material.dart';
import 'package:gta6hub/core/character_runtime_state.dart';
import 'package:gta6hub/engine/body/body_renderer.dart';
import 'package:gta6hub/engine/body/body_animation_controller.dart';
import 'package:gta6hub/engine/body/body_physics_controller.dart';

/// Unified character presentation loop.
///
/// Gameplay/simulation code supplies a neutral runtime state; this class owns
/// the single per-frame order for physics, animation and rendering state.
class EngineIntegrator {
  final CharacterRuntimeState runtime;
  final BodyRenderer renderer;
  final BodyAnimationController animation;
  final BodyPhysicsController physics;

  EngineIntegrator({
    required this.runtime,
    required this.renderer,
    required this.animation,
    required this.physics,
  });

  void update(double deltaTime, Size size) {
    physics.update(deltaTime);

    final activity = runtime.activityLevel;
    if (activity > 0.66) {
      animation.play(BodyAnimationType.breathing, speed: 1.25);
    } else if (activity > 0.1) {
      animation.play(BodyAnimationType.breathing, speed: 1.0);
    } else {
      animation.play(BodyAnimationType.idle);
    }

    animation.update(deltaTime);
    renderer.skinState.updateFromArousal(activity);
  }

  void render(Canvas canvas, Size size) {
    renderer.render(canvas, size, runtime.activityLevel);
  }
}
