import 'package:flutter/foundation.dart';

import '../engine/models/model_catalog.dart';

enum CharacterType {
  human,
  adultFemaleRigged,
}

@immutable
class OutfitConfig {
  const OutfitConfig({
    this.combinedGlbAsset,
    this.label = 'default',
  });

  final String? combinedGlbAsset;
  final String label;
}

@immutable
class CharacterAsset {
  const CharacterAsset({
    required this.source,
    required this.baseModel,
    required this.outfit,
    required this.rigId,
    required this.isRigged,
  });

  final String source;
  final ModelAsset baseModel;
  final OutfitConfig outfit;
  final String rigId;
  final bool isRigged;

  /// The resolved skeleton identifier used by the animation layer.
  String get skeletonId => rigId;

  /// Clothing is considered attached when a combined outfit asset is supplied.
  bool get clothingAttachedToSkeleton => hasCombinedOutfit && isRigged;

  bool get hasCombinedOutfit => outfit.combinedGlbAsset != null;
}

/// Resolves one production character source for the 3D presentation layer.
///
/// Asset selection stays outside widgets; GLB rendering and animation control
/// remain the responsibility of flutter_3d_controller.
class CharacterAssetService {
  const CharacterAssetService();

  Future<CharacterAsset> loadCompleteCharacter({
    required CharacterType type,
    OutfitConfig outfit = const OutfitConfig(),
  }) async {
    final baseModel = switch (type) {
      CharacterType.human => ModelCatalog.humanBase,
      CharacterType.adultFemaleRigged => ModelCatalog.adultFemaleRigged,
    };

    if (!baseModel.rigged) {
      throw StateError('Character model ${baseModel.id} is not rigged.');
    }

    final source = outfit.combinedGlbAsset ?? baseModel.url;
    final rigId = '${baseModel.id}:humanoid';

    if (outfit.combinedGlbAsset != null && outfit.combinedGlbAsset!.isEmpty) {
      throw StateError('Combined outfit asset path cannot be empty.');
    }

    return CharacterAsset(
      source: source,
      baseModel: baseModel,
      outfit: outfit,
      rigId: rigId,
      isRigged: baseModel.rigged,
    );
  }
}
