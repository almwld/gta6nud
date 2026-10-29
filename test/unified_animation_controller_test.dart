import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/controllers/unified_animation_controller.dart';

void main() {
  group('UnifiedAnimationController', () {
    test('selects idle, walk, run, ability and hit states', () {
      final controller = UnifiedAnimationController();
      controller.updateFromInput(Offset.zero, isGrounded: true);
      expect(controller.currentState, CharacterAnimationState.idle);
      controller.updateFromInput(const Offset(1, 0), isGrounded: true);
      expect(controller.currentState, CharacterAnimationState.walk);
      controller.updateFromInput(const Offset(3, 0), isGrounded: true);
      expect(controller.currentState, CharacterAnimationState.run);
      controller.updateFromInput(Offset.zero, isGrounded: true, isAbilityActive: true);
      expect(controller.currentState, CharacterAnimationState.abilityUse);
      controller.updateFromInput(Offset.zero, isGrounded: true, wasHit: true);
      expect(controller.currentState, CharacterAnimationState.hit);
      controller.dispose();
    });

    test('crossfade completes over the configured 0.2 seconds', () {
      final controller = UnifiedAnimationController();
      controller.transitionTo(CharacterAnimationState.walk, duration: 0.2);
      expect(controller.isTransitioning, isTrue);
      controller.update(0.1);
      expect(controller.transitionProgress, closeTo(0.5, 1e-9));
      controller.update(0.1);
      expect(controller.transitionProgress, 1);
      expect(controller.previousState, isNull);
      controller.dispose();
    });

    test('reset returns to idle without an active transition', () {
      final controller = UnifiedAnimationController();
      controller.transitionTo(CharacterAnimationState.hit);
      controller.reset();
      expect(controller.currentState, CharacterAnimationState.idle);
      expect(controller.isTransitioning, isFalse);
      controller.dispose();
    });
  });
}
