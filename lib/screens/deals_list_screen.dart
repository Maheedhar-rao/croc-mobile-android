import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/deal.dart';
import '../providers/deals_provider.dart';
import '../widgets/croc_loader.dart';
import '../widgets/deal_card.dart';

class DealsListScreen extends ConsumerStatefulWidget {
  const DealsListScreen({super.key});

  @override
  ConsumerState<DealsListScreen> createState() => _DealsListScreenState();
}

class _DealsListScreenState extends ConsumerState<DealsListScreen> {
  String _search = '';
  DateTimeRange? _dateRange;
  String _statusFilter = 'All';

  void _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: C.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  List<Deal> _applyFilters(List<Deal> deals) {
    var result = deals;

    // Search
    if (_search.isNotEmpty) {
      result = result.where((d) {
        final name = d.displayName.toLowerCase();
        final email = (d.senderEmail ?? '').toLowerCase();
        return name.contains(_search) || email.contains(_search);
      }).toList();
    }

    // Date range
    if (_dateRange != null) {
      result = result.where((d) {
        if (d.createdAt == null) return false;
        final date = DateTime.tryParse(d.createdAt!);
        if (date == null) return false;
        return !date.isBefore(_dateRange!.start) &&
            !date.isAfter(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Status
    if (_statusFilter != 'All') {
      result = result.where((d) {
        final s = (d.status ?? '').toLowerCase();
        return s == _statusFilter.toLowerCase();
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(dealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: C.approvedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset('assets/images/croc.png'),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Deals'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search + filters
          Container(
            color: C.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              children: [
                // Search
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search deals...',
                    hintStyle: const TextStyle(color: C.textTertiary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20, color: C.textTertiary),
                    isDense: true,
                    filled: true,
                    fillColor: C.grey50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (q) => setState(() => _search = q.toLowerCase()),
                ),
                const SizedBox(height: 8),
                // Filter row
                Row(
                  children: [
                    // Date range
                    _FilterChip(
                      label: _dateRange != null
                          ? '${DateFormat('M/d').format(_dateRange!.start)} - ${DateFormat('M/d').format(_dateRange!.end)}'
                          : 'Date range',
                      icon: Icons.calendar_today,
                      active: _dateRange != null,
                      onTap: _pickDateRange,
                      onClear: _dateRange != null
                          ? () => setState(() => _dateRange = null)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    // Status filter
                    _FilterChip(
                      label: _statusFilter,
                      icon: Icons.filter_list,
                      active: _statusFilter != 'All',
                      onTap: () => _showStatusPicker(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: C.border),
          // List
          Expanded(
            child: dealsAsync.when(
              loading: () => const Center(
                child: CrocLoader(message: 'Fetching deals...'),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: C.declined),
                      const SizedBox(height: 12),
                      Text('$e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: C.textSecondary, fontSize: 14)),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(dealsProvider),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (deals) {
                final filtered = _applyFilters(deals);

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
                          child: const Icon(Icons.business_center_outlined,
                              size: 28, color: C.textTertiary),
                        ),
                        const SizedBox(height: 16),
                        const Text('No deals found',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: C.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                          _dateRange != null || _statusFilter != 'All'
                              ? 'Try adjusting your filters.'
                              : 'Deals will appear here once submitted.',
                          style: const TextStyle(fontSize: 13, color: C.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: C.primary,
                  onRefresh: () async => ref.invalidate(dealsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final deal = filtered[i];
                      return DealCard(
                        deal: deal,
                        onTap: () => context.go('/deals/${deal.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker() {
    final statuses = ['All', 'Sent', 'Pending', 'Funded', 'Error'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Filter by status',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: C.textPrimary)),
            ),
            ...statuses.map((s) => ListTile(
                  title: Text(s),
                  trailing: _statusFilter == s
                      ? const Icon(Icons.check, color: C.primary)
                      : null,
                  onTap: () {
                    setState(() => _statusFilter = s);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? C.approvedBg : C.grey50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? C.primary.withValues(alpha: 0.3) : C.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? C.primary : C.textTertiary),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? C.primary : C.textSecondary)),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 14, color: C.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
