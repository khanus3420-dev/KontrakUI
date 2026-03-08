class Quotation {
  Quotation({
    required this.id,
    required this.vendorName,
    required this.expectedAmount,
    required this.reminderDate,
    required this.status,
    this.projectId,
    this.vendorId,
    this.currencyCode = 'INR',
  });

  final String id;
  final String? projectId;
  final String? vendorId;
  final String vendorName;
  final double expectedAmount;
  final String currencyCode;
  final DateTime reminderDate;
  final String status; // 'pending', 'approved', 'rejected'

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'] as String,
      projectId: json['project_id'] as String?,
      vendorId: json['vendor_id'] as String?,
      vendorName: json['vendor_name'] as String,
      expectedAmount: (json['expected_amount'] as num).toDouble(),
      currencyCode: json['currency_code'] as String? ?? 'INR',
      reminderDate: DateTime.parse(json['reminder_date'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (projectId != null) 'project_id': projectId,
      if (vendorId != null) 'vendor_id': vendorId,
      'vendor_name': vendorName,
      'expected_amount': expectedAmount,
      'currency_code': currencyCode,
      'reminder_date': reminderDate.toIso8601String().split('T')[0],
      'status': status,
    };
  }
}
