import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/lender_response.dart';
import '../providers/deals_provider.dart';
import '../widgets/croc_loader.dart';
import '../widgets/status_badge.dart';
import 'thread_screen.dart';

class DealDetailScreen extends ConsumerWidget {
  final int dealId;
  const DealDetailScreen({super.key, required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealAsync = ref.watch(dealDetailProvider(dealId));

    return Scaffold(
      appBar: AppBar(title: Text('Deal #$dealId')),
      body: dealAsync.when(
        loading: () => const Center(child: CrocLoader(message: 'Loading deal...')),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final app = data['application_json'] as Map<String, dynamic>? ?? {};
          final businessName = _resolveName(data, app);
          final createdAt = DateTime.tryParse(data['created_at']?.toString() ?? '');

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    color: C.surface,
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: C.approvedBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.business_center, size: 22, color: C.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(businessName,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.textPrimary)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (createdAt != null)
                                    Text(DateFormat('MMM d, yyyy').format(createdAt),
                                        style: const TextStyle(fontSize: 12, color: C.textTertiary)),
                                  if (_v(data['mode']) != null) ...[
                                    const Text('  ·  ', style: TextStyle(color: C.textTertiary)),
                                    Text(data['mode'], style: const TextStyle(fontSize: 12, color: C.textTertiary)),
                                  ],
                                  if (_v(data['send_status']) != null) ...[
                                    const Text('  ·  ', style: TextStyle(color: C.textTertiary)),
                                    Text(data['send_status'], style: const TextStyle(fontSize: 12, color: C.textTertiary)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      tabs: [
                        Tab(text: 'Offers'),
                        Tab(text: 'Declines'),
                        Tab(text: 'Stips'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _OffersTab(dealId: dealId),
                  _DeclinesTab(dealId: dealId),
                  _StipsTab(dealId: dealId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _resolveName(Map<String, dynamic> data, Map<String, dynamic> app) {
    final bn = data['business_name']?.toString().trim() ?? '';
    if (bn.isNotEmpty) return bn;
    final an = app['business_name']?.toString().trim() ?? '';
    if (an.isNotEmpty) return an;
    final subj = data['subject']?.toString().trim() ?? '';
    if (subj.isNotEmpty) {
      return subj
          .replaceAll(RegExp(r'^(Re:|Fwd?:)\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'^Application\s*[-–]\s*', caseSensitive: false), '')
          .trim();
    }
    return 'Deal #$dealId';
  }

  String? _v(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    return s.isEmpty ? null : s;
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: C.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ── Offers Tab ──

class _OffersTab extends ConsumerWidget {
  final int dealId;
  const _OffersTab({required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(responsesProvider(dealId));
    return async.when(
      loading: () => const Center(child: CrocLoader(size: 64, message: 'Loading...')),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (responses) {
        final seen = <String>{};
        final offers = responses.where((r) {
          if (!r.isApproved) return false;
          final key = '${r.lenderName ?? r.fromEmail}_${r.receivedAt}';
          return seen.add(key);
        }).toList();
        if (offers.isEmpty) {
          return const Center(
            child: Text('No offers yet', style: TextStyle(color: C.textTertiary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (_, i) => _OfferCard(response: offers[i], dealId: dealId),
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final LenderResponse response;
  final int dealId;
  const _OfferCard({required this.response, required this.dealId});

  @override
  Widget build(BuildContext context) {
    final offer = response.offerDetails ?? {};
    final amount = offer['amount'] as num?;
    final factor = offer['factor_rate'];
    final term = offer['term'];
    final payment = offer['payment'];
    final conditions = offer['conditions']?.toString().trim() ?? '';
    final date = response.receivedAt != null ? DateTime.tryParse(response.receivedAt!) : null;

    // Calculate daily payment if not provided
    final dailyPayment = payment ??
        (amount != null && factor != null && term != null
            ? (amount * (factor as num)) / ((term as num) * 30)
            : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: lender + badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    response.lenderName ?? response.fromEmail ?? 'Unknown Lender',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.textPrimary),
                  ),
                ),
                const StatusBadge(label: 'APPROVED', color: C.approved, bg: Color(0xFFBBF7D0)),
              ],
            ),
            const SizedBox(height: 14),
            // Amount
            if (amount != null)
              Text(
                NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: C.approved),
              ),
            const SizedBox(height: 10),
            // Details grid
            Row(
              children: [
                if (factor != null) _detail('Factor', '${factor}x'),
                if (term != null) _detail('Term', '$term mo'),
                if (dailyPayment != null)
                  _detail('Daily', NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(dailyPayment)),
              ],
            ),
            // Conditions
            if (conditions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: C.stipsBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: C.stips.withValues(alpha: 0.3)),
                ),
                child: Text(conditions,
                    style: const TextStyle(fontSize: 12, color: C.textSecondary)),
              ),
            ],
            // Footer
            const SizedBox(height: 12),
            Row(
              children: [
                if (date != null)
                  Text('Responded ${_timeAgo(date)}',
                      style: const TextStyle(fontSize: 11, color: C.textTertiary, fontStyle: FontStyle.italic)),
                const Spacer(),
                if (response.lenderName != null)
                  GestureDetector(
                    onTap: () => _openThread(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 14, color: C.primary),
                        SizedBox(width: 4),
                        Text('View Thread',
                            style: TextStyle(fontSize: 12, color: C.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openThread(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ThreadScreen(dealId: dealId, lenderName: response.lenderName!),
    ));
  }

  Widget _detail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: C.textTertiary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.textPrimary)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Declines Tab ──

class _DeclinesTab extends ConsumerWidget {
  final int dealId;
  const _DeclinesTab({required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(responsesProvider(dealId));
    return async.when(
      loading: () => const Center(child: CrocLoader(size: 64, message: 'Loading...')),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (responses) {
        final seen = <String>{};
        final declines = responses.where((r) {
          if (!r.isDeclined) return false;
          final key = '${r.lenderName ?? r.fromEmail}_${r.receivedAt}';
          return seen.add(key);
        }).toList();
        if (declines.isEmpty) {
          return const Center(
            child: Text('No declines', style: TextStyle(color: C.textTertiary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: declines.length,
          itemBuilder: (_, i) => _DeclineCard(response: declines[i], dealId: dealId),
        );
      },
    );
  }
}

class _DeclineCard extends StatelessWidget {
  final LenderResponse response;
  final int dealId;
  const _DeclineCard({required this.response, required this.dealId});

  @override
  Widget build(BuildContext context) {
    final date = response.receivedAt != null ? DateTime.tryParse(response.receivedAt!) : null;
    final reason = response.declineReason ?? response.snippet;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response.lenderName ?? response.fromEmail ?? 'Unknown Lender',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.textPrimary),
                      ),
                      if (response.fromEmail != null) ...[
                        const SizedBox(height: 2),
                        Text(response.fromEmail!,
                            style: const TextStyle(fontSize: 12, color: C.textTertiary)),
                      ],
                    ],
                  ),
                ),
                const StatusBadge(label: 'DECLINED', color: C.declined, bg: Color(0xFFFECACA)),
              ],
            ),
            // Reason box
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Decline Reason',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: Color(0xFF991B1B), letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Text(reason,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B), height: 1.5)),
                  ],
                ),
              ),
            ],
            // Footer
            const SizedBox(height: 12),
            Row(
              children: [
                if (date != null)
                  Text('Declined ${_timeAgo(date)}',
                      style: const TextStyle(fontSize: 11, color: C.textTertiary, fontStyle: FontStyle.italic)),
                const Spacer(),
                if (response.lenderName != null)
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ThreadScreen(dealId: dealId, lenderName: response.lenderName!),
                    )),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 14, color: C.primary),
                        SizedBox(width: 4),
                        Text('View Thread',
                            style: TextStyle(fontSize: 12, color: C.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Stips Tab ──

class _StipsTab extends ConsumerWidget {
  final int dealId;
  const _StipsTab({required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(responsesProvider(dealId));
    return async.when(
      loading: () => const Center(child: CrocLoader(size: 64, message: 'Loading...')),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (responses) {
        final seen = <String>{};
        final stips = responses.where((r) {
          if (!r.isStips) return false;
          final key = '${r.lenderName ?? r.fromEmail}_${r.receivedAt}';
          return seen.add(key);
        }).toList();
        if (stips.isEmpty) {
          return const Center(
            child: Text('No stips requested', style: TextStyle(color: C.textTertiary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stips.length,
          itemBuilder: (_, i) => _StipCard(response: stips[i], dealId: dealId),
        );
      },
    );
  }
}

class _StipCard extends StatelessWidget {
  final LenderResponse response;
  final int dealId;
  const _StipCard({required this.response, required this.dealId});

  @override
  Widget build(BuildContext context) {
    final date = response.receivedAt != null ? DateTime.tryParse(response.receivedAt!) : null;

    // Parse requirements from stips_requested or snippet
    final stipsData = response.stipsRequested;
    List<String> requirements = [];
    if (stipsData is List) {
      requirements = stipsData.map((e) => e.toString()).toList();
    } else if (stipsData is String && stipsData.isNotEmpty) {
      requirements = stipsData.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else if (response.snippet.isNotEmpty) {
      requirements = response.snippet.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    response.lenderName ?? response.fromEmail ?? 'Unknown Lender',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.textPrimary),
                  ),
                ),
                const StatusBadge(label: 'STIPS', color: C.stips, bg: Color(0xFFFDE68A)),
              ],
            ),
            // Requirements
            if (requirements.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Required Documents',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E), letterSpacing: 0.5)),
              const SizedBox(height: 8),
              ...requirements.map((req) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box_outline_blank, size: 16, color: Color(0xFF92400E)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(req,
                                style: const TextStyle(fontSize: 13, color: C.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                  )),
            ] else if (response.snippet.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(response.snippet,
                  style: const TextStyle(fontSize: 13, color: C.textSecondary, height: 1.5)),
            ],
            // Footer
            const SizedBox(height: 12),
            Row(
              children: [
                if (date != null)
                  Text('Requested ${_timeAgo(date)}',
                      style: const TextStyle(fontSize: 11, color: C.textTertiary, fontStyle: FontStyle.italic)),
                const Spacer(),
                if (response.lenderName != null)
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ThreadScreen(dealId: dealId, lenderName: response.lenderName!),
                    )),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 14, color: C.primary),
                        SizedBox(width: 4),
                        Text('View Thread',
                            style: TextStyle(fontSize: 12, color: C.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
