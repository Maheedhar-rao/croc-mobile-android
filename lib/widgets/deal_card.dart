import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/deal.dart';

class DealCard extends StatelessWidget {
  final Deal deal;
  final VoidCallback onTap;

  const DealCard({super.key, required this.deal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date =
        deal.createdAt != null ? DateTime.tryParse(deal.createdAt!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [C.primary.withValues(alpha: 0.1), C.approvedBg],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business_center_rounded,
                          size: 20, color: C.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deal.displayName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: C.textPrimary,
                                letterSpacing: -0.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Deal #${deal.id}',
                            style: const TextStyle(fontSize: 12, color: C.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (date != null)
                          Text(_timeAgo(date),
                              style: const TextStyle(fontSize: 11, color: C.textTertiary)),
                        const SizedBox(height: 4),
                        const Icon(Icons.chevron_right_rounded,
                            size: 20, color: C.textTertiary),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (deal.sendStatus != null)
                      _Chip(
                        deal.sendStatus == 'done'
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        deal.sendStatus!,
                        deal.sendStatus == 'done' ? C.approved : C.pending,
                        deal.sendStatus == 'done' ? C.approvedBg : C.pendingBg,
                      ),
                    if (deal.isFunded)
                      const _Chip(Icons.paid_rounded, 'Funded', C.approved, C.approvedBg),
                    if (deal.status != null && deal.status!.isNotEmpty)
                      _Chip(Icons.circle, deal.status!, C.textSecondary, C.grey100),
                    if (deal.sendSummary != null && deal.sendSummary!.isNotEmpty)
                      _Chip(Icons.mail_outline_rounded, deal.sendSummary!, C.textSecondary, C.grey50),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _Chip(this.icon, this.label, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
