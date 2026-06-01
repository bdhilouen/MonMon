class Transaction {
  final String id;
  String title;
  int amount;
  final bool isIncome;
  DateTime date;
  String category;
  String? categoryId;
  String? categoryIcon;
  String? categoryColor;
  String currency;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.category,
    this.categoryId,
    this.categoryIcon,
    this.categoryColor,
    this.currency = 'IDR',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'isIncome': isIncome,
      'date': date.toIso8601String(),
      'category': category,
      'category_id': categoryId,
      'currency': currency,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final categorySnapshot = json['category_snapshot'];

    final Map<String, dynamic>? snapshot =
    categorySnapshot is Map<String, dynamic> ? categorySnapshot : null;

    final rawType = json['type']?.toString();

    return Transaction(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['note']?.toString() ??
          json['title']?.toString() ??
          'Tanpa catatan',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      isIncome: rawType == 'income' || json['isIncome'] == true,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      category: snapshot?['name']?.toString() ??
          json['category']?.toString() ??
          'Kategori',
      categoryId: json['category_id']?.toString() ??
          snapshot?['id']?.toString() ??
          snapshot?['_id']?.toString(),
      categoryIcon: snapshot?['icon']?.toString(),
      categoryColor: snapshot?['color']?.toString(),
      currency: json['currency']?.toString() ?? 'IDR',
    );
  }
}