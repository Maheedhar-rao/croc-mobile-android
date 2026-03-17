import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          final isOffer = responseType.contains('APPROV') || responseType == 'OFFER';
          final isDecline = responseType.contains('DECLIN') || responseType == 'PASS';
          final isStips = responseType.contains('STIP');

          if (!isOffer && !isDecline && !isStips) return;

          final lenderName = record['lender_name'] ?? record['from_email'] ?? 'A lender';
          final dealId = record['deal_id'];

          debugPrint('[realtime] $responseType from $lenderName for deal $dealId');

          final label = isOffer ? 'OFFER' : isDecline ? 'DECLINED' : 'STIPS REQUESTED';

          // Fetch business name async without blocking
          _fetchAndNotify(client, dealId, lenderName.toString(), label);

          // Invalidate providers to refresh UI
          ref.invalidate(updatesProvider);
          ref.invalidate(dealsProvider);
        },
      )
      .subscribe((status, error) {
    debugPrint('[realtime] Channel status: $status, error: $error');
  });

  ref.onDispose(() {
    debugPrint('[realtime] Disposing channel');
    channel.unsubscribe();
  });
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

Future<void> _fetchAndNotify(
  SupabaseClient client,
  dynamic dealId,
  String lenderName,
  String label,
) async {
  String businessName = '';
  try {
    if (dealId != null) {
      final deal = await client
          .from('deals')
          .select('business_name, subject')
          .eq('id', dealId)
          .maybeSingle();
      if (deal != null) {
        final bn = deal['business_name']?.toString().trim() ?? '';
        final subj = deal['subject']?.toString().trim() ?? '';
        businessName = bn.isNotEmpty ? bn : subj.isNotEmpty ? subj : '';
      }
    }
  } catch (e) {
    debugPrint('[realtime] Failed to fetch deal info: $e');
  }

  final nameDisplay = businessName.isNotEmpty ? businessName : 'Deal #$dealId';

  _showNotification(
    title: '$lenderName — $label',
    body: '#$dealId · $nameDisplay',
  );
}

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
