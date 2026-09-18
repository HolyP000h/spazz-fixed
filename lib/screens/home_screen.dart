import 'package:flutter/material.dart';
import '../design/spazz_theme.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _prefs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);

    // Fetch account & preference data safely
    final prefs = await AuthService.getPreferences();

    // Simulated async delay
    await Future.delayed(const Duration(milliseconds: 250));

    if (mounted) {
      setState(() {
        _prefs = prefs ?? {};
        _userData = {
          'username': 'Spazzer',
          'wisp_coins': 120,
        };
        _loading = false;
      });
    }
  }

  void _toggleSpazz() {
    setState(() {
      _prefs['is_broadcasting'] = !(_prefs['is_broadcasting'] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = _userData['username'] ?? 'Spazzer';
    final wispCoins = _userData['wisp_coins'] ?? 0;
    final isBroadcasting = _prefs['is_broadcasting'] ?? false;

    return Scaffold(
      backgroundColor: SpazzTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final headerButtonSize = (width * 0.11).clamp(34.0, 48.0);
          final startButtonHeight = (width * 0.14).clamp(48.0, 60.0);
          final navPad = (width * 0.025).clamp(8.0, 16.0);
          final cityHeight = (constraints.maxHeight * 0.72).clamp(280.0, 560.0);
          final bottomDock = (width * 0.15).clamp(52.0, 68.0);
          final bottomDockOffset = (width * 0.11).clamp(18.0, 38.0);

          return SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: SpazzTheme.accentPurple),
                  )
                : Padding(
                    padding: EdgeInsets.all((width * 0.03).clamp(8.0, 12.0)),
                    child: Column(
                      children: [
                        // Header Toolbar
                        Row(
                          children: [
                            Container(
                              width: headerButtonSize,
                              height: headerButtonSize,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D1E2A),
                                borderRadius: BorderRadius.circular(headerButtonSize / 2),
                              ),
                              child: Icon(
                                Icons.search,
                                color: SpazzTheme.textPrimary,
                                size: headerButtonSize * 0.52,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: navPad * 1.6,
                                vertical: navPad * 0.8,
                              ),
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
                              child: Icon(
                                Icons.menu,
                                color: SpazzTheme.textPrimary,
                                size: headerButtonSize * 0.52,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: (width * 0.03).clamp(10.0, 16.0)),

                        // Action Banner Toggle
                        GestureDetector(
                          onTap: _toggleSpazz,
                          child: Container(
                            width: double.infinity,
                            height: startButtonHeight,
                            decoration: BoxDecoration(
                              color: isBroadcasting
                                  ? SpazzTheme.accentPurple
                                  : const Color(0xFF1A1B2D),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: SpazzTheme.accentCyan, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: isBroadcasting ? Colors.white : SpazzTheme.accentCyan,
                                  size: 24,
                                ),
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

                        // Main Content Box
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
                                      style: const TextStyle(
                                        color: SpazzTheme.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),

                                // Bottom Nav Overlay
                                Positioned(
                                  bottom: 24,
                                  left: 24,
                                  child: _buildDockIcon(
                                    icon: Icons.home_rounded,
                                    size: bottomDock,
                                    isActive: _currentIndex == 0,
                                    onTap: () => setState(() => _currentIndex = 0),
                                  ),
                                ),
                                Positioned(
                                  bottom: 24,
                                  left: bottomDock + bottomDockOffset,
                                  child: _buildDockIcon(
                                    icon: Icons.inventory_2_rounded,
                                    size: bottomDock,
                                    isActive: _currentIndex == 1,
                                    onTap: () => setState(() => _currentIndex = 1),
                                  ),
                                ),
                                Positioned(
                                  bottom: 24,
                                  right: bottomDock + bottomDockOffset,
                                  child: _buildDockIcon(
                                    icon: Icons.people_alt_rounded,
                                    size: bottomDock,
                                    isActive: _currentIndex == 2,
                                    onTap: () => setState(() => _currentIndex = 2),
                                  ),
                                ),
                                Positioned(
                                  bottom: 24,
                                  right: 24,
                                  child: _buildDockIcon(
                                    icon: Icons.person_rounded,
                                    size: bottomDock,
                                    isActive: _currentIndex == 3,
                                    onTap: () => setState(() => _currentIndex = 3),
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
      ),
    );
  }

  Widget _buildDockIcon({
    required IconData icon,
    required double size,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF6FE7FF) : const Color(0xFF8B8EA6),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? SpazzTheme.accentCyan : SpazzTheme.textSecondary,
        ),
      ),
    );
  }
}