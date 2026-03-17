import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/deal.dart';
import '../models/delivery.dart';
import '../models/lender_response.dart';
import 'realtime_provider.dart';

// ── Deals list — fast, light query ──

final dealsProvider = FutureProvider<List<Deal>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.isLoading) return [];

  final client = Supabase.instance.client;
  final userEmail = client.auth.currentUser?.email;
  if (userEmail == null) return [];

  final data = await client
      .from('deals')
      .select('id, user_id, sender_email, subject, business_name, mode, status, created_at, resend_count, send_status, send_summary, funded_amount, funded_lender, funded_at')
      .eq('user_id', userEmail)
      .order('created_at', ascending: false)
      .limit(100);

  return data.map((d) => Deal.fromJson(d)).toList();
});

// ── Deal detail — single row, includes application_json ──

final dealDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, dealId) async {
  final client = Supabase.instance.client;
  return await client.from('deals').select().eq('id', dealId).single();
});

// ── Deliveries for a deal ──

final deliveriesProvider =
    FutureProvider.family<List<Delivery>, int>((ref, dealId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('deliveries')
      .select('id, lender_name, to_email, cc_csv, status, business_name, tracking_status, response_received, response_type, created_at')
      .eq('deal_id', dealId)
      .order('created_at', ascending: false);
  return data.map((d) => Delivery.fromJson(d)).toList();
});

// ── Lender responses for a deal ──

final responsesProvider =
    FutureProvider.family<List<LenderResponse>, int>((ref, dealId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('email_responses')
      .select('id, deal_id, lender_name, from_email, subject, summary, ai_summary, response_type, confidence, received_at, offer_details, decline_reason, classification, stips_requested')
      .eq('deal_id', dealId)
      .order('received_at', ascending: false);
  return data.map((r) => LenderResponse.fromJson(r)).toList();
});
