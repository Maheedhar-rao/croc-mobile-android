class LenderResponse {
  final String? id;
  final int? dealId;
  final String? lenderName;
  final String? fromEmail;
  final String? subject;
  final String? summary;
  final String? aiSummary;
  final String? responseType;
  final String? classification;
  final double? confidence;
  final String? receivedAt;
  final Map<String, dynamic>? offerDetails;
  final String? declineReason;
  final dynamic stipsRequested;

  const LenderResponse({
    this.id,
    this.dealId,
    this.lenderName,
    this.fromEmail,
    this.subject,
    this.summary,
    this.aiSummary,
    this.responseType,
    this.classification,
    this.confidence,
    this.receivedAt,
    this.offerDetails,
    this.declineReason,
    this.stipsRequested,
  });

  factory LenderResponse.fromJson(Map<String, dynamic> j) => LenderResponse(
        id: j['id']?.toString(),
        dealId: j['deal_id'] as int?,
        lenderName: j['lender_name'] as String?,
        fromEmail: j['from_email'] as String?,
        subject: j['subject'] as String?,
        summary: j['summary'] as String?,
        aiSummary: j['ai_summary'] as String?,
        responseType: j['response_type'] as String?,
        classification: j['classification'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble(),
        receivedAt: j['received_at']?.toString(),
        offerDetails: j['offer_details'] as Map<String, dynamic>?,
        declineReason: j['decline_reason'] as String?,
        stipsRequested: j['stips_requested'],
      );

  bool get isApproved =>
      (responseType ?? classification ?? '').toUpperCase().contains('APPROV');
  bool get isDeclined =>
      (responseType ?? classification ?? '').toUpperCase().contains('DECLIN');
  bool get isStips =>
      (responseType ?? classification ?? '').toUpperCase().contains('STIP');

  String get snippet => aiSummary ?? summary ?? '';
}
