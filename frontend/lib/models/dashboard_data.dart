import 'transaction.dart';

class DashboardData {
  final DashboardUser user;
  final String month;
  final MonthlyStats monthlyStats;
  final List<Transaction> recentTransactions;
  final int achievementsUnlocked;

  DashboardData({
    required this.user,
    required this.month,
    required this.monthlyStats,
    required this.recentTransactions,
    this.achievementsUnlocked = 0,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      user: DashboardUser.fromJson(json['user'] ?? {}),
      month: json['month'] ?? '',
      monthlyStats: MonthlyStats.fromJson(json['monthly_stats'] ?? {}),
      recentTransactions: (json['recent_transactions'] as List?)
              ?.map((t) => Transaction.fromJson(t))
              .toList() ??
          [],
      achievementsUnlocked: (json['achievements_unlocked'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardUser {
  final String name;
  final double balance;
  final int points;
  final int level;
  final int streak;

  DashboardUser({
    required this.name,
    required this.balance,
    required this.points,
    required this.level,
    required this.streak,
  });

  factory DashboardUser.fromJson(Map<String, dynamic> json) {
    return DashboardUser(
      name: json['name'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class MonthlyStats {
  final double totalIncome;
  final double totalExpense;
  final double netIncome;
  final double savingRate;
  final int incomeCount;
  final int expenseCount;

  MonthlyStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.netIncome,
    required this.savingRate,
    required this.incomeCount,
    required this.expenseCount,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0.0,
      netIncome: (json['net_income'] as num?)?.toDouble() ?? 0.0,
      savingRate: (json['saving_rate'] as num?)?.toDouble() ?? 0.0,
      incomeCount: (json['income_count'] as num?)?.toInt() ?? 0,
      expenseCount: (json['expense_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChartDataResponse {
  final List<TimelineEntry> timeline;
  final List<CategoryBreakdown> categoryBreakdown;

  ChartDataResponse({
    required this.timeline,
    required this.categoryBreakdown,
  });

  factory ChartDataResponse.fromJson(Map<String, dynamic> json) {
    return ChartDataResponse(
      timeline: (json['timeline'] as List?)
              ?.map((t) => TimelineEntry.fromJson(t))
              .toList() ??
          [],
      categoryBreakdown: (json['category_breakdown'] as List?)
              ?.map((c) => CategoryBreakdown.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class TimelineEntry {
  final String date;
  final double income;
  final double expense;

  TimelineEntry({
    required this.date,
    required this.income,
    required this.expense,
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      date: json['date'] ?? '',
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryBreakdown {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final double total;
  final int count;

  CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.total,
    required this.count,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name'] ?? 'Unknown',
      categoryIcon: json['category_icon'] ?? '📦',
      categoryColor: json['category_color'] ?? '#999999',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
