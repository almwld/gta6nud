import 'package:flutter/material.dart';

import '../../core/attributions.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credits & Attributions'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: Attributions.all.length,
        separatorBuilder: (_, __) => const Divider(height: 32),
        itemBuilder: (context, index) {
          final attr = Attributions.all[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.attribution),
              title: Text(attr.assetName),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText(
                  'Author: ${attr.author}\n'
                  'License: ${attr.license}\n'
                  'Source: ${attr.sourceUrl}'
                  '${attr.modifications == null ? '' : '\nModifications: ${attr.modifications}'}',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
