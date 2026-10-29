import 'package:flutter/material.dart';
import 'package:gta6hub/core/character_runtime_state.dart';
import 'package:gta6hub/core/quality_settings.dart';
import 'package:gta6hub/engine/body/body_renderer.dart';
import 'package:gta6hub/engine/body/body_animation_controller.dart';
import 'package:gta6hub/engine/body/body_physics_controller.dart';
import 'package:gta6hub/engine/physics/soft_body_physics.dart';
import 'package:gta6hub/engine/physics/hair_physics.dart';
import 'package:gta6hub/engine/physics/breast_physics.dart';

/// Unified character presentation loop: physics, animation and rendering state.
class EngineIntegrator {
  final CharacterRuntimeState runtime;
  final BodyRenderer renderer;
  final BodyAnimationController animation;
  final BodyPhysicsController physics;
  final SoftBodyPhysics softBodyPhysics;
  final HairPhysics hairPhysics;
  final BreastPhysics breastPhysics;
  final List<PhysicsSphere> bodyColliders;
  QualitySettings quality;

  EngineIntegrator({
    required this.runtime,
    required this.renderer,
    required this.animation,
    required this.physics,
    SoftBodyPhysics? softBodyPhysics,
    HairPhysics? hairPhysics,
    BreastPhysics? breastPhysics,
    this.bodyColliders = const <PhysicsSphere>[],
    this.quality = QualitySettings.defaults,
  })  : softBodyPhysics = softBodyPhysics ?? SoftBodyPhysics(),
        hairPhysics = hairPhysics ?? HairPhysics(),
        breastPhysics = breastPhysics ?? BreastPhysics() {
    renderer.setQuality(quality);
  }

  void update(double deltaTime, Size size) {
    physics.update(deltaTime);
    softBodyPhysics.update(deltaTime, colliders: bodyColliders);
    hairPhysics.update(deltaTime, bodyColliders: bodyColliders);
    breastPhysics.update(deltaTime, bodyColliders: bodyColliders);

    final activity = runtime.activityLevel;
    if (activity > 0.66) {
      animation.play(BodyAnimationType.breathing, speed: 1.25);
    } else if (activity > 0.1) {
      animation.play(BodyAnimationType.breathing, speed: 1.0);
    } else {
      animation.play(BodyAnimationType.idle);
    }

    animation.update(deltaTime);
  }

  void setQuality(QualitySettings next) {
    quality = next;
    renderer.setQuality(next);
  }

  void render(Canvas canvas, Size size) {
    renderer.render(canvas, size, runtime.activityLevel);
  }
}
