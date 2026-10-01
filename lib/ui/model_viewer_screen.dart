import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class ModelViewerScreen extends StatefulWidget {
  const ModelViewerScreen({
    super.key,
    this.title = '3D MODEL LAB',
    this.modelUrl = 'https://raw.githubusercontent.com/UMRAM-Bilkent/supine-human-model/main/assets/human.glb',
  });

  final String title;
  final String modelUrl;

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  late final Flutter3DController _controller;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = Flutter3DController();
  }

  @override
  void dispose() {
    _controller.stopRotation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Flutter3DViewer(
              controller: _controller,
              src: widget.modelUrl,
              activeGestureInterceptor: true,
              enableTouch: true,
              progressBarColor: Colors.cyanAccent,
              onProgress: (value) {
                if (mounted) setState(() => _progress = value);
              },
              onLoad: (_) {
                if (mounted) setState(() => _progress = 1);
              },
              onError: (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تعذر تحميل المجسم: $error')),
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ControlButton(
                    icon: Icons.threed_rotation,
                    onPressed: () => _controller.startRotation(rotationSpeed: 18),
                  ),
                  const SizedBox(width: 8),
                  _ControlButton(
                    icon: Icons.pause,
                    onPressed: _controller.pauseRotation,
                  ),
                  const SizedBox(width: 8),
                  _ControlButton(
                    icon: Icons.restart_alt,
                    onPressed: _controller.stopRotation,
                  ),
                ],
              ),
            ),
          ),
          if (_progress < 1)
            Positioned(
              left: 24,
              right: 24,
              bottom: 78,
              child: LinearProgressIndicator(value: _progress),
            ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.72),
      borderRadius: BorderRadius.circular(14),
      child: IconButton(
        tooltip: '3D control',
        color: Colors.white,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
