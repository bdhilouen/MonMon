class MonthlyWrapped {
  final String id;
  final String month;
  final double totalIncome;
  final double totalExpense;
  final double savingRate;
  final String? topCategory;
  final int totalTransactions;
  final int streak;
  final List<String> insights;

  MonthlyWrapped({
    required this.id,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.savingRate,
    this.topCategory,
    required this.totalTransactions,
    required this.streak,
    this.insights = const [],
  });

  factory MonthlyWrapped.fromJson(
      Map<String, dynamic> dataJson, List<dynamic>? insightsJson) {
    return MonthlyWrapped(
      id: dataJson['_id']?.toString() ?? dataJson['id']?.toString() ?? '',
      month: dataJson['month'] ?? '',
      totalIncome: (dataJson['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (dataJson['total_expense'] as num?)?.toDouble() ?? 0.0,
      savingRate: (dataJson['saving_rate'] as num?)?.toDouble() ?? 0.0,
      topCategory: dataJson['top_category'],
      totalTransactions:
          (dataJson['total_transactions'] as num?)?.toInt() ?? 0,
      streak: (dataJson['streak'] as num?)?.toInt() ?? 0,
      insights: insightsJson?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
