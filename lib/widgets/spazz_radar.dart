import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/spazz_theme.dart';

class SpazzRadar extends StatefulWidget {
  final double intensity; // 0.0 to 1.0 (1.0 is closest)
  final bool showLightning;
  final double heading; // in degrees

  const SpazzRadar({
    super.key,
    required this.intensity,
    required this.showLightning,
    this.heading = 0,
  });

  @override
  State<SpazzRadar> createState() => _SpazzRadarState();
}

class _SpazzRadarState extends State<SpazzRadar> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didUpdateWidget(SpazzRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Speed up pulses as intensity increases
    final newDuration = Duration(milliseconds: (1500 - (widget.intensity * 1200)).toInt().clamp(300, 1500));
    if (_pulseController.duration != newDuration) {
      _pulseController.duration = newDuration;
      if (_pulseController.isAnimating) _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(300, 300),
          painter: RadarPainter(
            pulseProgress: _pulseController.value,
            intensity: widget.intensity,
            showLightning: widget.showLightning,
            heading: widget.heading,
          ),
        );
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  final double pulseProgress;
  final double intensity;
  final bool showLightning;
  final double heading;

  RadarPainter({
    required this.pulseProgress,
    required this.intensity,
    required this.showLightning,
    required this.heading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 1. Draw Static Rings
    for (int i = 1; i <= 3; i++) {
      paint.color = SpazzTheme.accentPurple.withValues(alpha: 0.1 * i);
      canvas.drawCircle(center, maxRadius * (i / 3), paint);
    }

    // 2. Draw Pulsing Wave
    final pulseRadius = maxRadius * pulseProgress;
    final pulseOpacity = (1.0 - pulseProgress).clamp(0.0, 1.0);
    paint.color = SpazzTheme.accentCyan.withValues(alpha: pulseOpacity * (0.3 + intensity * 0.7));
    paint.strokeWidth = 4.0 + (intensity * 6.0);
    canvas.drawCircle(center, pulseRadius, paint);

    // 3. Draw Player Arrow (centered)
    final arrowPath = Path();
    const arrowSize = 20.0;
    
    // Rotate canvas for heading if needed, but usually the arrow is static 
    // and the map rotates under it in 1st person.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // canvas.rotate(heading * math.pi / 180); // If map is static
    
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    arrowPath.moveTo(0, -arrowSize);
    arrowPath.lineTo(arrowSize * 0.8, arrowSize * 0.8);
    arrowPath.lineTo(0, arrowSize * 0.4);
    arrowPath.lineTo(-arrowSize * 0.8, arrowSize * 0.8);
    arrowPath.close();

    // Glow for arrow
    final glowPaint = Paint()
      ..color = SpazzTheme.accentPurple.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(arrowPath, glowPaint);
    canvas.drawPath(arrowPath, arrowPaint);
    canvas.restore();

    // 4. Draw Lightning Bolts (if intensity is high)
    if (showLightning || intensity > 0.8) {
      _drawLightning(canvas, center, maxRadius);
    }
  }

  void _drawLightning(Canvas canvas, Offset center, double maxRadius) {
    final random = math.Random((DateTime.now().millisecondsSinceEpoch / 100).floor());
    final boltCount = (intensity * 5).toInt().clamp(1, 5);
    
    final boltPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = SpazzTheme.accentCyan
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (int i = 0; i < boltCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final start = Offset(
        center.dx + math.cos(angle) * (maxRadius * 0.2),
        center.dy + math.sin(angle) * (maxRadius * 0.2),
      );
      
      var current = start;
      final segments = 4;
      final segmentLen = maxRadius * 0.2;
      
      final path = Path();
      path.moveTo(current.dx, current.dy);
      
      for (int j = 0; j < segments; j++) {
        final nextAngle = angle + (random.nextDouble() - 0.5) * 1.0;
        current = Offset(
          current.dx + math.cos(nextAngle) * segmentLen,
          current.dy + math.sin(nextAngle) * segmentLen,
        );
        path.lineTo(current.dx, current.dy);
      }
      
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, boltPaint);
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}
