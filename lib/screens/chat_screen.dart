import 'package:flutter/material.dart';
import 'package:spazz_fixed/services/api_service.dart';
import 'package:spazz_fixed/services/auth_service.dart';
import '../design/spazz_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _myUsername = await AuthService.getUsername();
    try {
      final res = await ApiService.get('/api/chat');
      setState(() {
        _messages = List<Map<String, dynamic>>.from(res['messages'] ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      await ApiService.post('/api/chat', {'message': text});
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: SpazzTheme.bgSecondary,
        title: const Text('Chat', style: TextStyle(color: SpazzTheme.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: SpazzTheme.accentPurple))
                : ListView.builder(
                    padding: const EdgeInsets.all(SpazzTheme.spacing16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg['username'] == _myUsername;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: SpazzTheme.spacing8),
                          padding: const EdgeInsets.symmetric(horizontal: SpazzTheme.spacing14, vertical: SpazzTheme.spacing10),
                          decoration: BoxDecoration(
                            color: isMe ? SpazzTheme.accentPurple : SpazzTheme.bgTertiary,
                            borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(msg['username'] ?? '', style: const TextStyle(
                                  color: SpazzTheme.accentCyan, fontSize: 11, fontWeight: FontWeight.w600,
                                )),
                              Text(msg['message'] ?? '', style: const TextStyle(color: SpazzTheme.textPrimary)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(SpazzTheme.spacing12),
            color: SpazzTheme.bgSecondary,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: SpazzTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      contentPadding: EdgeInsets.symmetric(horizontal: SpazzTheme.spacing16, vertical: SpazzTheme.spacing10),
                    ),
                  ),
                ),
                const SizedBox(width: SpazzTheme.spacing8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(SpazzTheme.spacing12),
                    decoration: BoxDecoration(
                      color: SpazzTheme.accentPurple,
                      borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
