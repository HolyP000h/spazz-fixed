import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
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
  String? _activeSkin;
  String? _token;

  static const _baseUrl = 'https://www.spazzapp.com';

  // ── BOSS SKINS ────────────────────────────────────────────────
  final List<Map<String, dynamic>> _skins = [
    {
      'id': 'skin_lightning',
      'name': 'Storm Caller',
      'emoji': '⚡',
      'rarity': 'LEGENDARY',
      'rarityColor': 0xFFFFD700,
      'description': 'Lightning strikes ripple from your position. Everyone within 500m sees the flash.',
      'cost': 500,
      'effect': 'Lightning flashes pulse outward every 60s. Thunderclap haptic + crack sound.',
      'ping_sound': '⚡ CRACK',
      'ping_emoji': '⚡',
      'haptic': 'heavy',
    },
    {
      'id': 'skin_ghost',
      'name': 'Phantom',
      'emoji': '👻',
      'rarity': 'EPIC',
      'rarityColor': 0xFFAB5CFF,
      'description': 'You appear and vanish on other users\' maps like a ghost. Eerie ping sounds.',
      'cost': 350,
      'effect': 'Your dot fades in and out on the map. Ghost wail ping sound.',
      'ping_sound': '👻 WOOOO',
      'ping_emoji': '👻',
      'haptic': 'medium',
    },
    {
      'id': 'skin_inferno',
      'name': 'Inferno',
      'emoji': '🔥',
      'rarity': 'LEGENDARY',
      'rarityColor': 0xFFFF4500,
      'description': 'A ring of fire blazes from your location. Others feel the heat.',
      'cost': 500,
      'effect': 'Expanding fire ring animation every 45s. Deep bass rumble haptic.',
      'ping_sound': '🔥 ROAR',
      'ping_emoji': '🔥',
      'haptic': 'heavy',
    },
    {
      'id': 'skin_arctic',
      'name': 'Blizzard',
      'emoji': '❄️',
      'rarity': 'EPIC',
      'rarityColor': 0xFF00BFFF,
      'description': 'Ice shards shoot outward freezing nearby wisps temporarily.',
      'cost': 350,
      'effect': 'Snowflake burst animation. Crystal chime ping with freeze haptic.',
      'ping_sound': '❄️ SHATTER',
      'ping_emoji': '❄️',
      'haptic': 'light',
    },
    {
      'id': 'skin_void',
      'name': 'Void Walker',
      'emoji': '🌑',
      'rarity': 'MYTHIC',
      'rarityColor': 0xFF1A1A2E,
      'description': 'You exist between dimensions. A black hole pulse warps the map around you.',
      'cost': 1000,
      'effect': 'Black hole ripple animation. Deep void hum + gravitational haptic wave.',
      'ping_sound': '🌑 VOID',
      'ping_emoji': '🌑',
      'haptic': 'heavy',
    },
    {
      'id': 'skin_aurora',
      'name': 'Aurora',
      'emoji': '🌌',
      'rarity': 'EPIC',
      'rarityColor': 0xFF00FF87,
      'description': 'Northern lights radiate from your position in waves of colour.',
      'cost': 400,
      'effect': 'Rainbow wave pulses outward. Ethereal synth chime ping.',
      'ping_sound': '🌌 CHIME',
      'ping_emoji': '🌌',
      'haptic': 'medium',
    },
    {
      'id': 'skin_royale',
      'name': 'King\'s Decree',
      'emoji': '👑',
      'rarity': 'MYTHIC',
      'rarityColor': 0xFFFFD700,
      'description': 'A golden crown beacon shoots into the sky. All nearby users are notified.',
      'cost': 1000,
      'effect': 'Golden beacon shoots up. Royal trumpet fanfare. Everyone within 1km gets a notification.',
      'ping_sound': '👑 FANFARE',
      'ping_emoji': '👑',
      'haptic': 'heavy',
    },
    {
      'id': 'skin_neon',
      'name': 'Neon Punk',
      'emoji': '🌆',
      'rarity': 'RARE',
      'rarityColor': 0xFFFF007F,
      'description': 'Neon grid lines pulse outward like a retro city grid.',
      'cost': 200,
      'effect': 'Pink neon grid ripple. Synth laser ping sound.',
      'ping_sound': '🌆 LASER',
      'ping_emoji': '🌆',
      'haptic': 'light',
    },
    {
      'id': 'skin_shadow',
      'name': 'Shadow Lord',
      'emoji': '🦇',
      'rarity': 'EPIC',
      'rarityColor': 0xFF4A0080,
      'description': 'Bats scatter from your location. Dark sonar ping.',
      'cost': 350,
      'effect': 'Bat swarm animation radiates outward. Sonar ping with echo.',
      'ping_sound': '🦇 SCREECH',
      'ping_emoji': '🦇',
      'haptic': 'medium',
    },
  ];

  // ── PING SOUNDS ────────────────────────────────────────────────
  final List<Map<String, dynamic>> _pings = [
    {'id': 'ping_thunder', 'name': 'Thunderclap', 'emoji': '⚡', 'cost': 80, 'description': 'Deep crack of thunder that echoes'},
    {'id': 'ping_ghost', 'name': 'Ghost Wail', 'emoji': '👻', 'cost': 60, 'description': 'Eerie ghostly howl'},
    {'id': 'ping_dragon', 'name': 'Dragon Roar', 'emoji': '🐉', 'cost': 100, 'description': 'Epic dragon battle cry'},
    {'id': 'ping_laser', 'name': 'Plasma Laser', 'emoji': '🔫', 'cost': 50, 'description': 'Sci-fi plasma discharge'},
    {'id': 'ping_royal', 'name': 'Royal Fanfare', 'emoji': '👑', 'cost': 120, 'description': 'Trumpet blast announcing your arrival'},
    {'id': 'ping_void', 'name': 'Void Echo', 'emoji': '🌑', 'cost': 90, 'description': 'Deep reverberating void hum'},
    {'id': 'ping_crystal', 'name': 'Crystal Shatter', 'emoji': '💎', 'cost': 70, 'description': 'High-pitched crystal break'},
    {'id': 'ping_wolf', 'name': 'Wolf Howl', 'emoji': '🐺', 'cost': 65, 'description': 'Lone wolf howl in the dark'},
    {'id': 'ping_space', 'name': 'Warp Drive', 'emoji': '🚀', 'cost': 85, 'description': 'Hyperdrive engage sound'},
  ];

  // ── THEMES ────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _themes = [
    {'id': 'theme_midnight', 'name': 'Midnight Purple', 'emoji': '🌌', 'description': 'Dark purple galaxy vibes', 'cost': 50},
    {'id': 'theme_neon', 'name': 'Neon City', 'emoji': '🌆', 'description': 'Bright cyberpunk neon streets', 'cost': 75},
    {'id': 'theme_forest', 'name': 'Dark Forest', 'emoji': '🌲', 'description': 'Deep green mysterious woods', 'cost': 60},
    {'id': 'theme_ocean', 'name': 'Deep Ocean', 'emoji': '🌊', 'description': 'Bioluminescent ocean depths', 'cost': 80},
    {'id': 'theme_fire', 'name': 'Inferno', 'emoji': '🔥', 'description': 'Blazing red and orange heat', 'cost': 100},
    {'id': 'theme_ice', 'name': 'Arctic', 'emoji': '❄️', 'description': 'Cool icy blue tones', 'cost': 90},
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
    _activeSkin = prefs.getString('active_skin');

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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text('Buy ${item['name']}?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item['emoji'], style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(item['description'] ?? '',
                style: const TextStyle(color: Color(0xFF888899)), textAlign: TextAlign.center),
            if (item['effect'] != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('✨ ${item['effect']}',
                    style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 12),
                    textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✨ ', style: TextStyle(fontSize: 16)),
                Text('${item['cost']} Wisp Coins',
                    style: const TextStyle(
                        color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 16)),
              ],
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

    HapticFeedback.heavyImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      await http.post(
        Uri.parse('$_baseUrl/api/shop/buy'),
        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
        body: json.encode({'item_id': item['id'], 'user_id': userId, 'cost': item['cost']}),
      );
    } catch (_) {}

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

  Future<void> _equipSkin(Map<String, dynamic> skin) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_skin', skin['id']);
    setState(() => _activeSkin = skin['id']);

    // Tell backend
    try {
      final userId = prefs.getString('user_id') ?? '';
      await http.post(
        Uri.parse('$_baseUrl/api/skin/equip'),
        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'skin_id': skin['id']}),
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${skin['emoji']} ${skin['name']} equipped! Others will feel your presence.'),
        backgroundColor: Color(skin['rarityColor'] as int),
        duration: const Duration(seconds: 3),
      ),
    );
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Tab(text: '⚡ Boss Skins'),
            Tab(text: '🔊 Pings'),
            Tab(text: '🎨 Themes'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : TabBarView(
              controller: _tabController,
              children: [
                _SkinsTab(
                  skins: _skins,
                  owned: _owned,
                  activeSkin: _activeSkin,
                  onBuy: _buy,
                  onEquip: _equipSkin,
                ),
                _PingGrid(items: _pings, owned: _owned, onBuy: _buy),
                _ItemGrid(items: _themes, owned: _owned, onBuy: _buy),
              ],
            ),
    );
  }
}

