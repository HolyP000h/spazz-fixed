import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── PING DATA MODEL ───────────────────────────────────────────────

class PingData {
  final String id;
  final String userId;
  final String username;
  final String pingId;
  final String emoji;
  final String name;
  final String sound;
  final String haptic;
  final int priority; // higher = cuts through
  final double lat;
  final double lng;
  final DateTime sentAt;
  final bool isPremium;

  PingData({
    required this.id,
    required this.userId,
    required this.username,
    required this.pingId,
    required this.emoji,
    required this.name,
    required this.sound,
    required this.haptic,
    required this.priority,
    required this.lat,
    required this.lng,
    required this.sentAt,
    required this.isPremium,
  });

  factory PingData.fromJson(Map<String, dynamic> j) => PingData(
        id: j['id'] ?? '',
        userId: j['user_id'] ?? '',
        username: j['username'] ?? 'Hunter',
        pingId: j['ping_id'] ?? '',
        emoji: j['emoji'] ?? '📡',
        name: j['name'] ?? 'Ping',
        sound: j['sound'] ?? 'default',
        haptic: j['haptic'] ?? 'light',
        priority: j['priority'] ?? 1,
        lat: (j['lat'] ?? 0).toDouble(),
        lng: (j['lng'] ?? 0).toDouble(),
        sentAt: DateTime.tryParse(j['sent_at'] ?? '') ?? DateTime.now(),
        isPremium: j['is_premium'] ?? false,
      );
}

// ── PING DEFINITIONS ──────────────────────────────────────────────

class PingDefinitions {
  static const all = [
    // FREE pings — priority 1
    {
      'id': 'ping_default',
      'name': 'Basic Ping',
      'emoji': '📡',
      'sound': 'beep',
      'haptic': 'light',
      'priority': 1,
      'isPremium': false,
      'cost': 0,
      'description': 'A simple ping to let others know you\'re here',
    },
    {
      'id': 'ping_wave',
      'name': 'Wave',
      'emoji': '👋',
      'sound': 'chime',
      'haptic': 'light',
      'priority': 1,
      'isPremium': false,
      'cost': 0,
      'description': 'Friendly wave to nearby users',
    },

    // PAID pings — priority 2-5, push through free pings
    {
      'id': 'ping_thunder',
      'name': 'Thunderclap',
      'emoji': '⚡',
      'sound': 'thunder_crack',
      'haptic': 'heavy',
      'priority': 4,
      'isPremium': true,
      'cost': 80,
      'description': 'Cuts through everything. Deep crack of thunder. Everyone nearby feels it.',
    },
    {
      'id': 'ping_dragon',
      'name': 'Dragon Roar',
      'emoji': '🐉',
      'sound': 'dragon_roar',
      'haptic': 'heavy',
      'priority': 5,
      'isPremium': true,
      'cost': 100,
      'description': 'Highest priority ping. Overrides ALL other pings in range.',
    },
    {
      'id': 'ping_royal',
      'name': 'Royal Fanfare',
      'emoji': '👑',
      'sound': 'trumpet_fanfare',
      'haptic': 'heavy',
      'priority': 5,
      'isPremium': true,
      'cost': 120,
      'description': 'A royal announcement. Nobody ignores a king.',
    },
    {
      'id': 'ping_ghost',
      'name': 'Ghost Wail',
      'emoji': '👻',
      'sound': 'ghost_wail',
      'haptic': 'medium',
      'priority': 3,
      'isPremium': true,
      'cost': 60,
      'description': 'Eerie wail that cuts through basic pings.',
    },
    {
      'id': 'ping_void',
      'name': 'Void Echo',
      'emoji': '🌑',
      'sound': 'void_hum',
      'haptic': 'heavy',
      'priority': 4,
      'isPremium': true,
      'cost': 90,
      'description': 'Deep reverberating hum. Pushes through mid-tier pings.',
    },
    {
      'id': 'ping_crystal',
      'name': 'Crystal Shatter',
      'emoji': '💎',
      'sound': 'crystal_break',
      'haptic': 'medium',
      'priority': 3,
      'isPremium': true,
      'cost': 70,
      'description': 'High-pitched crystal shard sound. Cuts through free pings.',
    },
    {
      'id': 'ping_wolf',
      'name': 'Wolf Howl',
      'emoji': '🐺',
      'sound': 'wolf_howl',
      'haptic': 'medium',
      'priority': 3,
      'isPremium': true,
      'cost': 65,
      'description': 'Lone wolf in the dark. You\'re out and you want people to know.',
    },
    {
      'id': 'ping_laser',
      'name': 'Plasma Laser',
      'emoji': '🔫',
      'sound': 'plasma_zap',
      'haptic': 'light',
      'priority': 2,
      'isPremium': true,
      'cost': 50,
      'description': 'Sci-fi plasma discharge. Pushes past basic pings.',
    },
    {
      'id': 'ping_space',
      'name': 'Warp Drive',
      'emoji': '🚀',
      'sound': 'warp_engage',
      'haptic': 'medium',
      'priority': 3,
      'isPremium': true,
      'cost': 85,
      'description': 'Hyperdrive sound. Fast, sharp, impossible to ignore.',
    },
  ];

