import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

import '../services/local_glb_import_service.dart';

/// Local-first GLB workspace. No bundled character, preset rig, or movement UI.
class ModelViewerScreen extends StatefulWidget {
  const ModelViewerScreen({super.key, this.title = '3D MODEL LAB'});

  final String title;

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  late final Flutter3DController _controller;
  final LocalGlbImportService _importService = const LocalGlbImportService();

  String? _selectedUrl;
  ImportedGlb? _importedModel;
  double _progress = 0;
  bool _importing = false;

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

  Future<void> _pickLocalGlb() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final imported = await _importService.pickAndImport();
      if (!mounted || imported == null) return;
      setState(() {
        _importedModel = imported;
        _selectedUrl = imported.dataUri;
        _progress = 0;
      });
      final inspection = imported.inspection;
      final message = inspection.autoRigApplied
          ? 'تم استيراد المجسم وإنشاء Skin والعظام تلقائياً.'
          : inspection.alreadyRigged
              ? 'تم استيراد المجسم مع الحفاظ على الهيكل المدمج.'
              : 'تم استيراد المجسم؛ يحتاج إلى Rig مناسب قبل التحريك.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل استيراد GLB: $error')),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedUrl = _selectedUrl;
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF10151F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'استيراد مجسم GLB من الهاتف',
            onPressed: _importing ? null : _pickLocalGlb,
            icon: _importing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_open),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (selectedUrl != null)
            Positioned.fill(
              child: Flutter3DViewer(
                key: ValueKey(selectedUrl),
                controller: _controller,
                src: selectedUrl,
                activeGestureInterceptor: true,
                enableTouch: true,
                progressBarColor: Colors.tealAccent,
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
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.view_in_ar,
                      size: 76,
                      color: Colors.tealAccent,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'مساحة المجسمات ثلاثية الأبعاد',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'استورد ملف GLB من الهاتف لبدء الفحص والتجهيز.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _importing ? null : _pickLocalGlb,
                      icon: const Icon(Icons.file_open),
                      label: const Text('اختيار ملف GLB'),
                    ),
                  ],
                ),
              ),
            ),
          if (_importedModel != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _ImportSummary(model: _importedModel!),
            ),
          if (selectedUrl != null && _progress < 1)
            Positioned(
              left: 24,
              right: 24,
              bottom: 20,
              child: LinearProgressIndicator(value: _progress),
            ),
        ],
      ),
    );
  }
}

class _ImportSummary extends StatelessWidget {
  const _ImportSummary({required this.model});

  final ImportedGlb model;

  @override
  Widget build(BuildContext context) {
    final info = model.inspection;
    final rigStatus = info.autoRigApplied
        ? 'Auto-Rig: JOINTS عظمية'
        : info.alreadyRigged
            ? 'هيكل مدمج: JOINTS'
            : 'لم يتم تجهيز Skin';
    return Material(
      color: Colors.black.withOpacity(.78),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              model.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'MESH_COUNT Mesh • NODE_COUNT Nodes • ANIMATION_COUNT Animations'
                  .replaceFirst('MESH_COUNT', info.meshCount.toString())
                  .replaceFirst('NODE_COUNT', info.nodeCount.toString())
                  .replaceFirst('ANIMATION_COUNT', info.animationNames.length.toString()),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              rigStatus,
              style: TextStyle(
                color: info.alreadyRigged || info.autoRigApplied
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
