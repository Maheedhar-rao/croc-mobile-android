import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _obscure = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final biometricAvailable = ref.watch(biometricAvailableProvider);
    final hasSavedSession = ref.watch(hasSavedSessionProvider);

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

    final showBiometric = (biometricAvailable.valueOrNull ?? false) &&
        (hasSavedSession.valueOrNull ?? false);

    return Scaffold(
      backgroundColor: C.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Form(
              key: _formKey,
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
                  const SizedBox(height: 44),
                  // Email/Username
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
                  // Password
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
                  // Sign In
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
                  // Biometric
                  if (showBiometric) ...[
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: C.grey200)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: TextStyle(fontSize: 12, color: C.textTertiary)),
                        ),
                        Expanded(child: Divider(color: C.grey200)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: state.isLoading ? null : _biometricLogin,
                        icon: const Icon(Icons.fingerprint, size: 24),
                        label: const Text('Use Biometrics'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: C.primary,
                          side: const BorderSide(color: C.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
