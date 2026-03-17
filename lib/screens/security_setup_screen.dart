import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';

class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  ConsumerState<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _showPinSetup = false;
  bool _pinEnabled = false;
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  String? _pinError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    final isSupported = await auth.isDeviceSupported();
    setState(() => _biometricAvailable = canCheck && isSupported);
  }

  Future<void> _enableBiometric() async {
    setState(() => _loading = true);
    try {
      final auth = LocalAuthentication();
      final authenticated = await auth.authenticate(
        localizedReason: 'Register your biometric for quick login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        setState(() => _biometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Biometric login enabled'),
              backgroundColor: C.approved,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: C.declined,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _savePin() async {
    if (_pinCtrl.text.length != 4) {
      setState(() => _pinError = 'PIN must be 4 digits');
      return;
    }
    if (_pinCtrl.text != _confirmPinCtrl.text) {
      setState(() => _pinError = 'PINs do not match');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', _pinCtrl.text);
    await prefs.setBool('pin_enabled', true);
    setState(() {
      _pinEnabled = true;
      _pinError = null;
      _showPinSetup = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN login enabled'),
          backgroundColor: C.approved,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('security_setup_done', true);
    ref.invalidate(securitySetupDoneProvider);
    // Small delay to let provider refresh before navigating
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      context.go('/deals');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: C.approvedBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.security_rounded, size: 40, color: C.primary),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Secure Your Account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set up quick login for next time',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: C.textTertiary),
              ),
              const SizedBox(height: 36),

              // Biometric option
              if (_biometricAvailable) ...[
                _OptionCard(
                  icon: Icons.fingerprint,
                  title: 'Biometric Login',
                  subtitle: 'Use Face ID or fingerprint to login quickly',
                  enabled: _biometricEnabled,
                  loading: _loading,
                  onTap: _biometricEnabled ? null : _enableBiometric,
                ),
                const SizedBox(height: 16),
              ],

              // PIN option
              _OptionCard(
                icon: Icons.pin,
                title: 'PIN Login',
                subtitle: 'Set a 4-digit PIN as an alternative',
                enabled: _pinEnabled,
                onTap: _pinEnabled ? null : () => setState(() => _showPinSetup = !_showPinSetup),
              ),

              // PIN setup form
              if (_showPinSetup && !_pinEnabled) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: C.grey50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Create PIN',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.textPrimary)),
                      const SizedBox(height: 12),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          labelText: 'Enter PIN',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 28, letterSpacing: 16, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '••••',
                          hintStyle: TextStyle(color: C.textTertiary.withValues(alpha: 0.4)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          labelText: 'Confirm PIN',
                        ),
                      ),
                      if (_pinError != null) ...[
                        const SizedBox(height: 8),
                        Text(_pinError!, style: const TextStyle(color: C.declined, fontSize: 13)),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _savePin,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save PIN'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _finish,
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    shadowColor: C.primary.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    (_biometricEnabled || _pinEnabled) ? 'Continue' : 'Skip for now',
                    style: const TextStyle(fontSize: 16, letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!_biometricEnabled && !_pinEnabled)
                const Text(
                  'You can set this up later in settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: C.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: enabled ? C.approvedBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? C.approved : C.border,
            width: enabled ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: enabled ? C.approved.withValues(alpha: 0.15) : C.grey50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: C.primary),
                    )
                  : Icon(
                      enabled ? Icons.check_circle : icon,
                      size: 24,
                      color: enabled ? C.approved : C.primary,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: C.textTertiary)),
                ],
              ),
            ),
            if (enabled)
              const Icon(Icons.check_circle, color: C.approved, size: 22),
          ],
        ),
      ),
    );
  }
}
