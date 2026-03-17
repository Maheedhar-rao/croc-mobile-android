import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lender_response.dart';
import 'realtime_provider.dart';

// All recent lender responses across all user's deals
final updatesProvider = FutureProvider<List<LenderResponse>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.isLoading) return [];

  final client = Supabase.instance.client;
  final userEmail = client.auth.currentUser?.email;
  if (userEmail == null) return [];

  // Get deal IDs for this user
  final deals = await client
      .from('deals')
      .select('id')
      .eq('user_id', userEmail);

  if (deals.isEmpty) return [];

  final dealIds = deals.map((d) => d['id'] as int).toList();

  // Only fetch offers, declines, stips — not everything
  final data = await client
      .from('email_responses')
      .select('id, deal_id, lender_name, from_email, subject, summary, ai_summary, response_type, confidence, received_at, offer_details, decline_reason, classification, stips_requested')
      .inFilter('deal_id', dealIds)
      .inFilter('response_type', ['APPROVED', 'DECLINED', 'STIPS_REQUIRED', 'approved', 'declined', 'stips_required', 'stips', 'offer', 'Approved', 'Declined'])
      .order('received_at', ascending: false)
      .limit(50);

  return data.map((r) => LenderResponse.fromJson(r)).toList();
});

// Email thread for a specific lender on a deal
final emailThreadProvider = FutureProvider.family<List<Map<String, dynamic>>,
    ({int dealId, String lenderName})>((ref, params) async {
  final client = Supabase.instance.client;

  // Fetch sent and received in parallel
  final futures = await Future.wait([
    client
        .from('deliveries')
        .select('id, lender_name, to_email, sent_subject, sent_body, status, created_at')
        .eq('deal_id', params.dealId)
        .eq('lender_name', params.lenderName)
        .order('created_at', ascending: true),
    client
        .from('email_responses')
        .select('id, deal_id, lender_name, from_email, subject, body, ai_summary, summary, response_type, received_at, offer_details, decline_reason')
        .eq('deal_id', params.dealId)
        .eq('lender_name', params.lenderName)
        .order('received_at', ascending: true),
  ]);

  final deliveries = futures[0] as List;
  final responses = futures[1] as List;

  final thread = <Map<String, dynamic>>[];

  for (final d in deliveries) {
    thread.add({
      'type': 'sent',
      'from': 'You',
      'to': d['to_email'] ?? d['lender_name'],
      'subject': d['sent_subject'] ?? '',
      'body': d['sent_body'] ?? '',
      'timestamp': d['created_at'],
    });
  }

  for (final r in responses) {
    thread.add({
      'type': 'received',
      'from': r['from_email'] ?? r['lender_name'] ?? 'Unknown',
      'to': 'You',
      'subject': r['subject'] ?? '',
      'body': r['body'] ?? r['ai_summary'] ?? r['summary'] ?? '',
      'timestamp': r['received_at'],
      'response_type': r['response_type'],
      'offer_details': r['offer_details'],
      'decline_reason': r['decline_reason'],
    });
  }

  thread.sort((a, b) {
    final aTime = a['timestamp']?.toString() ?? '';
    final bTime = b['timestamp']?.toString() ?? '';
    return aTime.compareTo(bTime);
  });

  return thread;
});
