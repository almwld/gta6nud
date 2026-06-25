import 'dart:math';

class AdvancedCurves {
  static const double _pi = 3.141592653589793;
  static const double _e = 2.718281828459045;

  static double breathCurve(double t, double rate) {
    final phase = (t * rate) % 1.0;
    if (phase < 0.4) {
      final x = phase / 0.4;
      return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2;
    } else {
      final x = (phase - 0.4) / 0.6;
      return 1 - (1 - exp(-x * 4)) / (1 - exp(-4));
    }
  }

  static double tremorCurve(double t, double frequency, double intensity) {
    final base = sin(t * frequency * 2 * _pi);
    final jitter = sin(t * frequency * 1.7 * 2 * _pi + 1.3) * 0.3;
    final micro = sin(t * frequency * 2.3 * 2 * _pi + 0.7) * 0.15;
    return (base + jitter + micro) * intensity / 1.45;
  }

  static double heartbeatCurve(double t, double bpm) {
    final period = 60.0 / bpm;
    final phase = (t % period) / period;
    if (phase < 0.08) return pow(phase / 0.08, 0.5);
    if (phase < 0.15) return 1.0 - pow((phase - 0.08) / 0.07, 2);
    if (phase < 0.35) return 0.2 + 0.8 * pow(1 - (phase - 0.15) / 0.2, 3);
    return 0.0;
  }

  static double erectionCurve(double arousal) {
    if (arousal < 0.1) return 0;
    if (arousal > 0.9) return 1.0;
    final x = (arousal - 0.1) / 0.8;
    const c4 = (2 * _pi) / 3;
    return x == 0 ? 0 : x == 1 ? 1 : pow(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1;
  }

  static double orgasmCurve(double t, double duration) {
    final phase = (t / duration).clamp(0.0, 1.0);
    if (phase < 0.6) {
      final x = phase / 0.6;
      return x * x * x;
    } else if (phase < 0.75) {
      return 1.0;
    } else {
      final x = (phase - 0.75) / 0.25;
      return exp(-x * 5);
    }
  }

  static double swayCurve(double t, double baseFreq, double arousal) {
    final freq = baseFreq + arousal * 3.0;
    return sin(t * freq * 2 * _pi) * (0.5 + 0.5 * sin(t * 0.7 * 2 * _pi));
  }

  static double smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static double simpleNoise(double x, double y) {
    final n = (sin(x * 12.9898 + y * 78.233) * 43758.5453) % 1;
    return n < 0 ? n + 1 : n;
  }
}
