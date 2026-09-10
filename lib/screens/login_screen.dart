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
  bool _keepLoggedIn = true;
  bool _obscurePassword = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 10, 17, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 107,
                width: 235,
                child: Image.asset(
                  '.Figma/Make/assets/images/spazz_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 49),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Move.Discover.', style: _loginHeadline),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Connect.', style: _loginHeadline),
              ),
              const SizedBox(height: 34),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isLogin ? 'Enter Login Name:' : 'Choose Login Name:',
                  style: _fieldLabel,
                ),
              ),
              const SizedBox(height: 15),
              _loginField(
                controller: _usernameCtrl,
                hintText: 'Login name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isLogin ? 'Enter Login Password:' : 'Choose Login Password:',
                  style: _fieldLabel,
                ),
              ),
              const SizedBox(height: 15),
              _loginField(
                controller: _passwordCtrl,
                hintText: 'Login password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_error!, style: const TextStyle(color: SpazzTheme.errorRed, fontSize: 13)),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _keepLoggedIn,
                    onChanged: (value) => setState(() => _keepLoggedIn = value ?? false),
                    activeColor: _loginCyan,
                    side: const BorderSide(color: _loginCyan),
                  ),
                  const Text('Keep me logged in:', style: _fieldLabel),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _loginCyan,
                    foregroundColor: const Color(0xFF0B0F14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(33)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B0F14)))
                      : Text(_isLogin ? 'Login' : 'Create Profile', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot Password?', style: TextStyle(color: _loginCyan, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 150),
              Text(
                _isLogin ? 'New? Create New Profile and Join the Grid!' : 'Already have a profile?',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _loginCyan, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(33)),
                    foregroundColor: _loginCyan,
                  ),
                  child: Text(_isLogin ? 'Create Profile' : 'Back to Login', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF111827),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2937)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _loginCyan),
        ),
      ),
    );
  }
}

const Color _loginCyan = Color(0xFF00EEFF);
const TextStyle _loginHeadline = TextStyle(
  color: _loginCyan,
  fontSize: 37,
  fontWeight: FontWeight.w800,
  height: 1.05,
);
const TextStyle _fieldLabel = TextStyle(
  color: Color(0xFF94A3B8),
  fontSize: 12,
  fontWeight: FontWeight.w600,
);
