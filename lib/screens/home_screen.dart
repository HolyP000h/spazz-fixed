import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../design/spazz_theme.dart';
import '../services/auth_service.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _prefs = {};
  List<dynamic> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    
    // Load preferences for broadcasting state
    final prefs = await AuthService.getPreferences();

    // --- DEVELOPMENT MOCK OVERRIDE ---
    await Future.delayed(const Duration(milliseconds: 250));

    if (mounted) {
      class _DashboardTab extends StatelessWidget {
        final Map<String, dynamic> userData;
        final Map<String, dynamic> prefs;
        final List<dynamic> leaderboard;
        final bool loading;
        final VoidCallback onRefresh;
        final VoidCallback onToggleSpazz;

        const _DashboardTab({
          required this.userData,
          required this.prefs,
          required this.leaderboard,
          required this.loading,
          required this.onRefresh,
          required this.onToggleSpazz,
        });

        @override
        Widget build(BuildContext context) {
          final username = userData['username'] ?? 'Spazzer';
          final wispCoins = userData['wisp_coins'] ?? 0;
          final isBroadcasting = prefs['is_broadcasting'] ?? false;

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final headerButtonSize = (width * 0.11).clamp(34.0, 48.0);
              final startButtonHeight = (width * 0.14).clamp(48.0, 60.0);
              final navPad = (width * 0.025).clamp(8.0, 16.0);
              final cityHeight = (constraints.maxHeight * 0.72).clamp(280.0, 560.0);
              final bottomDock = (width * 0.15).clamp(52.0, 68.0);
              final bottomDockOffset = (width * 0.11).clamp(18.0, 38.0);

              return SafeArea(
                child: loading
                    ? const Center(child: CircularProgressIndicator(color: SpazzTheme.accentPurple))
                    : Padding(
                        padding: EdgeInsets.all((width * 0.03).clamp(8.0, 12.0)),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: headerButtonSize,
                                  height: headerButtonSize,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D1E2A),
                                    borderRadius: BorderRadius.circular(headerButtonSize / 2),
                                  ),
                                  child: Icon(Icons.search, color: SpazzTheme.textPrimary, size: headerButtonSize * 0.52),
                                ),
                                const Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: navPad * 1.6, vertical: navPad * 0.8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: SpazzTheme.gradientPrimary,
                                  ),
                                  child: Text(
                                    'SPAZZ',
                                    style: SpazzTheme.heading3.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: headerButtonSize,
                                  height: headerButtonSize,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D1E2A),
                                    borderRadius: BorderRadius.circular(headerButtonSize / 2),
                                  ),
                                  child: Icon(Icons.menu, color: SpazzTheme.textPrimary, size: headerButtonSize * 0.52),
                                ),
                              ],
                            ),
                            SizedBox(height: (width * 0.03).clamp(10.0, 16.0)),
                            GestureDetector(
                              onTap: onToggleSpazz,
                              child: Container(
                                width: double.infinity,
                                height: startButtonHeight,
                                decoration: BoxDecoration(
                                  color: isBroadcasting ? SpazzTheme.accentPurple : const Color(0xFF1A1B2D),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: SpazzTheme.accentCyan, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, color: isBroadcasting ? Colors.white : SpazzTheme.accentCyan, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'START SPAZZ',
                                      style: TextStyle(
                                        color: isBroadcasting ? Colors.white : SpazzTheme.accentCyan,
                                        fontSize: (width * 0.045).clamp(14.0, 18.0),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: (width * 0.03).clamp(10.0, 16.0)),
                            Expanded(
                              child: Container(
                                height: cityHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF060712),
                                      Color(0xFF110B2B),
                                      Color(0xFF1A0F35),
                                    ],
                                  ),
                                  border: Border.all(color: const Color(0xFF342A63), width: 2),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withValues(alpha: 0.2),
                                              Colors.black.withValues(alpha: 0.55),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 24, left: 18, right: 18, bottom: 18),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                children: List.generate(7, (index) {
                                                  return Expanded(
                                                    child: Container(
                                                      margin: const EdgeInsets.only(right: 8, bottom: 8),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF171327).withValues(alpha: 0.8),
                                                        border: Border.all(color: const Color(0xFF4A3C8A).withValues(alpha: 0.3)),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                children: List.generate(6, (index) {
                                                  return Expanded(
                                                    child: Container(
                                                      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF160F2C).withValues(alpha: 0.8),
                                                        border: Border.all(color: const Color(0xFF4A3C8A).withValues(alpha: 0.3)),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                children: List.generate(7, (index) {
                                                  return Expanded(
                                                    child: Container(
                                                      margin: const EdgeInsets.only(left: 8, bottom: 8),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF1B1431).withValues(alpha: 0.8),
                                                        border: Border.all(color: const Color(0xFF4A3C8A).withValues(alpha: 0.3)),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        height: 200,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Color(0xFF1C1033),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 25,
                                      right: 25,
                                      bottom: 40,
                                      child: Container(
                                        height: 130,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(26),
                                          border: Border.all(color: const Color(0xFF6FE7FF), width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6FE7FF).withValues(alpha: 0.45),
                                              blurRadius: 14,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 90,
                                      right: 90,
                                      bottom: 75,
                                      child: Container(
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6FE7FF).withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 18,
                                      left: 18,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1B2D),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF5CE7FF), width: 1),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.bolt, color: SpazzTheme.accentPurple, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$wispCoins',
                                              style: const TextStyle(
                                                color: SpazzTheme.textPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 18,
                                      right: 18,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1B2D),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF7A6CFF), width: 1),
                                        ),
                                        child: Text(
                                          username,
                                          style: const TextStyle(color: SpazzTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 24,
                                      left: 24,
                                      child: Container(
                                        width: bottomDock,
                                        height: bottomDock,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D1E2A),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFF6FE7FF), width: 2),
                                        ),
                                        child: const Icon(Icons.home_rounded, color: SpazzTheme.accentCyan),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 24,
                                      left: bottomDock + bottomDockOffset,
                                      child: Container(
                                        width: bottomDock,
                                        height: bottomDock,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D1E2A),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFF8B8EA6), width: 2),
                                        ),
                                        child: const Icon(Icons.inventory_2_rounded, color: SpazzTheme.textSecondary),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 24,
                                      right: bottomDock + bottomDockOffset,
                                      child: Container(
                                        width: bottomDock,
                                        height: bottomDock,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D1E2A),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFF8B8EA6), width: 2),
                                        ),
                                        child: const Icon(Icons.people_alt_rounded, color: SpazzTheme.textSecondary),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 24,
                                      right: 24,
                                      child: Container(
                                        width: bottomDock,
                                        height: bottomDock,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D1E2A),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFF8B8EA6), width: 2),
                                        ),
                                        child: const Icon(Icons.person_rounded, color: SpazzTheme.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            },
          );
        }
      }
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.2),
                                        Colors.black.withValues(alpha: 0.55),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 24, left: 18, right: 18, bottom: 18),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: List.generate(7, (index) {
                                            return Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.only(right: 8, bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF171327).withValues(alpha: 0.8),
                                                  border: Border.all(color: const Color(0xFF4A3C8A).withValues(alpha: 0.3)),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: List.generate(6, (index) {
                                            return Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF160F2C).withValues(alpha: 0.8),
                                                  border: Border.all(color: const Color(0xFF4A3C8A).withValues(alpha: 0.3)),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: List.generate(7, (index) {
                                            return Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.only(left: 8, bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1B1431).withValues(alpha: 0.8),
                                                  border: Border.all(color: const Color(0xFF4A3C8A).withValues(alpha: 0.3)),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  height: 200,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF1C1033),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 25,
                                right: 25,
                                bottom: 40,
                                child: Container(
                                  height: 130,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(color: const Color(0xFF6FE7FF), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6FE7FF).withValues(alpha: 0.45),
                                        blurRadius: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 90,
                                right: 90,
                                bottom: 75,
                                child: Container(
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6FE7FF).withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 18,
                                left: 18,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1B2D),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF5CE7FF), width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.bolt, color: SpazzTheme.accentPurple, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$wispCoins',
                                        style: const TextStyle(
                                          color: SpazzTheme.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 18,
                                right: 18,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1B2D),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF7A6CFF), width: 1),
                                  ),
                                  child: Text(
                                    username,
                                    style: const TextStyle(color: SpazzTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 24,
                                left: 24,
                                child: Container(
                                  width: bottomDock,
                                  height: bottomDock,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D1E2A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF6FE7FF), width: 2),
                                  ),
                                  child: const Icon(Icons.home_rounded, color: SpazzTheme.accentCyan),
                                ),
                              ),
                              Positioned(
                                bottom: 24,
                                left: bottomDock + bottomDockOffset,
                                child: Container(
                                  width: bottomDock,
                                  height: bottomDock,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D1E2A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF8B8EA6), width: 2),
                                  ),
                                  child: const Icon(Icons.inventory_2_rounded, color: SpazzTheme.textSecondary),
                                ),
                              ),
                              Positioned(
                                bottom: 24,
                                right: bottomDock + bottomDockOffset,
                                child: Container(
                                  width: bottomDock,
                                  height: bottomDock,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D1E2A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF8B8EA6), width: 2),
                                  ),
                                  child: const Icon(Icons.people_alt_rounded, color: SpazzTheme.textSecondary),
                                ),
                              ),
                              Positioned(
                                bottom: 24,
                                right: 24,
                                child: Container(
                                  width: bottomDock,
                                  height: bottomDock,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D1E2A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF8B8EA6), width: 2),
                                  ),
                                  child: const Icon(Icons.person_rounded, color: SpazzTheme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
          },
        );
    }
}
