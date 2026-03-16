import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/deal.dart';
import '../providers/deals_provider.dart';
import '../widgets/croc_loader.dart';

// Funded deals = deals that have at least one APPROVED response
final fundedDealsProvider = FutureProvider<List<Deal>>((ref) async {
  final allDeals = await ref.watch(dealsProvider.future);
  // Filter to deals that are funded (have approved responses)
  // We check the deal data — funded deals typically have a status or flag
  // For now we show deals that have sent_count > 0 and are marked funded
  // This can be refined based on actual Supabase schema
  return allDeals;
});

class FundedScreen extends ConsumerWidget {
  const FundedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(dealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Funded')),
      body: dealsAsync.when(
        loading: () => const Center(
          child: CrocLoader(message: 'Loading funded deals...'),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e', style: const TextStyle(color: C.textSecondary)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.invalidate(dealsProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (deals) {
          final funded = deals.where((d) => d.isFunded).toList();

          if (funded.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: C.approvedBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.celebration_outlined,
                        size: 28, color: C.approved),
                  ),
                  const SizedBox(height: 16),
                  const Text('No funded deals yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: C.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Funded deals will appear here.',
                      style: TextStyle(fontSize: 13, color: C.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: C.primary,
            onRefresh: () async => ref.invalidate(dealsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: funded.length,
              itemBuilder: (_, i) => _FundedCard(deal: funded[i]),
            ),
          );
        },
      ),
    );
  }
}

class _FundedCard extends StatelessWidget {
  final Deal deal;
  const _FundedCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final date =
        deal.createdAt != null ? DateTime.tryParse(deal.createdAt!) : null;

    return GestureDetector(
      onTap: () => context.go('/deals/${deal.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.approved.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: C.approvedBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 22, color: C.approved),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deal.displayName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: C.textPrimary)),
                  const SizedBox(height: 2),
                  if (date != null)
                    Text(DateFormat('MMM d, yyyy').format(date),
                        style: const TextStyle(
                            fontSize: 12, color: C.textTertiary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: C.textTertiary),
          ],
        ),
      ),
    );
  }
}
