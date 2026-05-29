import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../data/app_data.dart';
import '../utils/formatter.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  Map<String, double> getCategoryData() {
    Map<String, double> data = {};

    for (var t in transaksi) {
      if (!t.isIncome) {
        data[t.category] =
            (data[t.category] ?? 0) + t.amount.toDouble();
      }
    }

    return data;
  }

  int getTotalExpense() {
    int total = 0;

    for (var t in transaksi) {
      if (!t.isIncome) {
        total += t.amount.toInt();
      }
    }

    return total;
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

  @override
  Widget build(BuildContext context) {
    final data = getCategoryData();
    final totalExpense = getTotalExpense();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan"),
        elevation: 0,
      ),
      body: data.isEmpty
          ? const _EmptyReport()
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TotalExpenseCard(
              totalExpense: totalExpense,
            ),

            const SizedBox(height: 22),

            const Text(
              "Pengeluaran per Kategori",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 210,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 52,
                        sectionsSpace: 4,
                        startDegreeOffset: -90,
                        sections: data.entries.map((entry) {
                          final percent =
                              (entry.value / totalExpense) * 100;

                          return PieChartSectionData(
                            value: entry.value,
                            title:
                            "${percent.toStringAsFixed(0)}%",
                            radius: 66,
                            color: getCategoryColor(entry.key),
                            titleStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    "Distribusi berdasarkan kategori pengeluaran",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Detail Kategori",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${data.length} kategori",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Column(
              children: data.entries.map((entry) {
                final percent =
                    (entry.value / totalExpense) * 100;

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
        ),
      ),
    );
  }
}

class _TotalExpenseCard extends StatelessWidget {
  final int totalExpense;

  const _TotalExpenseCard({
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade700,
            Colors.red.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Pengeluaran",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            formatRupiah(totalExpense),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          const Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                "Ringkasan pengeluaran kamu",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
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

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_chart_outlined,
                size: 48,
                color: Colors.grey.shade500,
              ),

              const SizedBox(height: 14),

              const Text(
                "Belum ada laporan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Tambahkan transaksi pengeluaran dulu supaya grafik bisa muncul.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}