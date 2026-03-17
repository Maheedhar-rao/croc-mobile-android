import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

SupabaseClient get _supabase => Supabase.instance.client;

// ── Check if security setup screen was completed ──

final securitySetupDoneProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('security_setup_done') ?? false;
});

// ── App locked state ──
// Starts locked if user has PIN/biometric and a session exists

final appLockedProvider =
    AsyncNotifierProvider<AppLockedNotifier, bool>(AppLockedNotifier.new);

class AppLockedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    final session = _supabase.auth.currentSession;
    final hasSecurity = (prefs.getBool('biometric_enabled') ?? false) ||
        (prefs.getBool('pin_enabled') ?? false);
    // Locked if: has session + has security setup (meaning user was previously logged in)
    return session != null && hasSecurity;
  }

  Future<void> lock() async {
    state = const AsyncData(true);
  }

  Future<void> unlock() async {
    state = const AsyncData(false);
  }
}

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

      // Unlock
      await ref.read(appLockedProvider.notifier).unlock();
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

      // Unlock
      await ref.read(appLockedProvider.notifier).unlock();
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

      // Unlock
      await ref.read(appLockedProvider.notifier).unlock();
      debugPrint('[auth] PIN login successful');
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSecurity = (prefs.getBool('biometric_enabled') ?? false) ||
        (prefs.getBool('pin_enabled') ?? false);

    if (hasSecurity) {
      // Just lock — session stays, user unlocks with PIN/biometric
      await ref.read(appLockedProvider.notifier).lock();
    } else {
      // Full sign out
      if (Env.oneSignalAppId.isNotEmpty) {
        OneSignal.logout();
      }
      await _supabase.auth.signOut();
    }
  }
}
