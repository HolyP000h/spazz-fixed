import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../design/spazz_theme.dart';
import 'chat_screen.dart';
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
  List<dynamic> _leaderboard = [];
  bool _loading = true;

  static const _baseUrl = 'https://www.spazzapp.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    // Set loading state initially
    setState(() => _loading = true);

    // --- DEVELOPMENT MOCK OVERRIDE ---
    // Simulating a delay so it feels natural, then serving local data directly
    await Future.delayed(const Duration(milliseconds: 250));

    if (mounted) {
      setState(() {
        // Populates all dashboard card fields perfectly
        _userData = {
          "username": "ben",
          "wisp_coins": 45,
          "level": 1,
          "xp": 35,
          "steps": 4820,
          "calories": 245.0,
          "wisps_collected": 12,
        };

        // Populates your leaderboard rows cleanly
        _leaderboard = [
          {"username": "ben", "xp": 120},
          {"username": "ShadowHunter", "xp": 95},
          {"username": "WispMaster", "xp": 50}
        ];
        
        _loading = false;
      });
    }
    // ----------------------------------
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardTab(
        userData: _userData,
        leaderboard: _leaderboard,
        loading: _loading,
        onRefresh: _loadUserData,
      ),
      const ChatScreen(),
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
  final List<dynamic> leaderboard;
  final bool loading;
  final VoidCallback onRefresh;

  const _DashboardTab({
    required this.userData,
    required this.leaderboard,
    required this.loading,
    required this.onRefresh,
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

                    // Hunt button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/hunt'),
                        icon: const Icon(Icons.radar, color: Colors.white),
                        label: const Text('Start Hunting',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SpazzTheme.accentPurple,
                          padding: const EdgeInsets.symmetric(vertical: SpazzTheme.spacing16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge)),
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