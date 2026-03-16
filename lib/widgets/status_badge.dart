import 'package:flutter/material.dart';

import '../config/theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const StatusBadge(
      {super.key, required this.label, required this.color, required this.bg});

  factory StatusBadge.delivery(String status) {
    return switch (status.toLowerCase()) {
      'sent' || 'delivered' =>
        const StatusBadge(label: 'SENT', color: C.approved, bg: C.approvedBg),
      'error' || 'failed' =>
        const StatusBadge(label: 'ERROR', color: C.declined, bg: C.declinedBg),
      'skipped' =>
        const StatusBadge(label: 'SKIP', color: C.pending, bg: C.pendingBg),
      _ => StatusBadge(
          label: status.toUpperCase(), color: C.pending, bg: C.pendingBg),
    };
  }

  factory StatusBadge.response(String type) {
    return switch (type.toUpperCase()) {
      'APPROVED' => const StatusBadge(
          label: 'APPROVED', color: C.approved, bg: C.approvedBg),
      'DECLINED' => const StatusBadge(
          label: 'DECLINED', color: C.declined, bg: C.declinedBg),
      'STIPS_REQUIRED' =>
        const StatusBadge(label: 'STIPS', color: C.stips, bg: C.stipsBg),
      _ => const StatusBadge(
          label: 'PENDING', color: C.pending, bg: C.pendingBg),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
