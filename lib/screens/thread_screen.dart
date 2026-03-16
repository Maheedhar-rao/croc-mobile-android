import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../providers/updates_provider.dart';
import '../widgets/croc_loader.dart';
import '../widgets/status_badge.dart';

class ThreadScreen extends ConsumerWidget {
  final int dealId;
  final String lenderName;

  const ThreadScreen({super.key, required this.dealId, required this.lenderName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadAsync = ref.watch(
      emailThreadProvider((dealId: dealId, lenderName: lenderName)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lenderName, style: const TextStyle(fontSize: 16)),
            Text('Deal #$dealId',
                style: const TextStyle(fontSize: 12, color: C.textTertiary)),
          ],
        ),
      ),
      body: threadAsync.when(
        loading: () => const Center(
          child: CrocLoader(size: 64, message: 'Loading thread...'),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (messages) {
          if (messages.isEmpty) {
            return const Center(
              child: Text('No messages in this thread',
                  style: TextStyle(color: C.textTertiary)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (_, i) => _MessageBubble(message: messages[i]),
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSent = message['type'] == 'sent';
    final timestamp = message['timestamp'] != null
        ? DateTime.tryParse(message['timestamp'].toString())
        : null;
    final responseType = message['response_type'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              color: isSent ? C.primary : _responseColor(responseType),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSent ? C.primary.withValues(alpha: 0.04) : C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 14,
                        color: isSent ? C.primary : _responseColor(responseType),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isSent ? 'You' : (message['from'] ?? 'Unknown'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSent ? C.primary : C.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (responseType != null) StatusBadge.response(responseType),
                    ],
                  ),
                  if ((message['subject'] as String?)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Text(message['subject'],
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: C.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if ((message['body'] as String?)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Text(
                      _cleanBody(message['body']),
                      style: const TextStyle(
                          fontSize: 13, color: C.textSecondary, height: 1.4),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (timestamp != null) ...[
                    const SizedBox(height: 8),
                    Text(DateFormat('MMM d, yyyy h:mm a').format(timestamp),
                        style: const TextStyle(fontSize: 11, color: C.textTertiary)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _responseColor(String? type) {
    if (type == null) return C.pending;
    final u = type.toUpperCase();
    if (u.contains('APPROV')) return C.approved;
    if (u.contains('DECLIN')) return C.declined;
    if (u.contains('STIP')) return C.stips;
    return C.pending;
  }

  String _cleanBody(String body) {
    return body
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
