import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../design/spazz_theme.dart';
import '../services/auth_service.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';

const Color _magenta = Color(0xFFE83CFF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic> _prefs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await AuthService.getPreferences();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  Future<void> _toggleSpazzMode() async {
    final homeAddress = _prefs['home_address'] ?? '';
    if (homeAddress.isEmpty) {
      _showSafetyWarning(
        'Home Address Required',
        'Enter your home address in Profile to set a safe zone before starting Spazz.',
      );
      return;
    }

    final newState = !(_prefs['is_broadcasting'] ?? false);
    if (newState) {
      try {
        final position = await Geolocator.getCurrentPosition();
        final homeLat = _prefs['home_lat'] ?? 0.0;
        final homeLng = _prefs['home_lng'] ?? 0.0;
        final radius = _prefs['geofence_radius'] ?? 250.0;
        if (homeLat != 0.0 && homeLng != 0.0) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            homeLat,
            homeLng,
          );
          if (distance < radius) {
            _showSafetyWarning(
              'In Safe Zone',
              'Spazz broadcasting is disabled while you are within your Home Safe Zone.',
            );
            return;
          }
        }
      } catch (_) {}
    }

    await AuthService.updatePreferences(isBroadcasting: newState);
    if (!mounted) return;
    setState(() => _prefs['is_broadcasting'] = newState);
  }

  void _showSafetyWarning(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SpazzTheme.bgSecondary,
        title: Row(
          children: [
            const Icon(Icons.security, color: SpazzTheme.errorRed),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: SpazzTheme.errorRed)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: SpazzTheme.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          if (title == 'Home Address Required')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
              child: const Text('Go to Profile'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardTab(
        loading: _loading,
        isBroadcasting: _prefs['is_broadcasting'] ?? false,
        onStart: () => context.go('/hunt'),
        onToggleSpazz: _toggleSpazzMode,
      ),
      const FriendsScreen(),
      const ShopScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050609),
      body: screens[_currentIndex],
      bottomNavigationBar: _LensNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final bool loading;
  final bool isBroadcasting;
  final VoidCallback onStart;
  final VoidCallback onToggleSpazz;

  const _DashboardTab({
    required this.loading,
    required this.isBroadcasting,
    required this.onStart,
    required this.onToggleSpazz,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          const Positioned.fill(child: _LensBackdrop()),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleLensButton(icon: Icons.search, onTap: () {}),
                    const _SpazzMark(),
                    _CircleLensButton(icon: Icons.menu, onTap: () {}),
                  ],
                ),
                const SizedBox(height: 18),
                _StartSpazzButton(
                  loading: loading,
                  isBroadcasting: isBroadcasting,
                  onTap: onStart,
                ),
                const Spacer(),
                _RadarLensEmblem(isActive: isBroadcasting),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SignalChip(
                      icon: Icons.bolt,
                      label: isBroadcasting ? 'SIGNAL LIVE' : 'READY TO ROAM',
                      color: isBroadcasting ? _magenta : SpazzTheme.accentCyan,
                    ),
                    const SizedBox(width: 8),
                    _SignalChip(
                      icon: Icons.radar,
                      label: 'LIVE MAP',
                      color: SpazzTheme.accentCyan,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onToggleSpazz,
                  icon: Icon(
                    isBroadcasting ? Icons.stop_circle_outlined : Icons.radio_button_checked,
                    size: 17,
                  ),
                  label: Text(isBroadcasting ? 'Pause signal' : 'Enable signal'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LensBackdrop extends StatelessWidget {
  const _LensBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LensBackdropPainter());
  }
}

class _LensBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF06070A);
    canvas.drawRect(Offset.zero & size, background);

    final horizon = size.height * 0.45;
    final roadPaint = Paint()
      ..color = const Color(0xFF101425)
      ..style = PaintingStyle.fill;
    final road = Path()
      ..moveTo(size.width * 0.40, size.height)
      ..lineTo(size.width * 0.46, horizon)
      ..lineTo(size.width * 0.54, horizon)
      ..lineTo(size.width * 0.64, size.height)
      ..close();
    canvas.drawPath(road, roadPaint);

    final linePaint = Paint()
      ..color = SpazzTheme.accentCyan.withValues(alpha: 0.56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 7; i++) {
      final y = horizon + (size.height - horizon) * (i / 7);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (var i = -2; i <= 12; i++) {
      final x = size.width * (i / 10);
      canvas.drawLine(Offset(size.width * 0.5, horizon), Offset(x, size.height), linePaint);
    }

    final buildingPaint = Paint()..color = const Color(0xFF171331);
    for (var i = 0; i < 8; i++) {
      final left = i.isEven ? 0.0 : size.width * 0.78;
      final width = size.width * (0.12 + (i % 3) * 0.04);
      final top = horizon - 20 - (i % 4) * 22;
      canvas.drawRect(Rect.fromLTWH(left, top, width, size.height - top), buildingPaint);
    }

    final glow = Paint()
      ..color = _magenta.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.33), 90, glow);

    final cyan = Paint()
      ..color = SpazzTheme.accentCyan.withValues(alpha: 0.65)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(size.width * 0.06, horizon + 45), Offset(size.width * 0.36, horizon + 45), cyan);
    canvas.drawLine(Offset(size.width * 0.68, horizon + 20), Offset(size.width * 0.96, horizon + 20), cyan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpazzMark extends StatelessWidget {
  const _SpazzMark();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 190,
          height: 112,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(color: _magenta.withValues(alpha: 0.25), blurRadius: 28),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(
                left: 20,
                top: 16,
                child: Icon(Icons.bolt, color: SpazzTheme.accentCyan, size: 24),
              ),
              const Positioned(
                right: 18,
                top: 12,
                child: Icon(Icons.bolt, color: SpazzTheme.accentCyan, size: 20),
              ),
              const Positioned(
                left: 30,
                bottom: 12,
                child: Icon(Icons.bolt, color: SpazzTheme.accentCyan, size: 18),
              ),
              Icon(Icons.bolt, size: 82, color: _magenta.withValues(alpha: 0.9)),
              Text(
                'SPAZZ',
                style: TextStyle(
                  color: _magenta,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: SpazzTheme.accentCyan, blurRadius: 14),
                    Shadow(color: _magenta, blurRadius: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleLensButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleLensButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white70),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        shape: const CircleBorder(),
        fixedSize: const Size(52, 52),
      ),
    );
  }
}

