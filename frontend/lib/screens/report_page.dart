import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../data/app_data.dart';
import '../utils/formatter.dart';
import 'monthly_wrapped_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late DateTime selectedMonth;
  int selectedTab = 0;

  final List<String> tabs = [
    "Ringkasan",
    "Kategori",
    "Mingguan",
  ];

  final List<String> monthNames = const [
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember",
  ];

  final List<String> shortMonthNames = const [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "Mei",
    "Jun",
    "Jul",
    "Agu",
    "Sep",
    "Okt",
    "Nov",
    "Des",
  ];

  final List<String> dayNames = const [
    "Sen",
    "Sel",
    "Rab",
    "Kam",
    "Jum",
    "Sab",
    "Min",
  ];

  @override
  void initState() {
    super.initState();

    if (transaksi.isNotEmpty) {
      final sortedTransactions = [...transaksi]
        ..sort((a, b) => b.date.compareTo(a.date));

      selectedMonth = DateTime(
        sortedTransactions.first.date.year,
        sortedTransactions.first.date.month,
      );
    } else {
      final now = DateTime.now();
      selectedMonth = DateTime(now.year, now.month);
    }
  }

  List<DateTime> getMonthOptions() {
    final Map<String, DateTime> monthMap = {};

    final now = DateTime.now();

    for (int i = 0; i < 5; i++) {
      final month = DateTime(now.year, now.month - i);
      monthMap["${month.year}-${month.month}"] = month;
    }

    for (var transaction in transaksi) {
      final month = DateTime(
        transaction.date.year,
        transaction.date.month,
      );

      monthMap["${month.year}-${month.month}"] = month;
    }

    final months = monthMap.values.toList()
      ..sort((a, b) => b.compareTo(a));

    return months;
  }

  List<dynamic> getSelectedMonthTransactions() {
    return transaksi.where((transaction) {
      return transaction.date.year == selectedMonth.year &&
          transaction.date.month == selectedMonth.month;
    }).toList();
  }

  int getTotalIncome(List<dynamic> monthlyTransactions) {
    int total = 0;

    for (var transaction in monthlyTransactions) {
      if (transaction.isIncome) {
        final amount = (transaction.amount as num).toInt();
        total += amount;
      }
    }

    return total;
  }

  int getTotalExpense(List<dynamic> monthlyTransactions) {
    int total = 0;

    for (var transaction in monthlyTransactions) {
      if (!transaction.isIncome) {
        final amount = (transaction.amount as num).toInt();
        total += amount;
      }
    }

    return total;
  }

  Map<String, double> getCategoryData(List<dynamic> monthlyTransactions) {
    Map<String, double> data = {};

    for (var transaction in monthlyTransactions) {
      if (!transaction.isIncome) {
        data[transaction.category] =
            (data[transaction.category] ?? 0) +
                transaction.amount.toDouble();
      }
    }

    return data;
  }

  Map<int, int> getWeeklyExpense(List<dynamic> monthlyTransactions) {
    Map<int, int> weeklyData = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0,
    };

    for (var transaction in monthlyTransactions) {
      if (!transaction.isIncome) {
        final weekday = transaction.date.weekday;

        final amount = (transaction.amount as num).toInt();

        weeklyData[weekday] =
            (weeklyData[weekday] ?? 0) + amount;
      }
    }

    return weeklyData;
  }

  String getMonthLabel(DateTime month) {
    return "${monthNames[month.month - 1]} ${month.year}";
  }

  String getShortDate(DateTime date) {
    return "${date.day} ${shortMonthNames[date.month - 1]} ${date.year}";
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case "Makan":
        return Colors.orange;
      case "Transport":
        return Colors.blue;
      case "Hiburan":
        return Colors.purple;
      case "Lainnya":
        return Colors.grey;
      case "Pemasukan":
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case "Makan":
        return Icons.restaurant;
      case "Transport":
        return Icons.directions_bus;
      case "Hiburan":
        return Icons.sports_esports;
      case "Lainnya":
        return Icons.more_horiz;
      case "Pemasukan":
        return Icons.arrow_downward;
      default:
        return Icons.category;
    }
  }

  String getHighestCategory(Map<String, double> categoryData) {
    if (categoryData.isEmpty) {
      return "-";
    }

    final sorted = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  String getMostWastefulDay(List<dynamic> monthlyTransactions) {
    final Map<String, int> dailyExpense = {};

    for (var transaction in monthlyTransactions) {
      if (!transaction.isIncome) {
        final key =
            "${transaction.date.year}-${transaction.date.month}-${transaction.date.day}";

        final amount = (transaction.amount as num).toInt();

        dailyExpense[key] =
            (dailyExpense[key] ?? 0) + amount;
      }
    }

    if (dailyExpense.isEmpty) {
      return "-";
    }

    final sorted = dailyExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final parts = sorted.first.key.split("-");
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    return getShortDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTransactions = getSelectedMonthTransactions();
    final categoryData = getCategoryData(monthlyTransactions);
    final totalIncome = getTotalIncome(monthlyTransactions);
    final totalExpense = getTotalExpense(monthlyTransactions);
    final savedAmount = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F1F8),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 980,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "MonMon",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Laporan",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _MonthSelector(
                    months: getMonthOptions(),
                    selectedMonth: selectedMonth,
                    getMonthLabel: getMonthLabel,
                    onSelected: (month) {
                      setState(() {
                        selectedMonth = month;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  _SummaryHeaderCard(
                    monthLabel: getMonthLabel(selectedMonth),
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    savedAmount: savedAmount,
                    highestCategory: getHighestCategory(categoryData),
                    mostWastefulDay: getMostWastefulDay(monthlyTransactions),
                  ),

                  const SizedBox(height: 16),

                  _TabSelector(
                    tabs: tabs,
                    selectedIndex: selectedTab,
                    onSelected: (index) {
                      setState(() {
                        selectedTab = index;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  if (selectedTab == 0)
                    _buildSummaryTab(
                      monthlyTransactions: monthlyTransactions,
                      categoryData: categoryData,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      savedAmount: savedAmount,
                    ),

                  if (selectedTab == 1)
                    _buildCategoryTab(
                      categoryData: categoryData,
                      totalExpense: totalExpense,
                    ),

                  if (selectedTab == 2)
                    _buildWeeklyTab(
                      monthlyTransactions: monthlyTransactions,
                      weeklyData: getWeeklyExpense(monthlyTransactions),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTab({
    required List<dynamic> monthlyTransactions,
    required Map<String, double> categoryData,
    required int totalIncome,
    required int totalExpense,
    required int savedAmount,
  }) {
    final recentExpenses = monthlyTransactions
        .where((transaction) => !transaction.isIncome)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ringkasan Bulan Ini",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        _CashFlowCard(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          savedAmount: savedAmount,
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _MiniInfoCard(
                icon: Icons.trending_up,
                label: "Pemasukan",
                value: formatRupiah(totalIncome),
                color: Colors.green,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _MiniInfoCard(
                icon: Icons.trending_down,
                label: "Pengeluaran",
                value: formatRupiah(totalExpense),
                color: Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _MiniInfoCard(
                icon: Icons.savings,
                label: "Ditabung",
                value: formatRupiah(savedAmount),
                color: savedAmount >= 0 ? Colors.blue : Colors.red,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _MiniInfoCard(
                icon: Icons.category,
                label: "Kategori",
                value: "${categoryData.length}",
                color: Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        const SizedBox(height: 16),

        _MonthlyWrappedCard(
          title: "${monthNames[selectedMonth.month - 1]} in Review",
          subtitle: "lihat kilas balik keuanganmu bulan ini",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MonthlyWrappedPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        const Text(
          "Transaksi Pengeluaran Terbaru",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (recentExpenses.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: "Belum ada pengeluaran",
            message: "Pengeluaran bulan ini belum tercatat.",
          )
        else
          Column(
            children: recentExpenses.take(5).map((transaction) {
              final color = getCategoryColor(transaction.category);

              return _TransactionPreviewItem(
                title: transaction.title,
                category: transaction.category,
                amount: transaction.amount.toInt(),
                date: getShortDate(transaction.date),
                color: color,
                icon: getCategoryIcon(transaction.category),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCategoryTab({
    required Map<String, double> categoryData,
    required int totalExpense,
  }) {
    if (categoryData.isEmpty || totalExpense == 0) {
      return const _EmptyState(
        icon: Icons.pie_chart_outline,
        title: "Belum ada data kategori",
        message: "Tambahkan transaksi pengeluaran dulu supaya grafik muncul.",
      );
    }

    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Proporsi Pengeluaran",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        _CategoryChartCard(
          data: sortedEntries,
          totalExpense: totalExpense,
          getCategoryColor: getCategoryColor,
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Detail per Kategori",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "${categoryData.length} kategori",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Column(
          children: sortedEntries.map((entry) {
            final percent = (entry.value / totalExpense) * 100;

            return _CategoryReportItem(
              category: entry.key,
              amount: entry.value.toInt(),
              percent: percent,
              color: getCategoryColor(entry.key),
              icon: getCategoryIcon(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeeklyTab({
    required List<dynamic> monthlyTransactions,
    required Map<int, int> weeklyData,
  }) {
    final maxValue = weeklyData.values.isEmpty
        ? 0
        : weeklyData.values.reduce(math.max);

    final recentTransactions = monthlyTransactions
        .where((transaction) => !transaction.isIncome)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pengeluaran Mingguan",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 210,
                child: BarChart(
                  BarChartData(
                    maxY: maxValue == 0 ? 10 : maxValue * 1.25,
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            if (index < 0 || index >= dayNames.length) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dayNames[index],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(7, (index) {
                      final weekday = index + 1;
                      final value = weeklyData[weekday] ?? 0;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: value.toDouble(),
                            width: 18,
                            borderRadius: BorderRadius.circular(8),
                            color: value == 0
                                ? Colors.grey.shade300
                                : Colors.blue.shade500,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Rata-rata harian dari transaksi pengeluaran bulan ini.",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          "Log Pengeluaran",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (recentTransactions.isEmpty)
          const _EmptyState(
            icon: Icons.calendar_month_outlined,
            title: "Belum ada log mingguan",
            message: "Transaksi bulan ini belum tersedia.",
          )
        else
          Column(
            children: recentTransactions.take(7).map((transaction) {
              final color = getCategoryColor(transaction.category);

              return _TransactionPreviewItem(
                title: transaction.title,
                category: transaction.category,
                amount: transaction.amount.toInt(),
                date: getShortDate(transaction.date),
                color: color,
                icon: getCategoryIcon(transaction.category),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final List<DateTime> months;
  final DateTime selectedMonth;
  final String Function(DateTime month) getMonthLabel;
  final Function(DateTime month) onSelected;

  const _MonthSelector({
    required this.months,
    required this.selectedMonth,
    required this.getMonthLabel,
    required this.onSelected,
  });

  bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final month = months[index];
          final selected = isSameMonth(month, selectedMonth);

          return GestureDetector(
            onTap: () => onSelected(month),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: selected ? Colors.blue.shade500 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? Colors.blue.shade500
                      : Colors.grey.shade200,
                ),
              ),
              child: Text(
                getMonthLabel(month),
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryHeaderCard extends StatelessWidget {
  final String monthLabel;
  final int totalIncome;
  final int totalExpense;
  final int savedAmount;
  final String highestCategory;
  final String mostWastefulDay;

  const _SummaryHeaderCard({
    required this.monthLabel,
    required this.totalIncome,
    required this.totalExpense,
    required this.savedAmount,
    required this.highestCategory,
    required this.mostWastefulDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ringkasan",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            monthLabel,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  label: "Pemasukan",
                  value: formatRupiah(totalIncome),
                  color: Colors.green,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _HeaderStat(
                  label: "Pengeluaran",
                  value: formatRupiah(totalExpense),
                  color: Colors.red,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _HeaderStat(
                  label: "Ditabung",
                  value: formatRupiah(savedAmount),
                  color: savedAmount >= 0 ? Colors.blue : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _InsightRow(
            icon: Icons.warning_amber_rounded,
            label: "Pengeluaran terbesar",
            value: highestCategory,
          ),

          const SizedBox(height: 10),

          _InsightRow(
            icon: Icons.calendar_today,
            label: "Hari paling boros",
            value: mostWastefulDay,
          ),

          const SizedBox(height: 10),

          _InsightRow(
            icon: Icons.show_chart,
            label: "Laporan arus kas",
            value: savedAmount >= 0 ? "Masih aman" : "Defisit",
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.blue.shade500,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _TabSelector extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int index) onSelected;

  const _TabSelector({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.blue.shade500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CashFlowCard extends StatelessWidget {
  final int totalIncome;
  final int totalExpense;
  final int savedAmount;

  const _CashFlowCard({
    required this.totalIncome,
    required this.totalExpense,
    required this.savedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isSafe = savedAmount >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSafe ? Icons.trending_up : Icons.trending_down,
              color: Colors.white,
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSafe ? "Keuangan masih aman" : "Pengeluaran melebihi pemasukan",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "Selisih bulan ini: ${formatRupiah(savedAmount)}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),

          const Spacer(),

          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChartCard extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final int totalExpense;
  final Color Function(String category) getCategoryColor;

  const _CategoryChartCard({
    required this.data,
    required this.totalExpense,
    required this.getCategoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 56,
                sectionsSpace: 3,
                startDegreeOffset: -90,
                sections: data.map((entry) {
                  final percent = (entry.value / totalExpense) * 100;

                  return PieChartSectionData(
                    value: entry.value,
                    title: "${percent.toStringAsFixed(0)}%",
                    radius: 68,
                    color: getCategoryColor(entry.key),
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: data.map((entry) {
              return _LegendItem(
                label: entry.key,
                color: getCategoryColor(entry.key),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          Text(
            "Total pengeluaran: ${formatRupiah(totalExpense)}",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 6),

        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _CategoryReportItem extends StatelessWidget {
  final String category;
  final int amount;
  final double percent;
  final Color color;
  final IconData icon;

  const _CategoryReportItem({
    required this.category,
    required this.amount,
    required this.percent,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    color: color,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "${percent.toStringAsFixed(0)}% dari total pengeluaran",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 86,
            child: Text(
              formatRupiah(amount),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionPreviewItem extends StatelessWidget {
  final String title;
  final String category;
  final int amount;
  final String date;
  final Color color;
  final IconData icon;

  const _TransactionPreviewItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "$category • $date",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            "- ${formatRupiah(amount)}",
            style: TextStyle(
              color: Colors.red.shade500,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
class _MonthlyWrappedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MonthlyWrappedCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade500,
              Colors.cyan.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Monthly Wrapped",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Buka Wrapped",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.blue.shade700,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey.shade500,
          ),

          const SizedBox(height: 14),

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}