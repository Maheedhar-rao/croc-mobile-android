import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../models/psf.dart';
import 'auth_provider.dart';

// ── PSF list ──

final psfListProvider = FutureProvider<List<Psf>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.isLoading) return [];

  final client = Supabase.instance.client;
  final userEmail = client.auth.currentUser?.email;
  if (userEmail == null) return [];

  debugPrint('[psf] Fetching PSFs created_by=$userEmail');

  try {
    final data = await client
        .from('psf_agreements')
        .select()
        .eq('created_by', userEmail)
        .order('created_at', ascending: false)
        .limit(100);

    debugPrint('[psf] Fetched ${data.length} PSFs');
    return data.map((d) => Psf.fromJson(d)).toList();
  } catch (e) {
    debugPrint('[psf] ERROR: $e');
    rethrow;
  }
});

// ── PSF agreements for a specific deal ──

final psfByDealProvider =
    FutureProvider.family<List<Psf>, int>((ref, dealId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('psf_agreements')
      .select()
      .eq('deal_id', dealId)
      .order('created_at', ascending: false);
  return data.map((d) => Psf.fromJson(d)).toList();
});

// ── Send PSF via Flask API ──

final sendPsfProvider =
    AutoDisposeAsyncNotifierProvider<SendPsfNotifier, Map<String, dynamic>?>(
        SendPsfNotifier.new);

class SendPsfNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async => null;

  Future<void> send({
    required int dealId,
    required double amount,
    required String bankName,
    required String routingNumber,
    required String accountNumber,
    String? holderName,
    String? holderDba,
    String? signerEmail,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Not authenticated');

      final body = <String, dynamic>{
        'deal_id': dealId,
        'amount': amount,
        'bank_name': bankName,
        'routing_number': routingNumber,
        'account_number': accountNumber,
      };

      if (holderName != null && holderName.trim().isNotEmpty) {
        body['override_holder_name'] = holderName.trim();
      }
      if (holderDba != null && holderDba.trim().isNotEmpty) {
        body['override_holder_dba'] = holderDba.trim();
      }
      if (signerEmail != null && signerEmail.trim().isNotEmpty) {
        body['override_signer_email'] = signerEmail.trim();
      }

      debugPrint('[psf] Sending PSF: $body');

      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/api/psf/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode(body),
      );

      debugPrint('[psf] Response ${response.statusCode}: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to send PSF');
      }

      // Invalidate list to refresh
      ref.invalidate(psfListProvider);

      return data;
    });
  }
}
