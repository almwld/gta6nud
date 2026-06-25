import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SkinInfo {
  final String name;
  final String diffusePath;
  final String normalPath;
  final String specularPath;
  final String resolution;

  SkinInfo({
    required this.name,
    required this.diffusePath,
    required this.normalPath,
    required this.specularPath,
    required this.resolution,
  });
}

class BodyModelInfo {
  final String name;
  final String modelPath;
  final String format;

  BodyModelInfo({
    required this.name,
    required this.modelPath,
    required this.format,
  });
}

class BodyLoader {
  static const String _cacheKey = 'downloaded_assets';
  final SharedPreferences _prefs;

  BodyLoader(this._prefs);

  Future<List<SkinInfo>> scanAvailableSkins() async {
    final skins = <SkinInfo>[];
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifest);
      for (final key in manifestMap.keys) {
        if (key.startsWith('assets/body/skins/') && key.endsWith('.png')) {
          final name = key.split('/').last.replaceAll('.png', '');
          skins.add(SkinInfo(
            name: name,
            diffusePath: key,
            normalPath: key.replaceAll('.png', '_normal.png'),
            specularPath: key.replaceAll('.png', '_specular.png'),
            resolution: '8K',
          ));
        }
      }
    } catch (_) {}
    return skins;
  }

  Future<List<BodyModelInfo>> scanAvailableModels() async {
    final models = <BodyModelInfo>[];
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifest);
      for (final key in manifestMap.keys) {
        if (key.startsWith('assets/body/models/') && key.endsWith('.obj')) {
          final name = key.split('/').last.replaceAll('.obj', '');
          models.add(BodyModelInfo(name: name, modelPath: key, format: 'obj'));
        }
      }
    } catch (_) {}
    return models;
  }

  Future<List<int>> loadSkinBytes(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List().toList();
  }

  Future<void> saveDownloadRecord(String assetName) async {
    final records = _prefs.getStringList(_cacheKey) ?? [];
    if (!records.contains(assetName)) {
      records.add(assetName);
      await _prefs.setStringList(_cacheKey, records);
    }
  }

  bool isAssetCached(String assetName) {
    final records = _prefs.getStringList(_cacheKey) ?? [];
    return records.contains(assetName);
  }

  Future<Map<String, int>> getAssetStats() async {
    final skins = await scanAvailableSkins();
    final models = await scanAvailableModels();
    return {
      'skins': skins.length,
      'models': models.length,
      'cached': (_prefs.getStringList(_cacheKey) ?? []).length,
    };
  }
}
