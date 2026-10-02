/// Production 3D character catalog.
///
/// Sources are restricted to redistributable assets with verified licensing.
/// Keep visual assets separate from simulation/gameplay logic.
class ModelAsset {
  const ModelAsset({
    required this.id,
    required this.name,
    required this.url,
    required this.license,
    this.style = 'general',
    this.rigged = false,
  });

  final String id;
  final String name;
  final String url;
  final String license;
  final String style;
  final bool rigged;
}

class ModelCatalog {
  static const humanBase = ModelAsset(
    id: 'human-base-cc0',
    name: 'Human Base',
    url:
        'https://raw.githubusercontent.com/UMRAM-Bilkent/supine-human-model/main/assets/human.glb',
    license: 'CC0 1.0',
    rigged: true,
  );

  /// CC0 Quaternius female humanoid.
  ///
  /// The source is distributed as glTF + external binary/textures. The
  /// Flutter 3D viewer resolves the referenced resources relative to this URL.
  static const adultFemaleRigged = ModelAsset(
    id: 'adult-female-rigged-cc0',
    name: 'Adult Female — Rigged',
    url:
        'https://raw.githubusercontent.com/NafisRayan/Animate-Rigged-Humanoid-No-Blender/main/Universal%20Base%20Characters%5BStandard%5D/Universal%20Base%20Characters%5BStandard%5D/Base%20Characters/Godot%20-%20UE/Superhero_Female_FullBody.gltf',
    license: 'CC0 1.0 — Quaternius',
    style: 'female-rigged',
    rigged: true,
  );

  static const animeBikiniGirl = ModelAsset(
    id: 'anime-bikini-girl-zerovert',
    name: 'Anime Bikini Girl 3D Model',
    url: 'assets/models/anime_bikini_girl.glb',
    license: 'CC BY — ZeroVert',
    style: 'female-bikini',
    rigged: true,
  );

  static const all = <ModelAsset>[
    humanBase,
    adultFemaleRigged,
    animeBikiniGirl,
  ];
}
