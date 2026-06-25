import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/simulation_provider.dart';
import 'core/pleasure_manager.dart';
import 'engine/engine_integrator.dart';
import 'engine/body/body_renderer.dart';
import 'engine/body/body_animation_controller.dart';
import 'engine/body/body_physics_controller.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SimulationProvider()),
      ],
      child: const GTA6App(),
    ),
  );
}

class GTA6App extends StatelessWidget {
  const GTA6App({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // بناء المحرك الموحد
    final engine = EngineIntegrator(
      manager: PleasureManager(),
      renderer: BodyRenderer(),
      animation: BodyAnimationController(),
      physics: BodyPhysicsController(),
    );

    return MaterialApp(
      title: 'gta6hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        primaryColor: const Color(0xFFFF2A6D),
      ),
      // نمرر المحرك الآن إلى الواجهة
      home: HomeScreen(engine: engine),
    );
  }
}
