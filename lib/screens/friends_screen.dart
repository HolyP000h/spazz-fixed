import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design/spazz_theme.dart';
import '../services/api_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<dynamic> _friends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final res = await ApiService.get('/api/friends');
      setState(() {
        _friends = res['friends'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: SpazzTheme.bgSecondary,
        title: const Text('Spazz Friends', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFriends,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SpazzTheme.accentPurple))
          : _friends.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(SpazzTheme.spacing16),
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    return _buildFriendCard(friend);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✨', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'No encounters yet!',
            style: TextStyle(color: SpazzTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Go out and use the Radar to find matches. Successful encounters unlock private chats.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SpazzTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/hunt'),
            child: const Text('Open Radar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final username = friend['username'] ?? 'Unknown';
    final userId = friend['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: SpazzTheme.spacing16),
      padding: const EdgeInsets.all(SpazzTheme.spacing16),
      decoration: BoxDecoration(
        color: SpazzTheme.bgSecondary,
        borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
        border: Border.all(color: SpazzTheme.borderDark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: SpazzTheme.accentPurple,
                child: Text(username[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, style: const TextStyle(color: SpazzTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('Matched via Spazz Radar', style: TextStyle(color: SpazzTheme.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: SpazzTheme.accentCyan),
                onPressed: () => context.go('/chat/$userId/$username'),
              ),
            ],
          ),
          const Divider(height: 24, color: SpazzTheme.borderDark),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActivityButton(
                icon: Icons.favorite_border,
                label: 'Love Note',
                color: Colors.pinkAccent,
                onTap: () => context.go('/note/drop/$userId/$username'),
              ),
              _ActivityButton(
                icon: Icons.videogame_asset_outlined,
                label: 'Mini-Game',
                color: Colors.orangeAccent,
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mini-Games coming soon! Stay tuned.')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActivityButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
