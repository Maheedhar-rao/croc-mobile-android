import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider.dart';
import 'deals_provider.dart';
import 'updates_provider.dart';

final _notifications = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwin = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await _notifications.initialize(
    const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
  );
}

final realtimeProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  if (authState.isLoading || user == null) return;

  final userEmail = user.email;
  if (userEmail == null) return;

  debugPrint('[realtime] Setting up listener for $userEmail');

  // Listen for new email_responses on user's deals
  final channel = client
      .channel('mobile_responses')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'email_responses',
        callback: (payload) {
          final record = payload.newRecord;
          final responseType = (record['response_type'] ?? '').toString().toUpperCase();

          // Only notify on offers, declines, and stips
          final isOffer = responseType.contains('APPROV');
          final isDecline = responseType.contains('DECLIN');
          final isStips = responseType.contains('STIP');

          if (!isOffer && !isDecline && !isStips) return;

          final lenderName = record['lender_name'] ?? record['from_email'] ?? 'A lender';
          final dealId = record['deal_id'];

          debugPrint('[realtime] $responseType from $lenderName for deal $dealId');

          final label = isOffer ? 'OFFER' : isDecline ? 'DECLINED' : 'STIPS REQUESTED';

          _showNotification(
            title: '$lenderName — $label',
            body: isOffer
                ? 'Deal #$dealId received an offer!'
                : isDecline
                    ? 'Deal #$dealId was declined.'
                    : 'Deal #$dealId has stips requested.',
          );

          // Invalidate providers to refresh UI
          ref.invalidate(updatesProvider);
          ref.invalidate(dealsProvider);
        },
      )
      .subscribe();

  ref.onDispose(() {
    debugPrint('[realtime] Disposing channel');
    channel.unsubscribe();
  });
});

Future<void> _showNotification({
  required String title,
  required String body,
}) async {
  const android = AndroidNotificationDetails(
    'croc_responses',
    'Lender Responses',
    channelDescription: 'Notifications for new lender responses',
    importance: Importance.high,
    priority: Priority.high,
  );

  const darwin = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  await _notifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(android: android, iOS: darwin, macOS: darwin),
  );
}
