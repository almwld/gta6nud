import 'package:shared_preferences/shared_preferences.dart';

enum QualityLevel { low, medium, high }

class QualitySettings {
  const QualitySettings._({
    required this.level,
    required this.renderScale,
    required this.shadowMapSize,
    required this.ssao,
    required this.ssr,
  });

  final QualityLevel level;
  final double renderScale;
  final int shadowMapSize;
  final bool ssao;
  final bool ssr;

  static const low = QualitySettings._(
    level: QualityLevel.low,
    renderScale: 0.5,
    shadowMapSize: 1024,
    ssao: false,
    ssr: false,
  );

  static const medium = QualitySettings._(
    level: QualityLevel.medium,
    renderScale: 0.75,
    shadowMapSize: 2048,
    ssao: true,
    ssr: false,
  );

  static const high = QualitySettings._(
    level: QualityLevel.high,
    renderScale: 1.0,
    shadowMapSize: 4096,
    ssao: true,
    ssr: true,
  );

  static const defaults = medium;

  static QualitySettings forLevel(QualityLevel level) => switch (level) {
        QualityLevel.low => low,
        QualityLevel.medium => medium,
        QualityLevel.high => high,
      };

  static Future<QualitySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('quality_level') ?? QualityLevel.medium.index;
    final safeIndex = index.clamp(0, QualityLevel.values.length - 1).toInt();
    return forLevel(QualityLevel.values[safeIndex]);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quality_level', level.index);
  }

  Future<QualitySettings> select(QualityLevel next) async {
    final selected = forLevel(next);
    await selected.save();
    return selected;
  }
}
