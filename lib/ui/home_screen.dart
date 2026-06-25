import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:gta6hub/core/simulation_provider.dart';
import 'package:gta6hub/engine/engine_integrator.dart';
import 'package:gta6hub/engine/fluids/fluid_simulator.dart';
import 'package:gta6hub/engine/fluids/fluid_emitter.dart';
import 'package:gta6hub/engine/cinematics/cinematic_impact_system.dart';
import 'package:gta6hub/engine/cinematics/motion_recorder.dart';
import 'package:gta6hub/ui/gta_hud.dart';
import 'package:gta6hub/ui/director_sandbox.dart';

class HomeScreen extends StatefulWidget {
  final EngineIntegrator engine;
  const HomeScreen({Key? key, required this.engine}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final Ticker _ticker;
  final FluidSimulator _fluidSimulator = FluidSimulator();
  final FluidEmitter _fluidEmitter = FluidEmitter();
  final MotionRecorder _motionRecorder = MotionRecorder();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final sim = Provider.of<SimulationProvider>(context, listen: false);
      double delta = elapsed.inMilliseconds / 1000.0;
      
      // تحديث المحرك الموحد
      widget.engine.update(delta, MediaQuery.of(context).size);
      
      // تحديث السوائل والفيزياء
      _fluidSimulator.update(delta);
      
      if (mounted) setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sim = Provider.of<SimulationProvider>(context);
    return Scaffold(
      body: CinematicImpactSystem(
        arousal: sim.arousal,
        currentState: sim.currentState.name,
        child: Stack(
          children: [
            Container(color: const Color(0xFF0A0A0F)),
            // طبقة الرسوم (Engine Renderer)
            Positioned.fill(
              child: CustomPaint(
                painter: _EnginePainter(engine: widget.engine, simulator: _fluidSimulator),
              ),
            ),
            // طبقة الواجهة
            const GTAHud(),
            Positioned(
              top: 40, right: 10,
              child: IconButton(
                icon: const Icon(Icons.dashboard_customize, color: Color(0xFFFF2A6D)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectorSandbox())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnginePainter extends CustomPainter {
  final EngineIntegrator engine;
  final FluidSimulator simulator;
  _EnginePainter({required this.engine, required this.simulator});

  @override
  void paint(Canvas canvas, Size size) {
    engine.render(canvas, size);
    simulator.render(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
