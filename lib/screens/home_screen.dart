import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      setState(() {
        _prefs = prefs;
        _userData = {
          "username": "ben",
          "wisp_coins": 45,
          "level": 1,
          "xp": 35,
          "steps": 4820,
          "calories": 245.0,
          "wisps_collected": 12,
        };

        _leaderboard = [
          {"username": "ben", "xp": 120},
          {"username": "ShadowHunter", "xp": 95},
          {"username": "WispMaster", "xp": 50}
        ];
        
        _loading = false;
      });
    }
  }

  Future<void> _toggleSpazzMode() async {
    final homeAddress = _prefs['home_address'] ?? '';
    if (homeAddress.isEmpty) {
      _showSafetyWarning('Home Address Required', 'Important: Enter your home address in Profile to protect yourself. Spazz will be unable to be initialized without a safe zone set.');
      return;
    }

    final newState = !(_prefs['is_broadcasting'] ?? false);
    
    if (newState) {
      // Check if user is currently at home
      try {
        final pos = await Geolocator.getCurrentPosition();
        final homeLat = _prefs['home_lat'] ?? 0.0;
        final homeLng = _prefs['home_lng'] ?? 0.0;
        final radius = _prefs['geofence_radius'] ?? 250.0;

        if (homeLat != 0.0 && homeLng != 0.0) {
          final dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, homeLat, homeLng);
          if (dist < radius) {
            _showSafetyWarning('In Safe Zone', 'You are currently within your Home Safe Zone. Spazz broadcasting is disabled here for your privacy.');
            return;
          }
        }
      } catch (_) {}
    }

    await AuthService.updatePreferences(isBroadcasting: newState);
    setState(() {
      _prefs['is_broadcasting'] = newState;
    });
  }

  void _showSafetyWarning(String title, String message) {
    showDialog(
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (title == 'Home Address Required')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3); // Go to Profile
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
        userData: _userData,
        prefs: _prefs,
        leaderboard: _leaderboard,
        loading: _loading,
        onRefresh: _loadUserData,
        onToggleSpazz: _toggleSpazzMode,
      ),
      const FriendsScreen(),
      const ShopScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: SpazzTheme.bgSecondary,
          border: Border(top: BorderSide(color: SpazzTheme.borderDark)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: SpazzTheme.accentPurple,
          unselectedItemColor: SpazzTheme.textTertiary,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Shop'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

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
    final steps = userData['steps'] ?? 0;
    final xp = userData['xp'] ?? 0;
    final level = userData['level'] ?? 1;
    final calories = (userData['calories'] ?? 0.0).toStringAsFixed(0);
    final xpProgress = (xp % 100) / 100.0;
    final isBroadcasting = prefs['is_broadcasting'] ?? false;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: SpazzTheme.accentPurple,
        backgroundColor: SpazzTheme.bgSecondary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(SpazzTheme.spacing16),
          child: loading
              ? const Center(child: CircularProgressIndicator(color: SpazzTheme.accentPurple))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hey, $username 👋',
                                style: SpazzTheme.heading3.copyWith(
                                    color: SpazzTheme.textPrimary)),
                            const Text('Go find some wisps!',
                                style: TextStyle(color: SpazzTheme.textSecondary, fontSize: 14)),
                          ],
                        ),
                        // Wisp coin badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: SpazzTheme.spacing12, vertical: SpazzTheme.spacing8),
                          decoration: BoxDecoration(
                            color: SpazzTheme.bgTertiary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: SpazzTheme.accentPurple),
                          ),
                          child: Row(
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: SpazzTheme.spacing4),
                              Text('$wispCoins',
                                  style: const TextStyle(
                                      color: SpazzTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpazzTheme.spacing20),

                    // Level + XP bar
                    Container(
                      padding: const EdgeInsets.all(SpazzTheme.spacing16),
                      decoration: BoxDecoration(
                        color: SpazzTheme.bgTertiary,
                        borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Level $level',
                                  style: const TextStyle(
                                      color: SpazzTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('$xp XP',
                                  style: const TextStyle(color: SpazzTheme.accentPurple, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: SpazzTheme.spacing8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(SpazzTheme.radiusSmall),
                            child: LinearProgressIndicator(
                              value: xpProgress,
                              backgroundColor: SpazzTheme.bgPrimary,
                              valueColor: const AlwaysStoppedAnimation<Color>(SpazzTheme.accentPurple),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: SpazzTheme.spacing4),
                          Text('${((1 - xpProgress) * 100).toInt()} XP to next level',
                              style: const TextStyle(color: SpazzTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: SpazzTheme.spacing16),

                    // Stats row
                    Row(
                      children: [
                        _StatCard(icon: '👟', label: 'Steps', value: '$steps'),
                        const SizedBox(width: SpazzTheme.spacing12),
                        _StatCard(icon: '🔥', label: 'Calories', value: calories),
                        const SizedBox(width: SpazzTheme.spacing12),
                        _StatCard(icon: '✨', label: 'Wisps', value: '${userData['wisps_collected'] ?? 0}'),
                      ],
                    ),
                    const SizedBox(height: SpazzTheme.spacing20),

                    // Start Spazz Button
                    GestureDetector(
                      onTap: onToggleSpazz,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: SpazzTheme.spacing20),
                        decoration: BoxDecoration(
                          gradient: isBroadcasting ? SpazzTheme.gradientPrimary : null,
                          color: isBroadcasting ? null : SpazzTheme.bgTertiary,
                          borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                          border: isBroadcasting ? null : Border.all(color: SpazzTheme.borderDark, width: 2),
                          boxShadow: isBroadcasting ? [
                            BoxShadow(color: SpazzTheme.accentPurple.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)
                          ] : [],
                        ),
                        child: Column(
                          children: [
                            Text(
                              isBroadcasting ? '📡 BROADCASTING SIGNAL' : 'Start Spazz',
                              style: TextStyle(
                                color: isBroadcasting ? Colors.white : SpazzTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isBroadcasting ? 'Searching for matched paths...' : 'Tap to start hunting for matches',
                              style: TextStyle(
                                color: isBroadcasting ? Colors.white.withValues(alpha: 0.8) : SpazzTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: SpazzTheme.spacing16),

                    // Open Radar button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/hunt'),
                        icon: const Icon(Icons.radar, color: Colors.white),
                        label: const Text('Open Radar',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SpazzTheme.bgSecondary,
                          padding: const EdgeInsets.symmetric(vertical: SpazzTheme.spacing16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                            side: const BorderSide(color: SpazzTheme.accentPurple),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: SpazzTheme.spacing16),

                    // AI Dating Coach button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/coach'),
                        icon: const Icon(Icons.psychology, color: SpazzTheme.accentCyan),
                        label: const Text('AI Dating Coach',
                            style: TextStyle(color: SpazzTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: SpazzTheme.spacing16),
                          side: const BorderSide(color: SpazzTheme.accentCyan),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: SpazzTheme.spacing16),

                    // Bless a Wisp button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/bless-wisp'),
                        icon: const Icon(Icons.stars, color: Colors.black),
                        label: const Text('Bless a Wisp (Pin Money)',
                            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: SpazzTheme.spacing16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: SpazzTheme.spacing20),

                    // Leaderboard
                    const Text('🏆 Leaderboard',
                        style: TextStyle(color: SpazzTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: SpazzTheme.spacing12),
                    if (leaderboard.isEmpty)
                      const Center(
                        child: Text('No hunters yet — be the first!',
                            style: TextStyle(color: SpazzTheme.textSecondary)),
                      )
                    else
                      ...leaderboard.asMap().entries.map((entry) {
                        final i = entry.key;
                        final player = entry.value;
                        final medals = ['🥇', '🥈', '🥉'];
                        final medal = i < 3 ? medals[i] : '${i + 1}.';
                        return Container(
                          margin: const EdgeInsets.only(bottom: SpazzTheme.spacing8),
                          padding: const EdgeInsets.symmetric(horizontal: SpazzTheme.spacing16, vertical: SpazzTheme.spacing12),
                          decoration: BoxDecoration(
                            color: SpazzTheme.bgTertiary,
                            borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium),
                          ),
                          child: Row(
                            children: [
                              Text(medal, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: SpazzTheme.spacing12),
                              Expanded(
                                child: Text(player['username'] ?? '',
                                    style: const TextStyle(color: SpazzTheme.textPrimary, fontWeight: FontWeight.w600)),
                              ),
                              Text('${player['xp'] ?? 0} XP',
                                  style: const TextStyle(color: SpazzTheme.accentPurple)),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: SpazzTheme.spacing20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(SpazzTheme.spacing14),
        decoration: BoxDecoration(
          color: SpazzTheme.bgTertiary,
          borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: SpazzTheme.spacing6),
            Text(value,
                style: const TextStyle(
                    color: SpazzTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: SpazzTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