// ── BOSS SKINS TAB ────────────────────────────────────────────────

class _SkinsTab extends StatelessWidget {
  final List<Map<String, dynamic>> skins;
  final List<String> owned;
  final String? activeSkin;
  final Function(Map<String, dynamic>) onBuy;
  final Function(Map<String, dynamic>) onEquip;

  const _SkinsTab({
    required this.skins,
    required this.owned,
    required this.activeSkin,
    required this.onBuy,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: skins.length,
      itemBuilder: (_, i) {
        final skin = skins[i];
        final isOwned = owned.contains(skin['id']);
        final isActive = activeSkin == skin['id'];
        final rarityColor = Color(skin['rarityColor'] as int);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? rarityColor : (isOwned ? rarityColor.withOpacity(0.4) : const Color(0xFF1E1E2E)),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: rarityColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Animated emoji
                    _PulsingEmoji(emoji: skin['emoji'], color: rarityColor, isActive: isActive),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(skin['name'],
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: rarityColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: rarityColor.withOpacity(0.5)),
                                ),
                                child: Text(skin['rarity'],
                                    style: TextStyle(
                                        color: rarityColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(skin['description'],
                              style: const TextStyle(color: Color(0xFF888899), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Effect description
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: rarityColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(skin['ping_emoji'], style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(skin['effect'],
                            style: TextStyle(color: rarityColor.withOpacity(0.9), fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action row
                Row(
                  children: [
                    if (!isOwned) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => onBuy(skin),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rarityColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('✨ ', style: TextStyle(fontSize: 13)),
                              Text('${skin['cost']}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ] else if (isActive) ...[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: rarityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: rarityColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt, color: rarityColor, size: 16),
                              const SizedBox(width: 4),
                              Text('ACTIVE',
                                  style: TextStyle(
                                      color: rarityColor,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => onEquip(skin),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1E2E),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Equip',
                              style: TextStyle(color: rarityColor, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── PULSING EMOJI WIDGET ──────────────────────────────────────────

class _PulsingEmoji extends StatefulWidget {
  final String emoji;
  final Color color;
  final bool isActive;

  const _PulsingEmoji({required this.emoji, required this.color, required this.isActive});

  @override
  State<_PulsingEmoji> createState() => _PulsingEmojiState();
}

class _PulsingEmojiState extends State<_PulsingEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isActive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingEmoji old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isActive && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.15),
          boxShadow: widget.isActive
              ? [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 16, spreadRadius: 2)]
              : [],
        ),
        child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 28))),
      ),
    );
  }
}

// ── PING GRID ─────────────────────────────────────────────────────

class _PingGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final List<String> owned;
  final Function(Map<String, dynamic>) onBuy;

  const _PingGrid({required this.items, required this.owned, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final isOwned = owned.contains(item['id']);
        return GestureDetector(
          onTap: isOwned
              ? () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item['emoji']} ${item['name']} — equipped as your ping!'),
                      backgroundColor: const Color(0xFF7C3AED),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOwned ? const Color(0xFF7C3AED) : const Color(0xFF1E1E2E),
                width: isOwned ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['emoji'], style: const TextStyle(fontSize: 32)),
                    if (isOwned)
                      const Icon(Icons.volume_up, color: Color(0xFF7C3AED), size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['name'],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isOwned
                        ? const Text('✓ Owned',
                            style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 12))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('✨ ', style: TextStyle(fontSize: 11)),
                              Text('${item['cost']}',
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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

// ── THEMES GRID ───────────────────────────────────────────────────

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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
