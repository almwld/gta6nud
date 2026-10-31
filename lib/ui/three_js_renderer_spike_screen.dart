import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

/// Isolated renderer experiment. The production viewer remains unchanged until
/// GLB loading and mutable GPU-buffer updates are verified on Android devices.
class ThreeJsRendererSpikeScreen extends StatefulWidget {
  const ThreeJsRendererSpikeScreen({super.key});

  @override
  State<ThreeJsRendererSpikeScreen> createState() =>
      _ThreeJsRendererSpikeScreenState();
}

class _ThreeJsRendererSpikeScreenState
    extends State<ThreeJsRendererSpikeScreen> {
  late final three.ThreeJS _threeJs;
  three.BufferGeometry? _probeGeometry;
  bool _ready = false;
  bool _loading = false;
  String _status = 'Renderer prototype';

  @override
  void initState() {
    super.initState();
    _threeJs = three.ThreeJS(
      onSetupComplete: () {
        if (mounted) setState(() => _ready = true);
      },
      setup: _setupScene,
    );
  }

  Future<void> _setupScene() async {
    _threeJs.camera = three.PerspectiveCamera(
      45,
      _threeJs.width / _threeJs.height,
      0.1,
      100,
    );
    _threeJs.camera.position.setValues(0, 1.5, 5);
    _threeJs.scene = three.Scene();
    _threeJs.scene.background = three.Color(0x101722);

    _threeJs.scene.add(three.AmbientLight(0xffffff, 0.8));
    final light = three.PointLight(0xffffff, 1.2);
    light.position.setValues(3, 4, 5);
    _threeJs.scene.add(light);

    // A deliberately mutable mesh verifies CPU -> BufferAttribute -> GPU flow.
    final geometry = three.SphereGeometry(1, 32, 24);
    _probeGeometry = geometry;
    final material = three.MeshNormalMaterial();
    final probe = three.Mesh(geometry, material);
    _threeJs.scene.add(probe);

    var elapsed = 0.0;
    _threeJs.addAnimationEvent((delta) {
      elapsed += delta;
      final position = geometry.getAttribute(three.Attribute.position);
      if (position == null) return;
      final values = position.array;
      for (var vertex = 0; vertex < position.count; vertex++) {
        final offset = vertex * position.itemSize;
        final x = values[offset] as num;
        final y = values[offset + 1] as num;
        final z = values[offset + 2] as num;
        final radius = math.sqrt(x * x + y * y + z * z);
        final wave = 1 + 0.045 * math.sin(elapsed * 2.4 + y * 5);
        values[offset] = x / radius * wave;
        values[offset + 1] = y / radius * wave;
        values[offset + 2] = z / radius * wave;
      }
      position.needsUpdate = true;
      geometry.computeVertexNormals();
      geometry.computeBoundingSphere();
    });
  }

  Future<void> _pickGlb() async {
    if (!_ready || _loading) return;
    setState(() {
      _loading = true;
      _status = 'Selecting GLB…';
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['glb'],
        withData: false,
      );
      if (!mounted || result == null || result.files.single.path == null) {
        return;
      }
      final loader = three.GLTFLoader();
      final gltf = await loader.fromFile(File(result.files.single.path!));
      if (!mounted) return;
      if (gltf == null) {
        setState(() => _status = 'GLB loader returned no scene');
        return;
      }
      _threeJs.scene.add(gltf.scene);
      setState(() => _status = 'Loaded: ${result.files.single.name}');
    } catch (error) {
      if (mounted) setState(() => _status = 'Load failed: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _probeGeometry?.dispose();
    _threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff080b12),
      appBar: AppBar(
        title: const Text('Renderer Spike'),
        actions: [
          IconButton(
            onPressed: _ready && !_loading ? _pickGlb : null,
            tooltip: 'Load local GLB',
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_open),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _threeJs.build()),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Card(
              color: Colors.black.withOpacity(0.72),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _ready ? _status : 'Initializing renderer…',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
