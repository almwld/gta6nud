import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:gta6hub/core/simulation_provider.dart';
import 'package:gta6hub/engine/body/body_manager.dart';
import 'package:gta6hub/engine/body/heatmap_renderer.dart';
import 'package:gta6hub/engine/fluids/fluid_output_system.dart';
import 'package:gta6hub/engine/cinematics/cinematic_show_system.dart';
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
  final FluidOutputSystem _fluidOutput = FluidOutputSystem();
  final CinematicShowSystem _cinematicShow = CinematicShowSystem();
  final HeatmapRenderer _heatmap = HeatmapRenderer();
  final MotionRecorder _motionRecorder = MotionRecorder();
  SimulationState _lastState = SimulationState.idle;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final sim = Provider.of<SimulationProvider>(context, listen: false);
      final bodyManager = Provider.of<BodyManager>(context, listen: false);
      double delta = elapsed.inMilliseconds / 1000.0;

      sim.update(delta);
      bodyManager.setArousal(sim.arousal / 100.0);
      bodyManager.setPleasure(sim.thrustSpeed / 100.0);
      bodyManager.update(delta);

      final screenSize = MediaQuery.of(context).size;
      _fluidOutput.update(delta, screenSize);
      _heatmap.update(delta);
      _cinematicShow.update(delta);

      if (sim.currentState == SimulationState.peak && _lastState != SimulationState.peak) {
        final origin = Offset(screenSize.width / 2, screenSize.height * 0.65);
        _fluidOutput.emitOrgasmWaves(origin: origin, direction: const Offset(0, -1), waves: 6, force: (sim.thrustSpeed / 50).clamp(0.5, 2.0), viscosity: 1.8);
        _cinematicShow.play('climax');
        bodyManager.triggerClimax();
      }
      if (_lastState == SimulationState.peak && sim.currentState != SimulationState.peak) {
        bodyManager.recover();
        _cinematicShow.play('calm');
        _fluidOutput.setGlobalViscosity(1.0);
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
    final bodyManager = Provider.of<BodyManager>(context);

    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (details) {
          bodyManager.touchAt(details.globalPosition, MediaQuery.of(context).size);
          _heatmap.addTouchPoint(details.globalPosition, intensity: 0.7 + sim.arousal / 100.0 * 0.3, radius: 35 + sim.arousal * 0.3);
          if (sim.arousal > 30 && _random.nextDouble() < 0.08) {
            _fluidOutput.emitSpray(origin: details.globalPosition, direction: Offset((_random.nextDouble() - 0.5) * 0.4, -1), force: 0.2, count: 3, spreadAngle: 0.6, color: Colors.white.withOpacity(0.4));
          }
        },
        child: Stack(
          children: [
            Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.center, colors: [Color(0xFF1A0A2E), Color(0xFF050508)], radius: 1.5))),
            Positioned.fill(child: CustomPaint(painter: _CinematicPainter(showSystem: _cinematicShow))),
            Positioned.fill(child: CustomPaint(painter: _HeatmapPainter(heatmap: _heatmap))),
            Positioned.fill(child: CustomPaint(painter: _BodyPainter(bodyManager: bodyManager))),
            Positioned.fill(child: CustomPaint(painter: _FluidPainter(system: _fluidOutput))),
            Center(
              child: Transform.scale(
                scale: _cinematicShow.zoomLevel,
                child: Transform.translate(
                  offset: _cinematicShow.applyShake(Offset.zero),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 240),
                      ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFFF2A6D), Color(0xFF00D4FF)]).createShader(bounds), child: const Text('GTA6HUB', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 12, color: Colors.white))),
                      const SizedBox(height: 15),
                      Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                        _btn('SPEED+', () => sim.setSpeedDirect((sim.thrustSpeed + 10).clamp(0, 100))),
                        _btn('SPEED-', () => sim.setSpeedDirect((sim.thrustSpeed - 10).clamp(0, 100))),
                        _btn('DEPTH+', () => sim.setDepthDirect((sim.thrustDepth + 10).clamp(0, 100))),
                        _btn('DEPTH-', () => sim.setDepthDirect((sim.thrustDepth - 10).clamp(0, 100))),
                        _btn('💦CLIMAX', () { sim.setSpeedDirect(100); sim.setDepthDirect(100); }, special: true),
                        _btn('🧹CLEAR', () { _fluidOutput.clear(); _heatmap.clear(); }),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            const GTAHud(),
            Positioned(top: 50, right: 15, child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectorSandbox())), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.5))), child: const Icon(Icons.dashboard_customize, color: Color(0xFFFF2A6D), size: 22)))),
            Positioned(bottom: 8, left: 10, child: Text('💧${_fluidOutput.activeDroplets} 🔥${_heatmap.activePoints}', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10))),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap, {bool special = false}) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: special ? const Color(0xFFFF2A6D).withOpacity(0.4) : const Color(0xFFFF2A6D).withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: special ? const Color(0xFFFF2A6D) : const Color(0xFFFF2A6D).withOpacity(0.5), width: special ? 2 : 1)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))));
  }
}

class _BodyPainter extends CustomPainter { final BodyManager bodyManager; _BodyPainter({required this.bodyManager}); @override void paint(Canvas canvas, Size size) => bodyManager.render(canvas, size); @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true; }
class _CinematicPainter extends CustomPainter { final CinematicShowSystem showSystem; _CinematicPainter({required this.showSystem}); @override void paint(Canvas canvas, Size size) => showSystem.applyEffects(canvas, size); @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true; }
class _FluidPainter extends CustomPainter { final FluidOutputSystem system; _FluidPainter({required this.system}); @override void paint(Canvas canvas, Size size) => system.render(canvas); @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true; }
class _HeatmapPainter extends CustomPainter { final HeatmapRenderer heatmap; _HeatmapPainter({required this.heatmap}); @override void paint(Canvas canvas, Size size) => heatmap.render(canvas, size); @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true; }
