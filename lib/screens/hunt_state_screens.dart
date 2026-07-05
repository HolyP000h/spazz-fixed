import 'package:flutter/material.dart';
import '../design/spazz_theme.dart';

/// Hunt state screens representing different phases of the hunting experience
/// These correspond to the Figma designs: screen-hunt-warm, screen-hunt-cold, etc.

class HuntWarmScreen extends StatefulWidget {
  final String targetUsername;
  final double distance;
  final bool isMovingTowardTarget;

  const HuntWarmScreen({
    super.key,
    required this.targetUsername,
    required this.distance,
    required this.isMovingTowardTarget,
  });

  @override
  State<HuntWarmScreen> createState() => _HuntWarmScreenState();
}

class _HuntWarmScreenState extends State<HuntWarmScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Radar visualization
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: SpazzTheme.accentOrange.withValues(alpha: 0.3), width: 2),
                  ),
                ),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: SpazzTheme.accentOrange.withValues(alpha: 0.5), width: 1.5),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: SpazzTheme.accentOrange.withValues(alpha: 0.7), width: 1),
                  ),
                ),
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.2).animate(_pulseController),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SpazzTheme.gradientWarm,
                      boxShadow: [
                        BoxShadow(
                          color: SpazzTheme.accentOrange.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text('🎯', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              '🔥 GETTING WARM 🔥',
              style: SpazzTheme.heading2.copyWith(
                color: SpazzTheme.accentOrange,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.targetUsername,
              style: SpazzTheme.heading3.copyWith(
                color: SpazzTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: SpazzTheme.bgSecondary,
                borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                border: Border.all(color: SpazzTheme.accentOrange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '${widget.distance.toStringAsFixed(1)} meters away',
                    style: SpazzTheme.subtitle1.copyWith(
                      color: SpazzTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isMovingTowardTarget ? '✓ Moving toward target' : '↻ Adjusting course',
                    style: SpazzTheme.bodySmall.copyWith(
                      color: widget.isMovingTowardTarget ? SpazzTheme.successGreen : SpazzTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SpazzTheme.bgSecondary,
                    foregroundColor: SpazzTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_location),
                  label: const Text('Lock On'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SpazzTheme.accentOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HuntColdScreen extends StatelessWidget {
  final String targetUsername;
  final double distance;

  const HuntColdScreen({
    super.key,
    required this.targetUsername,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Radar visualization - fading/cold
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: SpazzTheme.coldBlue.withValues(alpha: 0.2), width: 2),
                  ),
                ),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: SpazzTheme.coldBlue.withValues(alpha: 0.3), width: 1.5),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: SpazzTheme.coldBlue.withValues(alpha: 0.4), width: 1),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SpazzTheme.gradientCold,
                    boxShadow: [
                      BoxShadow(
                        color: SpazzTheme.coldBlue.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text('❄️', style: TextStyle(fontSize: 40)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              '❄️ GETTING COLD ❄️',
              style: SpazzTheme.heading2.copyWith(
                color: SpazzTheme.coldBlue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              targetUsername,
              style: SpazzTheme.heading3,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: SpazzTheme.bgSecondary,
                borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                border: Border.all(color: SpazzTheme.coldBlue.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    '${distance.toStringAsFixed(1)} meters away',
                    style: SpazzTheme.subtitle1.copyWith(
                      color: SpazzTheme.coldBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '↻ Wrong direction - adjust course',
                    style: SpazzTheme.bodySmall.copyWith(
                      color: SpazzTheme.warningYellow,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Exit Hunt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SpazzTheme.bgSecondary,
                foregroundColor: SpazzTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HuntDetectedScreen extends StatefulWidget {
  final String detectedUsername;
  final bool isPremium;

  const HuntDetectedScreen({
    super.key,
    required this.detectedUsername,
    required this.isPremium,
  });

  @override
  State<HuntDetectedScreen> createState() => _HuntDetectedScreenState();
}

class _HuntDetectedScreenState extends State<HuntDetectedScreen> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.5, end: 1.0).animate(_blinkController),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SpazzTheme.gradientPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: SpazzTheme.accentPurple.withValues(alpha: 0.6),
                      blurRadius: 24,
                      spreadRadius: 8,
                    )
                  ],
                ),
                child: const Center(
                  child: Text('📍', style: TextStyle(fontSize: 60)),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              '🎯 DETECTED 🎯',
              style: SpazzTheme.heading2.copyWith(
                color: SpazzTheme.accentPurple,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isPremium)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text('👑', style: TextStyle(fontSize: 24)),
                  ),
                Text(
                  widget.detectedUsername,
                  style: SpazzTheme.heading3,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: SpazzTheme.bgSecondary,
                borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                border: Border.all(color: SpazzTheme.accentPurple.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'A user has been detected nearby!\nSend a ping or start a connection request.',
                textAlign: TextAlign.center,
                style: SpazzTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Dismiss'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SpazzTheme.bgSecondary,
                    foregroundColor: SpazzTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.location_on),
                  label: const Text('Send Ping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SpazzTheme.accentPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HuntConnectionScreen extends StatefulWidget {
  final String connectedUsername;
  final bool isPremium;

  const HuntConnectionScreen({
    super.key,
    required this.connectedUsername,
    required this.isPremium,
  });

  @override
  State<HuntConnectionScreen> createState() => _HuntConnectionScreenState();
}

class _HuntConnectionScreenState extends State<HuntConnectionScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SpazzTheme.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: SpazzTheme.accentPurple.withValues(alpha: 0.8),
                    blurRadius: 32,
                    spreadRadius: 12,
                  )
                ],
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 60)),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              '🔗 CONNECTED 🔗',
              style: SpazzTheme.heading2.copyWith(
                color: SpazzTheme.accentCyan,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isPremium)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text('👑', style: TextStyle(fontSize: 24)),
                  ),
                Text(
                  widget.connectedUsername,
                  style: SpazzTheme.heading3,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: SpazzTheme.bgSecondary,
                borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                border: Border.all(color: SpazzTheme.accentCyan.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'You\'ve established a connection!\nYou\'re now visible to each other on the map.',
                textAlign: TextAlign.center,
                style: SpazzTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 32),
            if (!_confirmed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SpazzTheme.bgSecondary,
                      foregroundColor: SpazzTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _confirmed = true),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirm'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Text(
                    '✓ Connection Confirmed',
                    style: TextStyle(color: SpazzTheme.successGreen, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Start Chatting'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
