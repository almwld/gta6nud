import 'package:flutter/material.dart';

import '../core/quality_settings.dart';

class QualitySettingsPanel extends StatefulWidget {
  const QualitySettingsPanel({
    super.key,
    this.initial = QualitySettings.defaults,
    this.onChanged,
  });

  final QualitySettings initial;
  final ValueChanged<QualitySettings>? onChanged;

  @override
  State<QualitySettingsPanel> createState() => _QualitySettingsPanelState();
}

class _QualitySettingsPanelState extends State<QualitySettingsPanel> {
  late QualitySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  Future<void> _select(QualityLevel level) async {
    final next = await _settings.select(level);
    if (!mounted) return;
    setState(() => _settings = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Graphics quality'),
        const SizedBox(height: 8),
        SegmentedButton<QualityLevel>(
          segments: const [
            ButtonSegment(value: QualityLevel.low, label: Text('Low')),
            ButtonSegment(value: QualityLevel.medium, label: Text('Medium')),
            ButtonSegment(value: QualityLevel.high, label: Text('High')),
          ],
          selected: {_settings.level},
          onSelectionChanged: (values) {
            if (values.isNotEmpty) _select(values.first);
          },
        ),
      ],
    );
  }
}
