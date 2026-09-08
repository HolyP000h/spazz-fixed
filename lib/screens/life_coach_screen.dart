import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design/spazz_theme.dart';
import '../services/api_service.dart';

class LifeCoachScreen extends StatefulWidget {
  const LifeCoachScreen({super.key});

  @override
  State<LifeCoachScreen> createState() => _LifeCoachScreenState();
}

class _LifeCoachScreenState extends State<LifeCoachScreen> {
  bool _loading = true;
  Map<String, dynamic> _status = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/api/coach/status');
      setState(() {
        _status = res;
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
        title: const Text('AI Dating Coach'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SpazzTheme.accentPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(SpazzTheme.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coach Header
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SpazzTheme.gradientPrimary,
                        ),
                        child: const Center(child: Text('🧠', style: TextStyle(fontSize: 32))),
                      ),
                      const SizedBox(width: SpazzTheme.spacing16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dating Coach AI', style: SpazzTheme.heading3),
                            Text('Analyzing your rizz...', style: TextStyle(color: SpazzTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpazzTheme.spacing32),

                  // The Main Nudge (Encouragement)
                  _buildCoachCard(
                    title: 'Today\'s Motivation',
                    content: _status['main_nudge'] ?? 'Lets make today the 1st day of our new lives!',
                    icon: Icons.lightbulb_outline,
                    color: SpazzTheme.accentCyan,
                  ),
                  const SizedBox(height: SpazzTheme.spacing20),

                  // Pinpoints (Specific Tips from Feedback)
                  const Text('SPECIFIC FOCUS AREAS', style: TextStyle(
                    color: SpazzTheme.textTertiary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                  )),
                  const SizedBox(height: SpazzTheme.spacing12),
                  ...(_status['pinpoints'] as List? ?? []).map((tip) => _buildTipTile(tip)),
                  
                  const SizedBox(height: SpazzTheme.spacing32),

                  // Lifestyle Goals
                  const Text('LIFESTYLE GOALS', style: TextStyle(
                    color: SpazzTheme.textTertiary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                  )),
                  const SizedBox(height: SpazzTheme.spacing12),
                  ...(_status['goals'] as List? ?? []).map((goal) => _buildGoalCard(goal)),
                ],
              ),
            ),
    );
  }

  Widget _buildCoachCard({required String title, required String content, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(SpazzTheme.spacing20),
      decoration: BoxDecoration(
        color: SpazzTheme.bgSecondary,
        borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.4, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildTipTile(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpazzTheme.spacing8),
      padding: const EdgeInsets.all(SpazzTheme.spacing16),
      decoration: BoxDecoration(
        color: SpazzTheme.bgSecondary,
        borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: SpazzTheme.accentPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: SpazzTheme.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final progress = (goal['progress'] as num? ?? 0.0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: SpazzTheme.spacing16),
      padding: const EdgeInsets.all(SpazzTheme.spacing16),
      decoration: BoxDecoration(
        color: SpazzTheme.bgSecondary,
        borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium),
        border: Border.all(color: SpazzTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(goal['description'] ?? '', style: const TextStyle(color: SpazzTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: SpazzTheme.bgPrimary,
            valueColor: const AlwaysStoppedAnimation(SpazzTheme.accentCyan),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text('${(progress * 100).toInt()}% Complete', style: const TextStyle(color: SpazzTheme.accentCyan, fontSize: 11)),
        ],
      ),
    );
  }
}
