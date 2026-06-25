import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:gta6hub/core/simulation_provider.dart';
import 'package:gta6hub/engine/fluids/fluid_simulator.dart';
import 'package:gta6hub/engine/fluids/fluid_emitter.dart';
import 'package:gta6hub/engine/cinematics/motion_recorder.dart';
import 'package:gta6hub/ui/gta_hud.dart';
import 'package:gta6hub/ui/director_sandbox.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final Ticker _ticker;
  final FluidSimulator _fluidSimulator = FluidSimulator();
  final FluidEmitter _fluidEmitter = FluidEmitter();
  final MotionRecorder _motionRecorder = MotionRecorder();
  SimulationState _lastState = SimulationState.idle;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final sim = Provider.of<SimulationProvider>(context, listen: false);
      double delta = elapsed.inMilliseconds / 1000.0;
      _time += delta;
      sim.update(delta);
      _fluidSimulator.update(delta);
      if (sim.currentState == SimulationState.peak && _lastState != SimulationState.peak) {
        final origin = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2);
        _fluidSimulator.emitParticles(_fluidEmitter.emitCum(origin, const Offset(0, -1), (sim.thrustSpeed / 50).clamp(0.5, 2.0)));
      }
      _lastState = sim.currentState;
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(center: Alignment.center, colors: [Color(0xFF1A0A2E), Color(0xFF050508)], radius: 1.5),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _FluidCanvasPainter(simulator: _fluidSimulator)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: 1.0 + (sim.arousal / 100) * 0.3,
                  duration: const Duration(milliseconds: 100),
                  child: Icon(Icons.local_fire_department, size: 80 + sim.arousal * 0.4, color: const Color(0xFFFF2A6D)),
                ),
                const SizedBox(height: 30),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFF2A6D), Color(0xFF00D4FF)]).createShader(bounds),
                  child: const Text('GTA6HUB', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 12, color: Colors.white)),
                ),
              ],
            ),
          ),
          const GTAHud(),
          Positioned(
            top: 50, right: 15,
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectorSandbox())),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.5))),
                child: const Icon(Icons.dashboard_customize, color: Color(0xFFFF2A6D), size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FluidCanvasPainter extends CustomPainter {
  final FluidSimulator simulator;
  _FluidCanvasPainter({required this.simulator});
  @override
  void paint(Canvas canvas, Size size) => simulator.render(canvas);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