  static Map<String, dynamic>? getById(String id) {
    try {
      return all.firstWhere((p) => p['id'] == id) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

// ── PING BUTTON WIDGET ────────────────────────────────────────────
// Drop this onto the map screen

class PingButton extends StatefulWidget {
  final double lat;
  final double lng;
  final List<String> ownedPings;
  final String activePingId;
  final Function(PingData) onPingSent;

  const PingButton({
    super.key,
    required this.lat,
    required this.lng,
    required this.ownedPings,
    required this.activePingId,
    required this.onPingSent,
  });

  @override
  State<PingButton> createState() => _PingButtonState();
}

class _PingButtonState extends State<PingButton> with SingleTickerProviderStateMixin {
  bool _sending = false;
  bool _cooldown = false;
  int _cooldownSecs = 0;
  Timer? _cooldownTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  static const _baseUrl = 'https://www.spazzapp.com';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulse = Tween(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendPing() async {
    if (_sending || _cooldown) return;

    final pingDef = PingDefinitions.getById(widget.activePingId) ??
        PingDefinitions.all.first as Map<String, dynamic>;

    setState(() => _sending = true);

    // Haptic feedback based on ping tier
    switch (pingDef['haptic']) {
      case 'heavy':
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
        break;
      case 'medium':
        await HapticFeedback.mediumImpact();
        break;
      default:
        await HapticFeedback.lightImpact();
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getString('user_id') ?? '';
    final username = prefs.getString('username') ?? 'Hunter';

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/ping/send'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'username': username,
          'ping_id': pingDef['id'],
          'emoji': pingDef['emoji'],
          'name': pingDef['name'],
          'sound': pingDef['sound'],
          'haptic': pingDef['haptic'],
          'priority': pingDef['priority'],
          'lat': widget.lat,
          'lng': widget.lng,
          'is_premium': pingDef['isPremium'],
        }),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        widget.onPingSent(PingData.fromJson({
          ...data,
          'user_id': userId,
          'username': username,
          ...pingDef,
          'lat': widget.lat,
          'lng': widget.lng,
          'sent_at': DateTime.now().toIso8601String(),
        }));
      }
    } catch (_) {
      // Fire locally even if backend down
      widget.onPingSent(PingData(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        username: username,
        pingId: pingDef['id'] as String,
        emoji: pingDef['emoji'] as String,
        name: pingDef['name'] as String,
        sound: pingDef['sound'] as String,
        haptic: pingDef['haptic'] as String,
        priority: pingDef['priority'] as int,
        lat: widget.lat,
        lng: widget.lng,
        sentAt: DateTime.now(),
        isPremium: pingDef['isPremium'] as bool,
      ));
    }

    setState(() => _sending = false);

    // Cooldown: premium pings 20s, free pings 60s
    final cooldownDuration = (pingDef['isPremium'] as bool) ? 20 : 60;
    _startCooldown(cooldownDuration);
  }

  void _startCooldown(int seconds) {
    setState(() {
      _cooldown = true;
      _cooldownSecs = seconds;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _cooldownSecs--);
      if (_cooldownSecs <= 0) {
        t.cancel();
        setState(() => _cooldown = false);
      }
    });
  }

