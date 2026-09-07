import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../design/spazz_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic> _prefs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userRes = await ApiService.get('/api/me');
      final prefRes = await AuthService.getPreferences();
      setState(() {
        _user = userRes;
        _prefs = prefRes;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updatePref(String key, dynamic value) async {
    final Map<String, dynamic> update = {key: value};
    await AuthService.updatePreferences(
      gender: key == 'gender' ? value : null,
      age: key == 'age' ? value : null,
      interestedIn: key == 'interested_in' ? value : null,
      minAge: key == 'min_age' ? value : null,
      maxAge: key == 'max_age' ? value : null,
      isBroadcasting: key == 'is_broadcasting' ? value : null,
    );
    setState(() {
      _prefs[key] = value;
    });
  }

  Future<void> _logout() async {
    await AuthService.clearSession();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: SpazzTheme.bgSecondary,
        title: const Text('Profile', style: TextStyle(color: SpazzTheme.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: SpazzTheme.textTertiary),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SpazzTheme.accentPurple))
          : _user == null
              ? const Center(child: Text('Failed to load', style: TextStyle(color: SpazzTheme.textPrimary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(SpazzTheme.spacing24),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SpazzTheme.gradientPrimary,
                        ),
                        child: Center(
                          child: Text(
                            (_user!['username'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: SpazzTheme.spacing16),
                      Text(_user!['username'] ?? '', style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: SpazzTheme.textPrimary,
                      )),
                      const SizedBox(height: SpazzTheme.spacing32),
                      
                      // Stats
                      _statsGrid(),
                      
                      const SizedBox(height: SpazzTheme.spacing32),
                      
                      // Dating Preferences Section
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('DATING PREFERENCES', style: TextStyle(
                          color: SpazzTheme.textTertiary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                        )),
                      ),
                      const SizedBox(height: SpazzTheme.spacing16),
                      
                      _prefTile('My Gender', _prefs['gender'], ['Male', 'Female', 'Other'], (v) => _updatePref('gender', v)),
                      _prefTile('Interested In', _prefs['interested_in'], ['Male', 'Female', 'Both'], (v) => _updatePref('interested_in', v)),
                      
                      const SizedBox(height: SpazzTheme.spacing16),
                      _ageSlider(),
                    ],
                  ),
                ),
    );
  }

  Widget _prefTile(String label, String value, List<String> options, Function(String) onSelect) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpazzTheme.spacing12),
      padding: const EdgeInsets.symmetric(horizontal: SpazzTheme.spacing16, vertical: SpazzTheme.spacing8),
      decoration: BoxDecoration(
        color: SpazzTheme.bgSecondary,
        borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium),
        border: Border.all(color: SpazzTheme.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: SpazzTheme.textSecondary)),
          DropdownButton<String>(
            value: options.contains(value) ? value : options[0],
            dropdownColor: SpazzTheme.bgSecondary,
            underline: const SizedBox(),
            items: options.map((o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: const TextStyle(color: SpazzTheme.accentCyan, fontWeight: FontWeight.bold)),
            )).toList(),
            onChanged: (v) { if (v != null) onSelect(v); },
          ),
        ],
      ),
    );
  }

  Widget _ageSlider() {
    double min = (_prefs['min_age'] ?? 18).toDouble();
    double max = (_prefs['max_age'] ?? 99).toDouble();
    
    return Container(
      padding: const EdgeInsets.all(SpazzTheme.spacing16),
      decoration: BoxDecoration(
        color: SpazzTheme.bgSecondary,
        borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium),
        border: Border.all(color: SpazzTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Age Range', style: TextStyle(color: SpazzTheme.textSecondary)),
              Text('${min.toInt()} - ${max.toInt()}', style: const TextStyle(color: SpazzTheme.accentCyan, fontWeight: FontWeight.bold)),
            ],
          ),
          RangeSlider(
            values: RangeValues(min, max),
            min: 18,
            max: 99,
            activeColor: SpazzTheme.accentCyan,
            inactiveColor: SpazzTheme.bgTertiary,
            onChanged: (RangeValues values) {
              _updatePref('min_age', values.start.toInt());
              _updatePref('max_age', values.end.toInt());
            },
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final stats = [
      {'label': 'Wisps', 'value': _user!['wisps_collected']?.toString() ?? '0', 'icon': Icons.bolt},
      {'label': 'Coins', 'value': _user!['credits']?.toString() ?? '0', 'icon': Icons.monetization_on},
      {'label': 'Steps', 'value': _user!['steps']?.toString() ?? '0', 'icon': Icons.directions_walk},
      {'label': 'Level', 'value': _user!['level']?.toString() ?? '1', 'icon': Icons.star},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: SpazzTheme.spacing12, mainAxisSpacing: SpazzTheme.spacing12, childAspectRatio: 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        return Container(
          decoration: BoxDecoration(
            color: SpazzTheme.bgSecondary,
            borderRadius: BorderRadius.circular(SpazzTheme.radiusLarge),
            border: Border.all(color: SpazzTheme.borderDark),
          ),
          padding: const EdgeInsets.all(SpazzTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(s['icon'] as IconData, color: SpazzTheme.accentPurple, size: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['value'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: SpazzTheme.textPrimary)),
                  Text(s['label'] as String, style: const TextStyle(fontSize: 12, color: SpazzTheme.textTertiary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
