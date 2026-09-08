import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../design/spazz_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class BlessWispScreen extends StatefulWidget {
  const BlessWispScreen({super.key});

  @override
  State<BlessWispScreen> createState() => _BlessWispScreenState();
}

class _BlessWispScreenState extends State<BlessWispScreen> {
  double _amount = 1.0;
  final _msgCtrl = TextEditingController();
  bool _submitting = false;
  bool _bankLinked = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkBankLink();
  }

  Future<void> _checkBankLink() async {
    final linked = await AuthService.isBankLinked();
    setState(() {
      _bankLinked = linked;
      _loading = false;
    });
  }

  Future<void> _linkBank() async {
    setState(() => _loading = true);
    // Simulate linking process
    await Future.delayed(const Duration(seconds: 2));
    await AuthService.linkBank(true);
    setState(() {
      _bankLinked = true;
      _loading = false;
    });
  }

  Future<void> _blessWisp() async {
    if (!_bankLinked) return;

    setState(() => _submitting = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      await ApiService.post('/api/wisp/bless', {
        'amount': _amount,
        'message': _msgCtrl.text,
        'lat': pos.latitude,
        'lng': pos.longitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Wisp blessed with \$$_amount!'),
            backgroundColor: Colors.amber,
          ),
        );
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to bless wisp'), backgroundColor: SpazzTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Bless a Wisp'),
        leading: IconButton(
          icon: const Icon(Icons.close),
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
                const Text('✨ Pin Actual Money', style: SpazzTheme.heading3),
                const SizedBox(height: 8),
                const Text(
                  'Bless a random stranger or pay for a couple\'s date. Pin money to your current location for someone to find!',
                  style: TextStyle(color: SpazzTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),

                if (!_bankLinked)
                  _buildLinkBankCard()
                else ...[
                  _buildAmountSelector(),
                  const SizedBox(height: 32),
                  const Text('Add a Message (Optional)', style: TextStyle(color: SpazzTheme.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _msgCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Enjoy this blessing!',
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _blessWisp,
                      icon: const Icon(Icons.stars),
                      label: Text(_submitting ? 'Processing...' : 'Pin \$$_amount Blessing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: SpazzTheme.spacing16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildLinkBankCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SpazzTheme.bgSecondary,
        borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
        border: Border.all(color: SpazzTheme.accentCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance, color: SpazzTheme.accentCyan, size: 48),
          const SizedBox(height: 16),
          const Text('Link Bank Account', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'To pin actual money, you need to securely link a bank or card account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SpazzTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _linkBank,
            style: ElevatedButton.styleFrom(backgroundColor: SpazzTheme.accentCyan),
            child: const Text('Connect with Plaid', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSelector() {
    final amounts = [1, 5, 10, 20, 50, 100];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Blessing Amount', style: TextStyle(color: SpazzTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: amounts.map((a) {
            final isSelected = _amount == a.toDouble();
            return ChoiceChip(
              label: Text('\$$a', style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              selected: isSelected,
              onSelected: (v) { if (v) setState(() => _amount = a.toDouble()); },
              selectedColor: Colors.amber,
              backgroundColor: SpazzTheme.bgTertiary,
            );
          }).toList(),
        ),
      ],
    );
  }
}
