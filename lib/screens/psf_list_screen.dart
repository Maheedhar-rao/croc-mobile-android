import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/psf.dart';
import '../providers/psf_provider.dart';
import '../widgets/croc_loader.dart';
import '../widgets/status_badge.dart';
import 'psf_send_screen.dart';

class PsfListScreen extends ConsumerWidget {
  const PsfListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final psfAsync = ref.watch(psfListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PSF Agreements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PsfSendScreen()),
        ),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.send_rounded, size: 20),
        label: const Text('Send PSF'),
      ),
      body: psfAsync.when(
        loading: () => const Center(
          child: CrocLoader(message: 'Loading PSFs...'),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e', style: const TextStyle(color: C.textSecondary)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.invalidate(psfListProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (psfs) {
          if (psfs.isEmpty) {
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
                    child: const Icon(Icons.description_outlined,
                        size: 28, color: C.textTertiary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No PSF agreements',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: C.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('PSF agreements will appear here.',
                      style: TextStyle(fontSize: 13, color: C.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: C.primary,
            onRefresh: () async => ref.invalidate(psfListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: psfs.length,
              itemBuilder: (_, i) => _PsfCard(psf: psfs[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PsfCard extends StatelessWidget {
  final Psf psf;
  const _PsfCard({required this.psf});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: psf.isSigned
              ? C.approved.withValues(alpha: 0.3)
              : psf.isVoided
                  ? C.declined.withValues(alpha: 0.3)
                  : C.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: psf.isSigned ? C.approvedBg : C.grey50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  psf.isSigned ? Icons.verified : Icons.description_outlined,
                  size: 18,
                  color: psf.isSigned ? C.approved : C.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(psf.displayName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                    if (psf.signerEmail != null) ...[
                      const SizedBox(height: 1),
                      Text(psf.signerEmail!,
                          style: const TextStyle(
                              fontSize: 12, color: C.textTertiary)),
                    ],
                  ],
                ),
              ),
              _statusBadge(psf.status ?? 'pending'),
            ],
          ),
          const SizedBox(height: 12),
          // Details row
          Row(
            children: [
              if (psf.amount != null) ...[
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                      .format(psf.amount),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: C.primaryDark),
                ),
                const Spacer(),
              ],
              if (psf.bankName != null)
                Text(psf.bankName!,
                    style:
                        const TextStyle(fontSize: 12, color: C.textSecondary)),
            ],
          ),
          if (psf.dealId != null) ...[
            const SizedBox(height: 6),
            Text('Deal #${psf.dealId}',
                style: const TextStyle(fontSize: 12, color: C.textTertiary)),
          ],
          // Timestamps
          const SizedBox(height: 8),
          Row(
            children: [
              if (psf.sentAt != null)
                _timestamp('Sent', psf.sentAt!),
              if (psf.signedAt != null) ...[
                const SizedBox(width: 16),
                _timestamp('Signed', psf.signedAt!),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _timestamp(String label, String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return const SizedBox.shrink();
    return Text(
      '$label ${_timeAgo(date)}',
      style: const TextStyle(fontSize: 11, color: C.textTertiary),
    );
  }

  StatusBadge _statusBadge(String status) {
    return switch (status.toLowerCase()) {
      'pending' =>
        const StatusBadge(label: 'PENDING', color: C.pending, bg: C.pendingBg),
      'sent' =>
        const StatusBadge(label: 'SENT', color: C.stips, bg: C.stipsBg),
      'viewed' =>
        const StatusBadge(label: 'VIEWED', color: C.stips, bg: C.stipsBg),
      'signed' =>
        const StatusBadge(label: 'SIGNED', color: C.approved, bg: C.approvedBg),
      'voided' =>
        const StatusBadge(label: 'VOIDED', color: C.declined, bg: C.declinedBg),
      _ =>
        const StatusBadge(label: 'UNKNOWN', color: C.pending, bg: C.pendingBg),
    };
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
