class Transaction {
  Transaction({
    required this.id,
    required this.projectId,
    required this.amount,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.date,
    this.vendorId,
    this.currencyCode = 'INR',
    this.exchangeRateToBase = 1.0,
    this.notes,
  });

  final String id;
  final String projectId;
  final String? vendorId;
  final double amount;
  final String currencyCode;
  final double exchangeRateToBase;
  final String type; // 'credit' or 'debit'
  final String category; // 'material', 'labor', 'transport', 'misc'
  final String paymentMethod; // 'cash', 'upi', 'bank'
  final DateTime date;
  final String? notes;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      vendorId: json['vendor_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currency_code'] as String? ?? 'INR',
      exchangeRateToBase: (json['exchange_rate_to_base'] as num?)?.toDouble() ?? 1.0,
      type: json['type'] as String,
      category: json['category'] as String,
      paymentMethod: json['payment_method'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      if (vendorId != null) 'vendor_id': vendorId,
      'amount': amount,
      'currency_code': currencyCode,
      'exchange_rate_to_base': exchangeRateToBase,
      'type': type,
      'category': category,
      'payment_method': paymentMethod,
      'date': date.toIso8601String().split('T')[0],
      if (notes != null) 'notes': notes,
    };
  }
}
