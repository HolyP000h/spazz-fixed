import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _coins = 0;
  bool _loading = true;
  List<String> _owned = [];
  String? _token;

  static const _baseUrl = 'https://www.spazzapp.com';

  // Hardcoded shop items grouped by category
  final List<Map<String, dynamic>> _themes = [
    {'id': 'theme_midnight', 'name': 'Midnight Purple', 'emoji': '🌌', 'description': 'Dark purple galaxy vibes', 'cost': 50},
    {'id': 'theme_neon', 'name': 'Neon City', 'emoji': '🌆', 'description': 'Bright cyberpunk neon streets', 'cost': 75},
    {'id': 'theme_forest', 'name': 'Dark Forest', 'emoji': '🌲', 'description': 'Deep green mysterious woods', 'cost': 60},
    {'id': 'theme_ocean', 'name': 'Deep Ocean', 'emoji': '🌊', 'description': 'Bioluminescent ocean depths', 'cost': 80},
    {'id': 'theme_fire', 'name': 'Inferno', 'emoji': '🔥', 'description': 'Blazing red and orange heat', 'cost': 100},
    {'id': 'theme_ice', 'name': 'Arctic', 'emoji': '❄️', 'description': 'Cool icy blue tones', 'cost': 90},
  ];

  final List<Map<String, dynamic>> _sounds = [
    {'id': 'sound_chime', 'name': 'Crystal Chime', 'emoji': '🔔', 'description': 'Soft magical ping sound', 'cost': 30},
    {'id': 'sound_laser', 'name': 'Laser Zap', 'emoji': '⚡', 'description': 'Sci-fi laser ping', 'cost': 40},
    {'id': 'sound_nature', 'name': 'Nature Ping', 'emoji': '🍃', 'description': 'Soft nature ambient ping', 'cost': 35},
    {'id': 'sound_retro', 'name': 'Retro Beep', 'emoji': '👾', 'description': '8-bit retro game sound', 'cost': 25},
    {'id': 'sound_whoosh', 'name': 'Whoosh', 'emoji': '💨', 'description': 'Fast swoosh notification', 'cost': 45},
    {'id': 'sound_bell', 'name': 'Temple Bell', 'emoji': '🛕', 'description': 'Deep resonant bell tone', 'cost': 55},
  ];

  final List<Map<String, dynamic>> _badges = [
    {'id': 'badge_hunter', 'name': 'Wisp Hunter', 'emoji': '🏹', 'description': 'Show off your hunting skills', 'cost': 100},
    {'id': 'badge_explorer', 'name': 'Explorer', 'emoji': '🗺️', 'description': 'For those who roam far', 'cost': 120},
    {'id': 'badge_champion', 'name': 'Champion', 'emoji': '👑', 'description': 'Top of the leaderboard', 'cost': 200},
    {'id': 'badge_ghost', 'name': 'Ghost', 'emoji': '👻', 'description': 'Silent and deadly hunter', 'cost': 150},
    {'id': 'badge_legend', 'name': 'Legend', 'emoji': '⭐', 'description': 'Reserved for the elite', 'cost': 300},
    {'id': 'badge_rookie', 'name': 'Rookie', 'emoji': '🌱', 'description': 'Just getting started', 'cost': 10},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    final userId = prefs.getString('user_id') ?? '';

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/user/$userId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _coins = data['wisp_coins'] ?? 0;
          _owned = List<String>.from(data['inventory'] ?? []);
        });
      }
    } catch (_) {}

    setState(() => _loading = false);
  }

  Future<void> _buy(Map<String, dynamic> item) async {
    if (_coins < item['cost']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough Wisp Coins! Go hunt more wisps 🌀'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Show confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text('Buy ${item['name']}?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Row(
          children: [
            Text(item['emoji'], style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['description'],
                      style: const TextStyle(color: Color(0xFF888899))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('✨ ', style: TextStyle(fontSize: 16)),
                      Text('${item['cost']} Wisp Coins',
                          style: const TextStyle(
                              color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF888899))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            child: const Text('Buy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final res = await http.post(
        Uri.parse('$_baseUrl/api/shop/buy'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'item_id': item['id'], 'user_id': userId, 'cost': item['cost']}),
      );

      if (res.statusCode == 200) {
        setState(() {
          _coins -= item['cost'] as int;
          _owned.add(item['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['emoji']} ${item['name']} unlocked!'),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
      }
    } catch (_) {
      // Optimistic update even if backend fails
      setState(() {
        _coins -= item['cost'] as int;
        _owned.add(item['id']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['emoji']} ${item['name']} unlocked!'),
          backgroundColor: const Color(0xFF7C3AED),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131A),
        title: const Text('Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF7C3AED)),
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text('$_coins',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7C3AED),
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: const Color(0xFF888899),
          tabs: const [
            Tab(text: '🎨 Themes'),
            Tab(text: '🔊 Sounds'),
            Tab(text: '🏅 Badges'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : TabBarView(
              controller: _tabController,
              children: [
                _ItemGrid(items: _themes, owned: _owned, onBuy: _buy),
                _ItemGrid(items: _sounds, owned: _owned, onBuy: _buy),
                _ItemGrid(items: _badges, owned: _owned, onBuy: _buy),
              ],
            ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final List<String> owned;
  final Function(Map<String, dynamic>) onBuy;

  const _ItemGrid({required this.items, required this.owned, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final isOwned = owned.contains(item['id']);
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOwned ? const Color(0xFF7C3AED) : const Color(0xFF1E1E2E),
              width: isOwned ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['emoji'], style: const TextStyle(fontSize: 36)),
                  if (isOwned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Owned',
                          style: TextStyle(color: Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(item['name'],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text(item['description'],
                  style: const TextStyle(color: Color(0xFF666680), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isOwned ? null : () => onBuy(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned ? const Color(0xFF1E1E2E) : const Color(0xFF7C3AED),
                    disabledBackgroundColor: const Color(0xFF1E1E2E),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isOwned
                      ? const Text('✓ Owned',
                          style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('✨ ', style: TextStyle(fontSize: 12)),
                            Text('${item['cost']}',
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold)),
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
