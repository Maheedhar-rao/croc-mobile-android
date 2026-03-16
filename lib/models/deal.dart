class Deal {
  final int id;
  final String? userId;
  final String? senderEmail;
  final String? subject;
  final String? businessName;
  final String? mode;
  final String? status;
  final String? createdAt;
  final int resendCount;
  final String? sendStatus;
  final String? sendSummary;
  final double? fundedAmount;
  final String? fundedLender;
  final String? fundedAt;
  final Map<String, dynamic> applicationJson;

  const Deal({
    required this.id,
    this.userId,
    this.senderEmail,
    this.subject,
    this.businessName,
    this.mode,
    this.status,
    this.createdAt,
    this.resendCount = 0,
    this.sendStatus,
    this.sendSummary,
    this.fundedAmount,
    this.fundedLender,
    this.fundedAt,
    this.applicationJson = const {},
  });

  factory Deal.fromJson(Map<String, dynamic> j) => Deal(
        id: j['id'] as int,
        userId: j['user_id'] as String?,
        senderEmail: j['sender_email'] as String?,
        subject: j['subject'] as String?,
        businessName: j['business_name'] as String?,
        mode: j['mode'] as String?,
        status: j['status'] as String?,
        createdAt: j['created_at']?.toString(),
        resendCount: j['resend_count'] as int? ?? 0,
        sendStatus: j['send_status'] as String?,
        sendSummary: j['send_summary'] as String?,
        fundedAmount: (j['funded_amount'] as num?)?.toDouble(),
        fundedLender: j['funded_lender'] as String?,
        fundedAt: j['funded_at']?.toString(),
        applicationJson: j['application_json'] as Map<String, dynamic>? ?? {},
      );

  String get displayName {
    if (businessName != null && businessName!.isNotEmpty) return businessName!;
    // Try to extract business name from subject (e.g. "Fwd: Application - Acme Corp")
    if (subject != null && subject!.isNotEmpty) {
      final s = subject!
          .replaceAll(RegExp(r'^(Re:|Fwd?:)\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'^Application\s*[-–]\s*', caseSensitive: false), '')
          .trim();
      if (s.isNotEmpty) return s;
    }
    return 'Deal #$id';
  }
  bool get isFunded => fundedAmount != null || fundedLender != null || fundedAt != null;
}
