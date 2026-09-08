import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../design/spazz_theme.dart';
import '../services/api_service.dart';

class LoveNoteScreen extends StatefulWidget {
  final String friendId;
  final String friendUsername;

  const LoveNoteScreen({
    super.key,
    required this.friendId,
    required this.friendUsername,
  });

  @override
  State<LoveNoteScreen> createState() => _LoveNoteScreenState();
}

class _LoveNoteScreenState extends State<LoveNoteScreen> {
  final _textCtrl = TextEditingController();
  bool _dropping = false;

  Future<void> _dropNote() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _dropping = true);

    try {
      // Get current location to "pin" the note
      final pos = await Geolocator.getCurrentPosition();
      
      await ApiService.post('/api/notes/drop', {
        'to_user_id': widget.friendId,
        'to_username': widget.friendUsername,
        'message': text,
        'lat': pos.latitude,
        'lng': pos.longitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💖 Love note dropped for ${widget.friendUsername}!'),
            backgroundColor: Colors.pinkAccent,
          ),
        );
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to drop note'), backgroundColor: SpazzTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _dropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Drop a Love Note'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(SpazzTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leave a message for ${widget.friendUsername} to find...', style: SpazzTheme.subtitle1),
            const SizedBox(height: 8),
            const Text(
              'The note will be pinned to your current location. They will need to use their Radar to find it!',
              style: TextStyle(color: SpazzTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(SpazzTheme.spacing16),
                decoration: BoxDecoration(
                  color: SpazzTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
                  border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _textCtrl,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                  decoration: const InputDecoration(
                    hintText: 'Write something sweet...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _dropping ? null : _dropNote,
                icon: const Icon(Icons.location_on),
                label: Text(_dropping ? 'Dropping...' : 'Pin Note Here'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: SpazzTheme.spacing16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
