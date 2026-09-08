import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design/spazz_theme.dart';
import '../services/api_service.dart';

class FeedbackScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUsername;

  const FeedbackScreen({
    super.key,
    required this.targetUserId,
    required this.targetUsername,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  double _rating = 3.0;
  final List<String> _selectedTags = [];
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  final List<String> _tags = [
    'Great Energy',
    'Good Conversation',
    'A bit quiet',
    'Friendly',
    'Respectful',
    'High energy',
    'Funny',
    'Polite',
  ];

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ApiService.post('/api/encounter/feedback', {
        'target_id': widget.targetUserId,
        'rating': _rating,
        'tags': _selectedTags,
        'notes': _notesCtrl.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        context.go('/home'); // Or to Life Coach
      }
    } catch (_) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit feedback'), backgroundColor: SpazzTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Post-Encounter Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpazzTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Banner
            Container(
              padding: const EdgeInsets.all(SpazzTheme.spacing16),
              decoration: BoxDecoration(
                color: SpazzTheme.accentCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium),
                border: Border.all(color: SpazzTheme.accentCyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: SpazzTheme.accentCyan),
                  const SizedBox(width: SpazzTheme.spacing12),
                  Expanded(
                    child: Text(
                      'Your feedback is strictly private. ${widget.targetUsername} will never see your responses.',
                      style: const TextStyle(color: SpazzTheme.accentCyan, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpazzTheme.spacing32),

            Text('How was your encounter with ${widget.targetUsername}?', 
                style: SpazzTheme.heading3),
            const SizedBox(height: SpazzTheme.spacing24),

            // Rating
            Center(
              child: Column(
                children: [
                  Text(_rating.toInt().toString(), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: SpazzTheme.accentPurple)),
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: SpazzTheme.accentPurple,
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Poor', style: TextStyle(color: SpazzTheme.textTertiary)),
                      Text('Amazing', style: TextStyle(color: SpazzTheme.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpazzTheme.spacing32),

            const Text('Tags', style: TextStyle(color: SpazzTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: SpazzTheme.spacing12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: SpazzTheme.accentPurple.withValues(alpha: 0.3),
                  checkmarkColor: SpazzTheme.accentPurple,
                );
              }).toList(),
            ),
            const SizedBox(height: SpazzTheme.spacing32),

            const Text('Private Notes for Dating Coach', style: TextStyle(color: SpazzTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: SpazzTheme.spacing12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Anything specific the coach should know?',
              ),
            ),
            const SizedBox(height: SpazzTheme.spacing40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
