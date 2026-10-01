/// Central catalog for production 3D assets.
///
/// Keep model URLs/licensing metadata here so UI code never hard-codes
/// individual assets. Replace remote URLs with bundled assets when the
/// production asset pack is approved.
class ModelAsset {
  const ModelAsset({
    required this.id,
    required this.name,
    required this.url,
    required this.license,
  });

  final String id;
  final String name;
  final String url;
  final String license;
}

class ModelCatalog {
  static const humanBase = ModelAsset(
    id: 'human-base-cc0',
    name: 'Human Base',
    url:
        'https://raw.githubusercontent.com/UMRAM-Bilkent/supine-human-model/main/assets/human.glb',
    license: 'CC0 1.0',
  );

  static const all = <ModelAsset>[humanBase];
}
