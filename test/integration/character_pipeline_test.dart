import 'package:flutter_test/flutter_test.dart';
import 'package:gta6hub/core/resource_manager.dart';

import 'package:gta6hub/controllers/unified_animation_controller.dart';
import 'package:gta6hub/services/character_asset_service.dart';

void main() {
  test('unified animation state machine transitions deterministically', () {
    final controller = UnifiedAnimationController();

    expect(controller.currentState, CharacterAnimationState.idle);

    controller.transitionTo(CharacterAnimationState.walk);
    expect(controller.currentState, CharacterAnimationState.walk);
    expect(controller.previousState, CharacterAnimationState.idle);
    expect(controller.isTransitioning, isTrue);

    controller.update(0.2);
    expect(controller.transitionProgress, 1.0);
    expect(controller.previousState, isNull);
  });

  test('resource manager reuses live resources by key', () {
    final manager = ResourceManager();
    final first = manager.getOrCreate('character', () => Object());
    final second = manager.getOrCreate('character', () => Object());

    expect(identical(first, second), isTrue);
    expect(manager.size, 1);
    manager.remove('character');
    expect(manager.size, 0);
  });

  test('character asset service returns one rigged character source', () async {
    const service = CharacterAssetService();

    final character = await service.loadCompleteCharacter(
      type: CharacterType.adultFemaleRigged,
    );

    expect(character.source, isNotEmpty);
    expect(character.baseModel.rigged, isTrue);
    expect(character.isRigged, isTrue);
    expect(character.rigId, contains('humanoid'));
  });
}