class _StartSpazzButton extends StatelessWidget {
  final bool loading;
  final bool isBroadcasting;
  final VoidCallback onTap;

  const _StartSpazzButton({required this.loading, required this.isBroadcasting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 280,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: SpazzTheme.accentCyan, width: 2),
          boxShadow: [
            BoxShadow(color: SpazzTheme.accentCyan.withValues(alpha: 0.32), blurRadius: 18),
          ],
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isBroadcasting ? Icons.radar : Icons.play_arrow, color: SpazzTheme.accentCyan),
                  const SizedBox(width: 8),
                  Text(
                    isBroadcasting ? 'OPEN LIVE RADAR' : 'START SPAZZ',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.8),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SignalChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

class _RadarLensEmblem extends StatefulWidget {
  final bool isActive;

  const _RadarLensEmblem({required this.isActive});

  @override
  State<_RadarLensEmblem> createState() => _RadarLensEmblemState();
}

class _RadarLensEmblemState extends State<_RadarLensEmblem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isActive ? SpazzTheme.accentCyan : _magenta;
    return AnimatedScale(
      scale: widget.isActive ? 1 : 0.78,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: 190,
        height: 116,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulse = widget.isActive
                ? 0.9 + (0.1 * (0.5 + 0.5 * math.sin(_controller.value * math.pi * 2)))
                : 0.72;
            return CustomPaint(
              painter: _RadarLensPainter(
                progress: _controller.value,
                accent: accent,
                pulse: pulse,
                isActive: widget.isActive,
              ),
              child: child,
            );
          },
          child: Center(
            child: Transform.rotate(
              angle: -0.1,
              child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 34),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarLensPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final double pulse;
  final bool isActive;

  const _RadarLensPainter({
    required this.progress,
    required this.accent,
    required this.pulse,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = 35.0 * pulse;
    final ring = Paint()
      ..color = accent.withValues(alpha: isActive ? 0.92 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 3 : 2;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(
      center,
      radius + (isActive ? 10 : 5),
      ring..color = accent.withValues(alpha: isActive ? 0.2 : 0.1),
    );

    final sweep = progress * math.pi * 2;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [accent.withValues(alpha: 0), accent, accent.withValues(alpha: 0)],
        startAngle: sweep,
        endAngle: sweep + math.pi * 1.15,
      ).createShader(Rect.fromCircle(center: center, radius: radius + 8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 8),
      sweep,
      math.pi * 1.2,
      false,
      sweepPaint,
    );

    if (!isActive) return;
    final sparkPaint = Paint()
      ..color = _magenta.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 8; index++) {
      final angle = (math.pi * 2 * index / 8) + sweep;
      final inner = radius + 15;
      final length = 5 + (math.sin((progress + index) * math.pi * 2).abs() * 8);
      final start = Offset(center.dx + math.cos(angle) * inner, center.dy + math.sin(angle) * inner);
      final end = Offset(center.dx + math.cos(angle) * (inner + length), center.dy + math.sin(angle) * (inner + length));
      canvas.drawLine(start, end, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarLensPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isActive != isActive;
}

class _LensNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LensNavigationBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF06070A).withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: SpazzTheme.accentCyan,
        unselectedItemColor: Colors.white.withValues(alpha: 0.3),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
