import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../design/spazz_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await AuthService.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await AuthService.register(_usernameCtrl.text.trim(), _passwordCtrl.text);
      }
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signInWithGoogle();
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpazzTheme.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: SpazzTheme.spacing24, vertical: SpazzTheme.spacing40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: SpazzTheme.spacing40),
              // Logo
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(SpazzTheme.radiusXL),
                    gradient: SpazzTheme.gradientPrimary,
                  ),
                  child: const Icon(Icons.bolt, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: SpazzTheme.spacing20),
              const Center(
                child: Text('SPAZZ', style: SpazzTheme.heading2),
              ),
              const SizedBox(height: SpazzTheme.spacing48),

              // Tab switcher
              Container(
                decoration: BoxDecoration(
                  color: SpazzTheme.bgTertiary,
                  borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _tab('Login', _isLogin, () => setState(() => _isLogin = true)),
                    _tab('Join', !_isLogin, () => setState(() => _isLogin = false)),
                  ],
                ),
              ),
              const SizedBox(height: SpazzTheme.spacing24),

              // Username
              TextField(
                controller: _usernameCtrl,
                style: const TextStyle(color: SpazzTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Username',
                  prefixIcon: Icon(Icons.person_outline, color: SpazzTheme.textTertiary),
                ),
              ),
              const SizedBox(height: SpazzTheme.spacing12),

              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                style: const TextStyle(color: SpazzTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: SpazzTheme.textTertiary),
                ),
              ),
              const SizedBox(height: SpazzTheme.spacing8),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: SpazzTheme.spacing8),
                  child: Text(_error!, style: const TextStyle(color: SpazzTheme.errorRed, fontSize: 13)),
                ),
              const SizedBox(height: SpazzTheme.spacing8),

              // Submit button
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isLogin ? 'Login' : 'Create Account'),
              ),
              const SizedBox(height: SpazzTheme.spacing20),

              // Divider
              Row(children: [
                const Expanded(child: Divider(color: SpazzTheme.borderDark)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: SpazzTheme.spacing12),
                  child: Text('or', style: TextStyle(color: SpazzTheme.textTertiary)),
                ),
                const Expanded(child: Divider(color: SpazzTheme.borderDark)),
              ]),
              const SizedBox(height: SpazzTheme.spacing20),

              // Google button
              OutlinedButton.icon(
                onPressed: _loading ? null : _googleSignIn,
                style: OutlinedButton.styleFrom(
                  foregroundColor: SpazzTheme.textPrimary,
                  side: const BorderSide(color: SpazzTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium)),
                ),
                icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 22),
                label: const Text('Continue with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: SpazzTheme.spacing8),
          decoration: BoxDecoration(
            color: active ? SpazzTheme.accentPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(SpazzTheme.radiusMedium),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? SpazzTheme.textPrimary : SpazzTheme.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
