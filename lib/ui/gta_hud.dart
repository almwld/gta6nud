import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gta6hub/core/simulation_provider.dart';

class GTAHud extends StatelessWidget {
  const GTAHud({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sim = Provider.of<SimulationProvider>(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _hudCard('STATUS', sim.currentState.name.toUpperCase(), sim.currentState == SimulationState.peak ? const Color(0xFFFF2A6D) : const Color(0xFF00D4FF)),
                const SizedBox(width: 8),
                _hudCard('SPEED', '${sim.thrustSpeed.toInt()}', Colors.orange),
                const SizedBox(width: 8),
                _hudCard('DEPTH', '${sim.thrustDepth.toInt()}', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
