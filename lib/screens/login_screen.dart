import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscure = true;
  bool _showPinLogin = false;
  bool _pinEnabled = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pinEnabled = prefs.getBool('pin_enabled') ?? false;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(loginProvider.notifier)
        .login(_identifier.text.trim(), _password.text);
  }

  Future<void> _biometricLogin() async {
    await ref.read(loginProvider.notifier).biometricLogin();
  }

  Future<void> _pinLogin() async {
    if (_pinCtrl.text.length != 4) return;
    await ref.read(loginProvider.notifier).pinLogin(_pinCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final hasSavedSession = ref.watch(hasSavedSessionProvider);
    final showQuickLogin = (hasSavedSession.valueOrNull ?? false) &&
        (_biometricEnabled || _pinEnabled);

    ref.listen(loginProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: C.declined,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: C.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                // Logo
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: C.approvedBg,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: C.primary.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/images/croc.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'CROC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: C.primaryDark,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'MCA Broker Dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: C.textTertiary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 40),

                // Quick login (PIN or biometric)
                if (showQuickLogin && !_showPinLogin) ...[
                  if (_biometricEnabled)
                    _QuickLoginButton(
                      icon: Icons.fingerprint,
                      label: 'Login with Biometrics',
                      loading: state.isLoading,
                      onTap: _biometricLogin,
                    ),
                  if (_biometricEnabled && _pinEnabled)
                    const SizedBox(height: 12),
                  if (_pinEnabled)
                    _QuickLoginButton(
                      icon: Icons.pin,
                      label: 'Login with PIN',
                      onTap: () => setState(() => _showPinLogin = true),
                    ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: C.grey200)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or use email', style: TextStyle(fontSize: 12, color: C.textTertiary)),
                      ),
                      Expanded(child: Divider(color: C.grey200)),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // PIN login view
                if (_showPinLogin) ...[
                  const Text('Enter your 4-digit PIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.textPrimary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 28, letterSpacing: 16, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: TextStyle(color: C.textTertiary.withValues(alpha: 0.4)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (v) {
                      if (v.length == 4) _pinLogin();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() {
                      _showPinLogin = false;
                      _pinCtrl.clear();
                    }),
                    child: const Text('Use email instead', style: TextStyle(color: C.textSecondary)),
                  ),
                  const SizedBox(height: 48),
                ] else ...[
                  // Email/password form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _identifier,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email or Username',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: C.textTertiary,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 6) ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: state.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              elevation: 2,
                              shadowColor: C.primary.withValues(alpha: 0.3),
                            ),
                            child: state.isLoading
                                ? const SizedBox(
                                    height: 22, width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text('Sign In', style: TextStyle(fontSize: 16, letterSpacing: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const _QuickLoginButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: C.grey50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: C.primary),
              )
            else
              Icon(icon, size: 24, color: C.primary),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: C.primary)),
          ],
        ),
      ),
    );
  }
}
