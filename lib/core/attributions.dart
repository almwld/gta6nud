/// Third-party asset attribution records used by the application.

class Attribution {
  const Attribution({
    required this.assetName,
    required this.author,
    required this.license,
    required this.sourceUrl,
    this.modifications,
  });

  final String assetName;
  final String author;
  final String license;
  final String sourceUrl;
  final String? modifications;
}

class Attributions {
  static const List<Attribution> all = [
    Attribution(
      assetName: 'Anime Bikini Girl 3D Model',
      author: 'ZeroVert',
      license: 'CC Attribution (CC BY)',
      sourceUrl:
          'https://downloadforfree.gumroad.com/l/free-anime-bikini-girl-3d-model',
      modifications: 'None - used as-is in the character rendering pipeline.',
    ),
  ];
}
