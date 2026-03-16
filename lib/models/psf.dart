class Psf {
  final int id;
  final int? dealId;
  final String? documentId;
  final double? amount;
  final String? effectiveDate;
  final String? accountHolderName;
  final String? accountHolderDba;
  final String? bankName;
  final String? signerEmail;
  final String? status; // pending, sent, viewed, signed, voided
  final String? sentAt;
  final String? viewedAt;
  final String? signedAt;
  final String? completedAt;
  final String? createdBy;
  final String? createdAt;
  final String? expiresAt;

  const Psf({
    required this.id,
    this.dealId,
    this.documentId,
    this.amount,
    this.effectiveDate,
    this.accountHolderName,
    this.accountHolderDba,
    this.bankName,
    this.signerEmail,
    this.status,
    this.sentAt,
    this.viewedAt,
    this.signedAt,
    this.completedAt,
    this.createdBy,
    this.createdAt,
    this.expiresAt,
  });

  factory Psf.fromJson(Map<String, dynamic> j) => Psf(
        id: j['id'] as int,
        dealId: j['deal_id'] as int?,
        documentId: j['document_id']?.toString(),
        amount: (j['amount'] as num?)?.toDouble(),
        effectiveDate: j['effective_date'] as String?,
        accountHolderName: j['account_holder_name'] as String?,
        accountHolderDba: j['account_holder_dba'] as String?,
        bankName: j['bank_name'] as String?,
        signerEmail: j['signer_email'] as String?,
        status: j['status'] as String?,
        sentAt: j['sent_at']?.toString(),
        viewedAt: j['viewed_at']?.toString(),
        signedAt: j['signed_at']?.toString(),
        completedAt: j['completed_at']?.toString(),
        createdBy: j['created_by'] as String?,
        createdAt: j['created_at']?.toString(),
        expiresAt: j['expires_at']?.toString(),
      );

  String get displayName => accountHolderDba ?? accountHolderName ?? 'PSF #$id';
  bool get isSigned => status?.toLowerCase() == 'signed';
  bool get isVoided => status?.toLowerCase() == 'voided';
  bool get isPending => status?.toLowerCase() == 'pending' || status?.toLowerCase() == 'sent';
}
