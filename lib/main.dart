import 'package:flutter/material.dart';

import 'package:gta6hub/ui/model_viewer_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GTA6App());
}

class GTA6App extends StatelessWidget {
  const GTA6App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GTA6HUB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A8F83),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080B12),
      ),
      home: const ModelViewerScreen(),
    );
  }
}
