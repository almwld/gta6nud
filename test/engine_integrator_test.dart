import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import 'package:gta6hub/core/character_runtime_state.dart';
import 'package:gta6hub/engine/body/body_animation_controller.dart';
import 'package:gta6hub/engine/body/body_physics_controller.dart';
import 'package:gta6hub/engine/body/body_renderer.dart';
import 'package:gta6hub/engine/engine_integrator.dart';
import 'package:gta6hub/engine/physics/breast_physics.dart';
import 'package:gta6hub/engine/physics/hair_physics.dart';
import 'package:gta6hub/engine/physics/soft_body_physics.dart';

void main() {
  test('EngineIntegrator updates all secondary physics systems each frame', () {
    final softParticle = SoftBodyParticle(position: v.Vector3(0, 1, 0));
    final softBody = SoftBodyPhysics(particles: [softParticle]);
    final hair = HairPhysics();
    final breast = BreastPhysics();
    final runtime = CharacterRuntimeState();
    final engine = EngineIntegrator(
      runtime: runtime,
      renderer: BodyRenderer(),
      animation: BodyAnimationController(),
      physics: BodyPhysicsController(),
      softBodyPhysics: softBody,
      hairPhysics: hair,
      breastPhysics: breast,
    );

    final hairBefore = hair.bones[1].position.y;
    final breastBefore = breast.leftNodes.first.position.y;
    engine.update(1 / 60, const Size(800, 600));

    expect(softParticle.position.y, lessThan(1));
    expect(hair.bones[1].position.y, isNot(hairBefore));
    expect(breast.leftNodes.first.position.y, isNot(breastBefore));

    engine.animation.dispose();
    engine.physics.dispose();
    engine.runtime.dispose();
  });
}
