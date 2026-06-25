import 'dart:collection';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MotionFrame {
  final double speed;
  final double depth;
  final String position;
  final double timestamp;
  MotionFrame({required this.speed, required this.depth, required this.position, required this.timestamp});
  Map<String, dynamic> toJson() => {'speed': speed, 'depth': depth, 'position': position, 'timestamp': timestamp};
  factory MotionFrame.fromJson(Map<String, dynamic> j) => MotionFrame(speed: j['speed'], depth: j['depth'], position: j['position'], timestamp: j['timestamp']);
}

class SavedSequence {
  final String name;
  final List<MotionFrame> frames;
  SavedSequence({required this.name, required this.frames});
  Map<String, dynamic> toJson() => {'name': name, 'frames': frames.map((f) => f.toJson()).toList()};
  factory SavedSequence.fromJson(Map<String, dynamic> j) => SavedSequence(name: j['name'], frames: (j['frames'] as List).map((f) => MotionFrame.fromJson(f)).toList());
}

class MotionRecorder {
  final ListQueue<MotionFrame> _frames = ListQueue();
  bool _isRecording = false;
  bool _isPlaying = false;
  double _recordingTime = 0;
  double _playbackTime = 0;
  int _playIndex = 0;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  int get frameCount => _frames.length;
  double get playbackTime => _playbackTime;

  void startRecording() { _frames.clear(); _isRecording = true; _recordingTime = 0; }
  void stopRecording() => _isRecording = false;

  void recordFrame(double speed, double depth, String position, double delta) {
    if (!_isRecording) return;
    _recordingTime += delta;
    if (_frames.isEmpty || _recordingTime - _frames.last.timestamp > 0.1) {
      _frames.add(MotionFrame(speed: speed, depth: depth, position: position, timestamp: _recordingTime));
    }
  }

  void startPlayback() { if (_frames.isEmpty) return; _isPlaying = true; _playIndex = 0; _playbackTime = 0; }
  void stopPlayback() => _isPlaying = false;

  MotionFrame? getFrameAtTime(double time) {
    if (_frames.isEmpty) return null;
    while (_playIndex < _frames.length - 1 && _frames.elementAt(_playIndex + 1).timestamp <= time) _playIndex++;
    return _frames.elementAt(_playIndex);
  }

  void updatePlayback(double delta) {
    if (!_isPlaying) return;
    _playbackTime += delta;
    if (_playbackTime > _frames.last.timestamp) stopPlayback();
  }

  Future<void> saveCurrentSequence(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final seq = SavedSequence(name: name, frames: _frames.toList());
    final existing = prefs.getStringList('saved_sequences') ?? [];
    existing.add(jsonEncode(seq.toJson()));
    await prefs.setStringList('saved_sequences', existing);
  }
}
