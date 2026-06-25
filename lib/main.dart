import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gta6hub/core/simulation_provider.dart';
import 'package:gta6hub/ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SimulationProvider(),
      child: const GTA6App(),
    ),
  );
}

class GTA6App extends StatelessWidget {
  const GTA6App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GTA6HUB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF2A6D),
        scaffoldBackgroundColor: const Color(0xFF050508),
      ),
      home: const HomeScreen(),
    );
  }
}