  void _showPingPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PingPickerSheet(
        ownedPings: widget.ownedPings,
        activePingId: widget.activePingId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pingDef = PingDefinitions.getById(widget.activePingId);
    final emoji = pingDef?['emoji'] as String? ?? '📡';
    final isPremium = pingDef?['isPremium'] as bool? ?? false;
    final priority = pingDef?['priority'] as int? ?? 1;

    final Color pingColor = _getPingColor(priority);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hold to change ping
        GestureDetector(
          onLongPress: _showPingPicker,
          onTap: _sendPing,
          child: ScaleTransition(
            scale: _pulse,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cooldown ? const Color(0xFF1E1E2E) : pingColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: _cooldown ? const Color(0xFF444460) : pingColor,
                  width: 2.5,
                ),
                boxShadow: _cooldown
                    ? []
                    : [BoxShadow(color: pingColor.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 4)],
              ),
              child: _sending
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    )
                  : _cooldown
                      ? Center(
                          child: Text('${_cooldownSecs}s',
                              style: const TextStyle(
                                  color: Color(0xFF888899),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        )
                      : Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _cooldown ? 'cooldown' : (isPremium ? '👑 hold to switch' : 'hold to switch'),
          style: TextStyle(
            color: _cooldown ? const Color(0xFF444460) : pingColor.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getPingColor(int priority) {
    switch (priority) {
      case 5: return const Color(0xFFFFD700); // gold
      case 4: return const Color(0xFFFF4500); // orange-red
      case 3: return const Color(0xFF7C3AED); // purple
      case 2: return const Color(0xFF00BFFF); // blue
      default: return const Color(0xFF444460); // grey
    }
  }
}

// ── PING PICKER SHEET ─────────────────────────────────────────────

class _PingPickerSheet extends StatelessWidget {
  final List<String> ownedPings;
  final String activePingId;

  const _PingPickerSheet({required this.ownedPings, required this.activePingId});

  @override
  Widget build(BuildContext context) {
    final allPings = PingDefinitions.all;
    final available = allPings.where((p) =>
      !(p['isPremium'] as bool) || ownedPings.contains(p['id'])
    ).toList();
    final locked = allPings.where((p) =>
      (p['isPremium'] as bool) && !ownedPings.contains(p['id'])
    ).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: const Color(0xFF444460), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Your Pings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Text('tap to equip', style: TextStyle(color: Color(0xFF888899), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Available pings
                ...available.map((p) => _PingRow(
                  ping: p as Map<String, dynamic>,
                  isActive: activePingId == p['id'],
                  isLocked: false,
                  onTap: () {
                    SharedPreferences.getInstance().then((prefs) {
                      prefs.setString('active_ping', p['id'] as String);
                    });
                    Navigator.pop(context);
                  },
                )),

                // Locked premium pings
                if (locked.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(children: [
                      Expanded(child: Divider(color: Color(0xFF1E1E2E))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('🔒 Unlock in Shop', style: TextStyle(color: Color(0xFF444460), fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Color(0xFF1E1E2E))),
                    ]),
                  ),
                  ...locked.map((p) => _PingRow(
                    ping: p as Map<String, dynamic>,
                    isActive: false,
                    isLocked: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PingRow extends StatelessWidget {
  final Map<String, dynamic> ping;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const _PingRow({
    required this.ping,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  Color _priorityColor(int p) {
    switch (p) {
      case 5: return const Color(0xFFFFD700);
      case 4: return const Color(0xFFFF4500);
      case 3: return const Color(0xFF7C3AED);
      case 2: return const Color(0xFF00BFFF);
      default: return const Color(0xFF444460);
    }
  }

  String _priorityLabel(int p) {
    switch (p) {
      case 5: return 'MAX POWER';
      case 4: return 'DOMINANT';
      case 3: return 'STRONG';
      case 2: return 'MID';
      default: return 'BASIC';
    }
  }

  @override
  Widget build(BuildContext context) {
    final priority = ping['priority'] as int;
    final color = _priorityColor(priority);

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.45 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.1) : const Color(0xFF0A0A0F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : const Color(0xFF1E1E2E),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(ping['emoji'] as String, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(ping['name'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _priorityLabel(priority),
                            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(ping['description'] as String,
                        style: const TextStyle(color: Color(0xFF666680), fontSize: 11)),
                  ],
                ),
              ),
              if (isActive)
                Icon(Icons.radio_button_checked, color: color, size: 20)
              else if (isLocked)
                const Text('🔒', style: TextStyle(fontSize: 16))
              else
                const Icon(Icons.radio_button_unchecked, color: Color(0xFF444460), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── INCOMING PING OVERLAY ─────────────────────────────────────────
// Show this when you receive a ping from another user

class IncomingPingOverlay extends StatefulWidget {
  final PingData ping;
  final VoidCallback onDismiss;

  const IncomingPingOverlay({super.key, required this.ping, required this.onDismiss});

  @override
  State<IncomingPingOverlay> createState() => _IncomingPingOverlayState();
}

class _IncomingPingOverlayState extends State<IncomingPingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

    _ctrl.forward();

    // Trigger haptic based on priority
    _triggerHaptic();

    // Auto-dismiss after 4s
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onDismiss();
    });
  }

  void _triggerHaptic() async {
    switch (widget.ping.haptic) {
      case 'heavy':
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        break;
      case 'medium':
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 200));
        await HapticFeedback.mediumImpact();
        break;
      default:
        await HapticFeedback.lightImpact();
    }
  }

  Color _priorityColor(int p) {
    switch (p) {
      case 5: return const Color(0xFFFFD700);
      case 4: return const Color(0xFFFF4500);
      case 3: return const Color(0xFF7C3AED);
      case 2: return const Color(0xFF00BFFF);
      default: return const Color(0xFF444460);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(widget.ping.priority);
    final isPremium = widget.ping.isPremium;

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xEE13131A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color, width: isPremium ? 2 : 1),
              boxShadow: isPremium
                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 4)]
                  : [],
            ),
            child: Row(
              children: [
                // Pulsing emoji
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)],
                  ),
                  child: Center(
                    child: Text(widget.ping.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (isPremium) ...[
                            Text('👑 ', style: TextStyle(fontSize: 12, color: color)),
                          ],
                          Text(widget.ping.username,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('sent a ${widget.ping.name}',
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('They\'re nearby and want to connect',
                          style: const TextStyle(color: Color(0xFF888899), fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(widget.ping.emoji, style: const TextStyle(fontSize: 22)),
                    if (isPremium)
                      Text('BOSS', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
