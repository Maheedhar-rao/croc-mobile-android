class Delivery {
  final String? id;
  final String? lenderName;
  final String? toEmail;
  final String? ccCsv;
  final String? status;
  final String? trackingStatus;
  final bool responseReceived;
  final String? deliveryResponseType;
  final String? businessName;
  final String? createdAt;

  const Delivery({
    this.id,
    this.lenderName,
    this.toEmail,
    this.ccCsv,
    this.status,
    this.trackingStatus,
    this.responseReceived = false,
    this.deliveryResponseType,
    this.businessName,
    this.createdAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> j) => Delivery(
        id: j['id']?.toString(),
        lenderName: j['lender_name'] as String?,
        toEmail: j['to_email'] as String?,
        ccCsv: j['cc_csv'] as String?,
        status: j['status'] as String?,
        trackingStatus: j['tracking_status'] as String?,
        responseReceived: j['response_received'] as bool? ?? false,
        deliveryResponseType: j['delivery_response_type'] as String?,
        businessName: j['delivery_business_name'] as String? ?? j['business_name'] as String?,
        createdAt: j['created_at']?.toString(),
      );

  String get displayName => lenderName ?? toEmail ?? 'Unknown Lender';
}
