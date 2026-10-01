import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

import '../controllers/unified_animation_controller.dart';
import '../engine/models/model_catalog.dart';

class ModelViewerScreen extends StatefulWidget {
  const ModelViewerScreen({
    super.key,
    this.title = '3D MODEL LAB',
    this.modelUrl,
  });

  final String title;
  final String? modelUrl;

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  late final Flutter3DController _controller;
  late final UnifiedAnimationController _animation;
  double _progress = 0;
  late String _selectedUrl;
  List<String> _availableAnimations = const [];
  bool _loadingAnimations = false;

  @override
  void initState() {
    super.initState();
    _controller = Flutter3DController();
    _animation = UnifiedAnimationController()..addListener(_syncAnimation);
    _selectedUrl = widget.modelUrl ?? ModelCatalog.adultFemaleRigged.url;
  }

  @override
  void dispose() {
    _animation
      ..removeListener(_syncAnimation)
      ..dispose();
    _controller.stopAnimation();
    _controller.stopRotation();
    super.dispose();
  }

  Future<void> _loadAnimations() async {
    if (_loadingAnimations) return;
    setState(() => _loadingAnimations = true);
    try {
      final animations = await _controller.getAvailableAnimations();
      if (!mounted) return;
      setState(() => _availableAnimations = animations);
      _syncAnimation();
    } finally {
      if (mounted) setState(() => _loadingAnimations = false);
    }
  }

  void _syncAnimation() {
    if (_availableAnimations.isEmpty) return;
    final preferred = switch (_animation.currentState) {
      CharacterAnimationState.idle => const ['Idle', 'idle', 'Standing'],
      CharacterAnimationState.walk => const ['Walk', 'walk'],
      CharacterAnimationState.run => const ['Run', 'run'],
      CharacterAnimationState.fall => const ['Fall', 'fall', 'Jump'],
    };

    String? selected;
    for (final name in preferred) {
      selected = _availableAnimations.cast<String?>().firstWhere(
            (candidate) => candidate?.toLowerCase() == name.toLowerCase(),
            orElse: () => null,
          );
      if (selected != null) break;
    }
    selected ??= _availableAnimations.first;
    _controller.playAnimation(animationName: selected);
  }

  void _transition(CharacterAnimationState state) {
    _animation.transitionTo(state);
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
              src: _selectedUrl,
              activeGestureInterceptor: true,
              enableTouch: true,
              progressBarColor: Colors.cyanAccent,
              onProgress: (value) {
                if (mounted) setState(() => _progress = value);
              },
              onLoad: (_) {
                if (!mounted) return;
                setState(() => _progress = 1);
                _loadAnimations();
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
            top: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedUrl,
                  dropdownColor: const Color(0xFF10151F),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: [
                    for (final model in ModelCatalog.all)
                      DropdownMenuItem(
                        value: model.url,
                        child: Text(model.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null || value == _selectedUrl) return;
                    setState(() {
                      _selectedUrl = value;
                      _progress = 0;
                      _availableAnimations = const [];
                    });
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 70,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loadingAnimations)
                    const LinearProgressIndicator(minHeight: 2),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StateButton(
                          label: 'Idle',
                          onPressed: () =>
                              _transition(CharacterAnimationState.idle),
                        ),
                        _StateButton(
                          label: 'Walk',
                          onPressed: () =>
                              _transition(CharacterAnimationState.walk),
                        ),
                        _StateButton(
                          label: 'Run',
                          onPressed: () =>
                              _transition(CharacterAnimationState.run),
                        ),
                        _StateButton(
                          label: 'Fall',
                          onPressed: () =>
                              _transition(CharacterAnimationState.fall),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        icon: Icons.threed_rotation,
                        onPressed: () =>
                            _controller.startRotation(rotationSpeed: 18),
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
                ],
              ),
            ),
          ),
          if (_progress < 1)
            Positioned(
              left: 24,
              right: 24,
              bottom: 58,
              child: LinearProgressIndicator(value: _progress),
            ),
        ],
      ),
    );
  }
}

class _StateButton extends StatelessWidget {
  const _StateButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label),
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
