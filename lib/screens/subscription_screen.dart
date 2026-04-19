import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isPremium = false;
  bool _loading = true;
  bool _purchasing = false;
  String _selectedPlan = 'monthly';
  String _token = '';
  String _userId = '';

  // IAP
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _iapSub;
  List<ProductDetails> _products = [];
  bool _iapAvailable = false;

  // Product IDs — must match exactly what you create in App Store Connect / Google Play
  static const String _monthlyId = 'spazz_premium_monthly';
  static const String _yearlyId = 'spazz_premium_yearly';
  static const _productIds = {_monthlyId, _yearlyId};

  static const _baseUrl = 'https://www.spazzapp.com';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _userId = prefs.getString('user_id') ?? '';

    // Check existing premium status
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/user/$_userId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => _isPremium = data['is_premium'] ?? false);
      }
    } catch (_) {}

    // Set up IAP
    _iapAvailable = await _iap.isAvailable();
    if (_iapAvailable) {
      // Listen for purchase updates
      _iapSub = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _iapSub?.cancel(),
        onError: (e) => _showError('Purchase error: $e'),
      );
      await _loadProducts();
    }

    setState(() => _loading = false);
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP products not found: ${response.notFoundIDs}');
    }
    setState(() => _products = response.productDetails);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _activatePremium(purchase.productID);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        _showError(purchase.error?.message ?? 'Purchase failed');
        setState(() => _purchasing = false);
      } else if (purchase.status == PurchaseStatus.canceled) {
        setState(() => _purchasing = false);
      }
    }
  }

  Future<void> _activatePremium(String productId) async {
    final plan = productId == _yearlyId ? 'yearly' : 'monthly';
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/subscribe'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'user_id': _userId, 'plan': plan}),
      );
    } catch (_) {}

    // Save locally too
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);

    setState(() {
      _isPremium = true;
      _purchasing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Welcome to Spazz Premium!'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
    }
  }

  Future<void> _buy() async {
    if (_purchasing) return;
    setState(() => _purchasing = true);

    final targetId = _selectedPlan == 'yearly' ? _yearlyId : _monthlyId;

    if (_iapAvailable && _products.isNotEmpty) {
      // Real IAP purchase
      final product = _products.firstWhere(
        (p) => p.id == targetId,
        orElse: () => _products.first,
      );
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      // Result comes via purchaseStream listener
    } else {
      // Fallback: direct backend activation (dev/testing mode)
      await _activatePremium(targetId);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _loading = true);
    await _iap.restorePurchases();
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking your purchases...'),
        backgroundColor: Color(0xFF1E1E2E),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
    );
  }

  // Get real price from App Store / Play Store if available
  String _getPrice(String planKey) {
    final targetId = planKey == 'yearly' ? _yearlyId : _monthlyId;
    try {
      final product = _products.firstWhere((p) => p.id == targetId);
      return product.price;
    } catch (_) {
      return planKey == 'yearly' ? '\$19.99' : '\$2.99';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131A),
        title: const Text('Spazz Premium',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : _isPremium
              ? _PremiumActiveView(onRestore: _restorePurchases)
              : _UpgradeView(
                  selectedPlan: _selectedPlan,
                  monthlyPrice: _getPrice('monthly'),
                  yearlyPrice: _getPrice('yearly'),
                  purchasing: _purchasing,
                  onPlanSelected: (p) => setState(() => _selectedPlan = p),
                  onSubscribe: _buy,
                  onRestore: _restorePurchases,
                ),
    );
  }
}

// ── PREMIUM ACTIVE VIEW ───────────────────────────────────────────

class _PremiumActiveView extends StatelessWidget {
  final VoidCallback onRestore;
  const _PremiumActiveView({required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(child: Text('👑', style: TextStyle(fontSize: 48))),
          ),
          const SizedBox(height: 24),
          const Text("You're Premium!",
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('All exclusive features unlocked',
              style: TextStyle(color: Color(0xFF888899), fontSize: 15)),
          const SizedBox(height: 32),
          ..._features.map((f) => _FeatureRow(emoji: f[0], title: f[1], desc: f[2])),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onRestore,
            child: const Text('Restore Purchase',
                style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }
}

// ── UPGRADE VIEW ─────────────────────────────────────────────────

class _UpgradeView extends StatelessWidget {
  final String selectedPlan;
  final String monthlyPrice;
  final String yearlyPrice;
  final bool purchasing;
  final Function(String) onPlanSelected;
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;

  const _UpgradeView({
    required this.selectedPlan,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.purchasing,
    required this.onPlanSelected,
    required this.onSubscribe,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(child: Text('👑', style: TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 20),
          const Text('Spazz Premium',
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Unlock the full Spazz experience',
              style: TextStyle(color: Color(0xFF888899), fontSize: 15)),
          const SizedBox(height: 28),

          // Features list
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E1E2E)),
            ),
            child: Column(
              children: _features
                  .map((f) => _FeatureRow(emoji: f[0], title: f[1], desc: f[2]))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Choose a plan',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          // Monthly plan
          _PlanCard(
            label: 'Monthly',
            price: monthlyPrice,
            period: 'per month',
            savings: null,
            isSelected: selectedPlan == 'monthly',
            onTap: () => onPlanSelected('monthly'),
          ),
          const SizedBox(height: 10),

          // Yearly plan
          _PlanCard(
            label: 'Yearly',
            price: yearlyPrice,
            period: 'per year',
            savings: 'Save 44%',
            isSelected: selectedPlan == 'yearly',
            onTap: () => onPlanSelected('yearly'),
          ),
          const SizedBox(height: 24),

          // Subscribe button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: purchasing ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: purchasing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Start Premium',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Cancel anytime. No hidden fees.',
              style: TextStyle(color: Color(0xFF888899), fontSize: 12)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onRestore,
            child: const Text('Restore Purchase',
                style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 13,
                    decoration: TextDecoration.underline)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────

const _features = [
  ['🔥', 'Hotspot Heatmap', 'See where users gather most in real time'],
  ['📊', 'Activity Insights', 'Detailed stats on wisp hotspots near you'],
  ['⚡', 'Wisp Radar Boost', 'Detect wisps from 2x the distance'],
  ['🎯', 'Exclusive Hunts', 'Access premium-only wisp events'],
  ['🚫', 'Ad Free', 'Clean, distraction-free experience'],
];

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String period;
  final String? savings;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    required this.price,
    required this.period,
    required this.savings,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF1E1E2E),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF444460),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(period,
                      style: const TextStyle(color: Color(0xFF888899), fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                if (savings != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(savings!,
                        style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;

  const _FeatureRow({required this.emoji, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(desc,
                    style: const TextStyle(color: Color(0xFF888899), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF7C3AED), size: 20),
        ],
      ),
    );
  }
}
