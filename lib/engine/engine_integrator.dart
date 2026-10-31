import 'package:flutter/material.dart';
import 'package:gta6hub/core/character_runtime_state.dart';
import 'package:gta6hub/core/quality_settings.dart';
import 'package:gta6hub/engine/body/body_renderer.dart';
import 'package:gta6hub/engine/body/body_animation_controller.dart';
import 'package:gta6hub/engine/body/body_physics_controller.dart';
import 'package:gta6hub/engine/physics/soft_body_physics.dart';
import 'package:gta6hub/engine/physics/hair_physics.dart';
import 'package:gta6hub/engine/physics/breast_physics.dart';
import 'package:gta6hub/engine/physics/soft_body_contact_solver.dart';
import 'package:gta6hub/engine/physics/stable_mesh_buffer.dart';

/// A pair of stable mesh buffers that should be kept apart by the contact solver.
///
/// Buffers must contain world-space packed XYZ positions. The binding is
/// evaluated once per fixed simulation step, after structural soft-body
/// constraints and before animation/render consumers read the deformed data.
class SoftBodyContactBinding {
  const SoftBodyContactBinding({
    required this.first,
    required this.second,
    required this.contactThreshold,
    this.stiffness = 0.5,
    this.firstWeight = 0.5,
    this.secondWeight = 0.5,
    this.maxContacts = 20000,
  });

  final StableMeshBuffer first;
  final StableMeshBuffer second;
  final double contactThreshold;
  final double stiffness;
  final double firstWeight;
  final double secondWeight;
  final int maxContacts;

  ContactSolveResult solve() => SoftBodyContactSolver.solveBuffers(
        upper: first,
        lower: second,
        contactThreshold: contactThreshold,
        stiffness: stiffness,
        upperWeight: firstWeight,
        lowerWeight: secondWeight,
        maxContacts: maxContacts,
      );
}

/// Unified character presentation loop: fixed-step physics, animation and rendering.
class EngineIntegrator {
  static const double fixedTimeStep = 1.0 / 120.0;
  static const double maxFrameDelta = 0.25;
  static const int maxSubSteps = 8;

  final CharacterRuntimeState runtime;
  final BodyRenderer renderer;
  final BodyAnimationController animation;
  final BodyPhysicsController physics;
  final SoftBodyPhysics softBodyPhysics;
  final HairPhysics hairPhysics;
  final BreastPhysics breastPhysics;
  final List<PhysicsSphere> bodyColliders;
  final List<SoftBodyContactBinding> contactBindings;
  QualitySettings quality;

  double _accumulator = 0.0;

  /// Interpolation fraction available to a renderer that supports it.
  double get interpolationAlpha =>
      (_accumulator / fixedTimeStep).clamp(0.0, 1.0).toDouble();

  EngineIntegrator({
    required this.runtime,
    required this.renderer,
    required this.animation,
    required this.physics,
    SoftBodyPhysics? softBodyPhysics,
    HairPhysics? hairPhysics,
    BreastPhysics? breastPhysics,
    this.bodyColliders = const <PhysicsSphere>[],
    this.contactBindings = const <SoftBodyContactBinding>[],
    this.quality = QualitySettings.defaults,
  })  : softBodyPhysics = softBodyPhysics ?? SoftBodyPhysics(),
        hairPhysics = hairPhysics ?? HairPhysics(),
        breastPhysics = breastPhysics ?? BreastPhysics() {
    renderer.setQuality(quality);
  }

  /// Accumulates variable frame time and advances simulation at a fixed rate.
  ///
  /// Large frame gaps are clamped, and work is capped to [maxSubSteps] to
  /// prevent a spiral of death after a stall. Excess accumulated time is
  /// deliberately discarded once the cap is reached.
  void update(double deltaTime, Size size) {
    if (!deltaTime.isFinite || deltaTime <= 0.0) return;

    _accumulator += deltaTime.clamp(0.0, maxFrameDelta).toDouble();
    var steps = 0;
    while (_accumulator >= fixedTimeStep && steps < maxSubSteps) {
      _step(fixedTimeStep);
      _accumulator -= fixedTimeStep;
      steps++;
    }

    if (steps == maxSubSteps && _accumulator >= fixedTimeStep) {
      _accumulator %= fixedTimeStep;
    }
  }

  void _step(double dt) {
    physics.update(dt);
    softBodyPhysics.update(dt, colliders: bodyColliders);
    hairPhysics.update(dt, bodyColliders: bodyColliders);
    breastPhysics.update(dt, bodyColliders: bodyColliders);
    for (final binding in contactBindings) {
      binding.solve();
    }

    final activity = runtime.activityLevel;
    if (activity > 0.66) {
      animation.play(BodyAnimationType.breathing, speed: 1.25);
    } else if (activity > 0.1) {
      animation.play(BodyAnimationType.breathing, speed: 1.0);
    } else {
      animation.play(BodyAnimationType.idle);
    }

    animation.update(dt);
  }

  void resetSimulationClock() {
    _accumulator = 0.0;
  }

  void setQuality(QualitySettings next) {
    quality = next;
    renderer.setQuality(next);
  }

  void render(Canvas canvas, Size size) {
    renderer.render(canvas, size, runtime.activityLevel);
  }
}
