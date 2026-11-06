import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gauge semicircular (arco de 180°) con el texto del avance al centro.
class GaugeMeta extends StatelessWidget {
  final double fraccion;
  final String texto;

  const GaugeMeta({super.key, required this.fraccion, required this.texto});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2,
      child: CustomPaint(
        painter: _GaugePainter(
          fraccion: fraccion.clamp(0.0, 1.0).toDouble(),
          colorFondo: Colors.grey.shade300,
          colorAvance: fraccion >= 1 ? Colors.green : Colors.red,
        ),
        child: Align(
          alignment: const Alignment(0, 0.6),
          child: Text(
            texto,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraccion;
  final Color colorFondo;
  final Color colorAvance;

  _GaugePainter({
    required this.fraccion,
    required this.colorFondo,
    required this.colorAvance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 24.0;
    final radio = math.min(size.width / 2, size.height) - grosor / 2;
    final centro = Offset(size.width / 2, size.height);
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, pincel..color = colorFondo);
    if (fraccion > 0) {
      canvas.drawArc(
          rect, math.pi, math.pi * fraccion, false, pincel..color = colorAvance);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraccion != fraccion ||
      old.colorFondo != colorFondo ||
      old.colorAvance != colorAvance;
}
