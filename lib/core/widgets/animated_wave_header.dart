import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedWaveHeader extends StatefulWidget {
  final double height;
  final Color baseColor;

  const AnimatedWaveHeader({
    super.key,
    this.height = 220,
    this.baseColor = const Color(0xFF871DAD),
  });

  @override
  State<AnimatedWaveHeader> createState() => _AnimatedWaveHeaderState();
}

class _AnimatedWaveHeaderState extends State<AnimatedWaveHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 8 second complete cycle for smooth ambient motion
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: WavePainter(
            animationValue: _controller.value,
            baseColor: widget.baseColor,
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final Color baseColor;

  WavePainter({required this.animationValue, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill the top safely so it doesnt tear
    final paintBase = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height - 60),
      paintBase,
    );

    void drawWaveLayer({
      required double heightOffset,
      required double amplitude,
      required double frequency,
      required double phaseShift,
      required Color color,
    }) {
      final path = Path();

      for (double x = 0; x <= size.width; x++) {
        double y =
            size.height -
            heightOffset +
            amplitude *
                math.sin(
                  (x / size.width) * frequency * math.pi * 2 + phaseShift,
                );
        if (x == 0) {
          path.moveTo(0, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Close path upward
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();

      final layerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, layerPaint);
    }

    // Layer 1 (Back, darker element moving right to left)
    // Create a darker shade of the base color
    final HSLColor hsl = HSLColor.fromColor(baseColor);
    final Color darkerColor = hsl
        .withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
        .toColor();

    drawWaveLayer(
      heightOffset: 25,
      amplitude: 15,
      frequency: 1.5,
      phaseShift: animationValue * math.pi * 2,
      color: darkerColor,
    );

    // Layer 2 (Middle, semi-transparent white moving left to right)
    drawWaveLayer(
      heightOffset: 35,
      amplitude: 20,
      frequency: 1.2,
      phaseShift: -animationValue * math.pi * 2 * 1.3,
      color: Colors.white.withValues(alpha: 0.15),
    );

    // Layer 3 (Front, base color moving organically)
    drawWaveLayer(
      heightOffset: 45,
      amplitude: 14,
      frequency: 2.0,
      phaseShift: animationValue * math.pi * 2 * 0.8 + math.pi,
      color: baseColor,
    );
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor;
}
