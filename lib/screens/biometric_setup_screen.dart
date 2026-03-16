import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _biometricAvailable = false;
  bool _settingUp = false;
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  String? _pinError;
  bool _showPinSetup = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _pin1.dispose();
    _pin2.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    final isSupported = await auth.isDeviceSupported();
    setState(() => _biometricAvailable = canCheck && isSupported);
  }

  Future<void> _setupBiometric() async {
    setState(() => _settingUp = true);
    try {
      final auth = LocalAuthentication();
      final authenticated = await auth.authenticate(
        localizedReason: 'Register your biometrics for quick login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        await prefs.setBool('has_saved_session', true);
        if (mounted) _complete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric setup failed: $e'), backgroundColor: C.declined),
        );
      }
    }
    setState(() => _settingUp = false);
  }

  Future<void> _savePin() async {
    if (_pin1.text.length != 4) {
      setState(() => _pinError = 'Enter 4 digits');
      return;
    }
    if (_pin1.text != _pin2.text) {
      setState(() => _pinError = 'PINs do not match');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', _pin1.text);
    await prefs.setBool('pin_enabled', true);
    await prefs.setBool('has_saved_session', true);
    if (mounted) _complete();
  }

  void _complete() {
    Navigator.of(context).pop(true);
  }

  void _skip() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: C.approvedBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.security_rounded, size: 40, color: C.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Secure Your Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: C.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set up quick login for next time',
                style: TextStyle(fontSize: 14, color: C.textSecondary),
              ),
              const SizedBox(height: 40),

              if (!_showPinSetup) ...[
                // Biometric option
                if (_biometricAvailable)
                  _OptionButton(
                    icon: Icons.fingerprint,
                    title: 'Use Biometrics',
                    subtitle: 'Face ID or Fingerprint',
                    loading: _settingUp,
                    onTap: _setupBiometric,
                  ),
                if (_biometricAvailable) const SizedBox(height: 12),
                // PIN option
                _OptionButton(
                  icon: Icons.pin,
                  title: 'Set a 4-Digit PIN',
                  subtitle: 'Quick unlock code',
                  onTap: () => setState(() => _showPinSetup = true),
                ),
              ] else ...[
                // PIN setup form
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Create PIN',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.textSecondary)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pin1,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: TextStyle(color: C.textTertiary.withValues(alpha: 0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Confirm PIN',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.textSecondary)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pin2,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: TextStyle(color: C.textTertiary.withValues(alpha: 0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                if (_pinError != null) ...[
                  const SizedBox(height: 8),
                  Text(_pinError!, style: const TextStyle(color: C.declined, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savePin,
                    child: const Text('Save PIN'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _showPinSetup = false;
                    _pinError = null;
                    _pin1.clear();
                    _pin2.clear();
                  }),
                  child: const Text('Back', style: TextStyle(color: C.textSecondary)),
                ),
              ],

              const Spacer(flex: 3),
              // Skip
              if (!_showPinSetup)
                TextButton(
                  onPressed: _skip,
                  child: const Text('Skip for now',
                      style: TextStyle(color: C.textTertiary, fontSize: 14)),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool loading;

  const _OptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: C.grey50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: C.approvedBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: C.primary),
                    )
                  : Icon(icon, size: 24, color: C.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: C.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: C.textTertiary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: C.textTertiary),
          ],
        ),
      ),
    );
  }
}
