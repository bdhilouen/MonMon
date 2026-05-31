class Transaction {
  final String? id;
  String title;
  int amount;
  final bool isIncome;
  final DateTime date;
  String category;
  final String? categoryId;
  final String? note;
  final String? categoryIcon;
  final String? categoryColor;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.category,
    this.categoryId,
    this.note,
    this.categoryIcon,
    this.categoryColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'isIncome': isIncome,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Backend API format
    if (json.containsKey('type') || json.containsKey('category_snapshot')) {
      final snapshot = json['category_snapshot'] as Map<String, dynamic>?;
      final type = json['type'] as String? ?? 'expense';
      final isIncome = type == 'income';

      return Transaction(
        id: json['_id']?.toString() ?? json['id']?.toString(),
        title:
            json['note'] ??
            snapshot?['name'] ??
            (isIncome ? 'Pemasukan' : 'Pengeluaran'),
        amount: (json['amount'] is int)
            ? json['amount']
            : (json['amount'] as num?)?.toInt() ?? 0,
        isIncome: isIncome,
        date: _parseDate(json['date']),
        category: snapshot?['name'] ?? (isIncome ? 'Pemasukan' : 'Lainnya'),
        categoryId: json['category_id']?.toString(),
        note: json['note']?.toString(),
        categoryIcon: snapshot?['icon'],
        categoryColor: snapshot?['color'],
      );
    }

    // Legacy local format
    return Transaction(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['title'] ?? '',
      amount: (json['amount'] is int)
          ? json['amount']
          : (json['amount'] as num?)?.toInt() ?? 0,
      isIncome: json['isIncome'] ?? false,
      date: _parseDate(json['date']),
      category: json['category'] ?? 'Lainnya',
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      return DateTime.tryParse(dateValue) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
