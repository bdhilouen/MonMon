class Transaction {
  String title;
  int amount;
  final bool isIncome;
  final DateTime date;
  final String category;

  Transaction({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.category,
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
  factory Transaction.fromJson(
      Map<String, dynamic> json) {

    return Transaction(
      title: json['title'],
      amount: json['amount'],
      isIncome: json['isIncome'],
      date: DateTime.parse(json['date']),
      category: json['category'],
    );
  }
}