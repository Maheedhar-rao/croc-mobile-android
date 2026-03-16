import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/env.dart';
import 'providers/realtime_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  await initNotifications();

  // OneSignal init
  if (Env.oneSignalAppId.isNotEmpty) {
    OneSignal.initialize(Env.oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);
  }

  runApp(const ProviderScope(child: CrocApp()));
}
