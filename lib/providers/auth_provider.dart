import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

SupabaseClient get _supabase => Supabase.instance.client;

// ── Biometric support ──

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final auth = LocalAuthentication();
  final canCheck = await auth.canCheckBiometrics;
  final isSupported = await auth.isDeviceSupported();
  return canCheck && isSupported;
});

// ── Check if security is set up (biometric or PIN) ──

final securitySetupDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getBool('biometric_enabled') ?? false) ||
      (prefs.getBool('pin_enabled') ?? false);
});

// ── Login controller ──

final loginProvider =
    AutoDisposeAsyncNotifierProvider<LoginNotifier, void>(LoginNotifier.new);

class LoginNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> login(String identifier, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      String email = identifier;

      await _supabase.auth.signInWithPassword(email: email, password: password);

      // Tag user in OneSignal for targeted push
      if (Env.oneSignalAppId.isNotEmpty) {
        OneSignal.login(email);
        OneSignal.User.addEmail(email);
        OneSignal.User.addTagWithKey('user_email', email);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      await prefs.setBool('has_saved_session', true);
    });
  }

  Future<void> biometricLogin() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = LocalAuthentication();
      final authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access CROC',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (!authenticated) throw Exception('Authentication failed');

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No saved session. Please login with email first.');
      }

      debugPrint('[auth] Biometric login successful');
    });
  }

  Future<void> pinLogin(String pin) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('app_pin');

      if (savedPin == null || savedPin != pin) {
        throw Exception('Incorrect PIN');
      }

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No saved session. Please login with email first.');
      }

      debugPrint('[auth] PIN login successful');
    });
  }

  Future<void> logout() async {
    if (Env.oneSignalAppId.isNotEmpty) {
      OneSignal.logout();
    }
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_saved_session', false);
  }
}

// ── Check if user has a saved session for biometric/PIN login ──

final hasSavedSessionProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final hasSaved = prefs.getBool('has_saved_session') ?? false;
  final session = _supabase.auth.currentSession;
  return hasSaved && session != null;
});
