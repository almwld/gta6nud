import 'package:flutter/material.dart';

class DirectorSandbox extends StatefulWidget {
  const DirectorSandbox({Key? key}) : super(key: key);
  @override
  State<DirectorSandbox> createState() => _DirectorSandboxState();
}

class _DirectorSandboxState extends State<DirectorSandbox> {
  final List<_Node> _nodes = [];
  Offset _panOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(title: const Text('DIRECTOR SANDBOX'), backgroundColor: Colors.black, elevation: 0),
      body: GestureDetector(
        onPanUpdate: (d) => setState(() => _panOffset += d.delta),
        child: Stack(
          children: [
            CustomPaint(painter: _GridPainter(offset: _panOffset)),
            ..._nodes.map((n) => Positioned(left: n.x + _panOffset.dx, top: n.y + _panOffset.dy, child: _buildNode(n))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF2A6D),
        onPressed: () => setState(() => _nodes.add(_Node('Action ${_nodes.length + 1}', _panOffset.dx + 200, _panOffset.dy + 300))),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNode(_Node node) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.6))),
      child: Text(node.label, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _Node {
  String label;
  double x, y;
  _Node(this.label, this.x, this.y);
}

class _GridPainter extends CustomPainter {
  final Offset offset;
  _GridPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00D4FF).withOpacity(0.08)..strokeWidth = 0.5;
    for (double x = (offset.dx % 40); x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = (offset.dy % 40); y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.offset != offset;
}
