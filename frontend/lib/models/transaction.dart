class Transaction {
  final String id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String categoryId;
  final Map<String, dynamic>? categorySnapshot;
  final String? note;
  final String? receiptUrl;
  final String currency;
  final DateTime date;
  final DateTime? createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.categorySnapshot,
    this.note,
    this.receiptUrl,
    this.currency = 'IDR',
    required this.date,
    this.createdAt,
  });

  bool get isIncome => type == 'income';

  String get categoryName =>
      categorySnapshot?['name'] ?? 'Unknown';

  String get categoryIcon =>
      categorySnapshot?['icon'] ?? '📦';

  String get categoryColor =>
      categorySnapshot?['color'] ?? '#999999';

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type'] ?? 'expense',
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : (json['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['category_id']?.toString() ?? '',
      categorySnapshot: json['category_snapshot'] is Map
          ? Map<String, dynamic>.from(json['category_snapshot'])
          : null,
      note: json['note'],
      receiptUrl: json['receipt_url'],
      currency: json['currency'] ?? 'IDR',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'note': note,
      'date': date.toIso8601String().split('T')[0],
      'currency': currency,
    };
  }
}