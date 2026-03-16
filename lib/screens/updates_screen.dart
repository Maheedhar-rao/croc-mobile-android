import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/lender_response.dart';
import '../providers/updates_provider.dart';
import '../widgets/croc_loader.dart';
import '../widgets/status_badge.dart';
import 'thread_screen.dart';

class UpdatesScreen extends ConsumerStatefulWidget {
  const UpdatesScreen({super.key});

  @override
  ConsumerState<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends ConsumerState<UpdatesScreen> {
  String _filter = 'All'; // All, Offers, Declines, Stips

  @override
  Widget build(BuildContext context) {
    final updatesAsync = ref.watch(updatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Updates')),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: C.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                _chip('All'),
                const SizedBox(width: 8),
                _chip('Offers'),
                const SizedBox(width: 8),
                _chip('Declines'),
                const SizedBox(width: 8),
                _chip('Stips'),
              ],
            ),
          ),
          const Divider(height: 1, color: C.border),
          // List
          Expanded(
            child: updatesAsync.when(
              loading: () => const Center(
                child: CrocLoader(message: 'Loading updates...'),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$e', style: const TextStyle(color: C.textSecondary)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(updatesProvider),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (responses) {
                final filtered = _applyFilter(responses);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: C.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _filter == 'Offers'
                                ? Icons.check_circle_outline
                                : _filter == 'Declines'
                                    ? Icons.cancel_outlined
                                    : Icons.notifications_none_rounded,
                            size: 28,
                            color: C.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'All' ? 'No updates yet' : 'No $_filter',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: C.textPrimary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: C.primary,
                  onRefresh: () async => ref.invalidate(updatesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _UpdateCard(
                      response: filtered[i],
                      onTap: () {
                        if (filtered[i].dealId != null &&
                            filtered[i].lenderName != null) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ThreadScreen(
                              dealId: filtered[i].dealId!,
                              lenderName: filtered[i].lenderName!,
                            ),
                          ));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<LenderResponse> _applyFilter(List<LenderResponse> responses) {
    return switch (_filter) {
      'Offers' => responses.where((r) => r.isApproved).toList(),
      'Declines' => responses.where((r) => r.isDeclined).toList(),
      'Stips' => responses.where((r) => r.isStips).toList(),
      _ => responses,
    };
  }

  Widget _chip(String label) {
    final active = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? C.primary : C.grey50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : C.textSecondary)),
      ),
    );
  }
}

// ── Update Card ──

class _UpdateCard extends StatelessWidget {
  final LenderResponse response;
  final VoidCallback onTap;
  const _UpdateCard({required this.response, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = response.receivedAt != null
        ? DateTime.tryParse(response.receivedAt!)
        : null;
    final offer = response.offerDetails;
    final amount = offer?['amount'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deal ID + Lender + Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: C.grey100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('#${response.dealId ?? '—'}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: C.textSecondary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.lenderName ?? response.fromEmail ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: C.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge.response(response.responseType ?? 'OTHER'),
              ],
            ),
            // Offer amount
            if (response.isApproved && amount != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                        .format(amount),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: C.approved),
                  ),
                  if (offer?['factor_rate'] != null) ...[
                    const SizedBox(width: 12),
                    Text('${offer!['factor_rate']}x',
                        style: const TextStyle(
                            fontSize: 13, color: C.textSecondary)),
                  ],
                  if (offer?['term'] != null) ...[
                    const SizedBox(width: 8),
                    Text('${offer!['term']}mo',
                        style: const TextStyle(
                            fontSize: 13, color: C.textSecondary)),
                  ],
                ],
              ),
            ],
            // Decline reason
            if (response.isDeclined && response.declineReason != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: C.declined),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(response.declineReason!,
                        style: const TextStyle(fontSize: 13, color: C.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            // Stips
            if (response.isStips && response.snippet.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 14, color: C.stips),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(response.snippet,
                        style: const TextStyle(fontSize: 13, color: C.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            // Footer: time + thread link
            const SizedBox(height: 8),
            Row(
              children: [
                if (date != null)
                  Text(_timeAgo(date),
                      style: const TextStyle(fontSize: 11, color: C.textTertiary)),
                const Spacer(),
                if (response.lenderName != null)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Thread',
                          style: TextStyle(
                              fontSize: 12,
                              color: C.primary,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: C.primary),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _borderColor => response.isApproved
      ? C.approved.withValues(alpha: 0.3)
      : response.isDeclined
          ? C.declined.withValues(alpha: 0.3)
          : response.isStips
              ? C.stips.withValues(alpha: 0.3)
              : C.border;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

