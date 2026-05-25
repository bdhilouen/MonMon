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
        total += t.amount;
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
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = getCategoryData();
    final totalExpense = getTotalExpense();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: data.isEmpty
            ? Center(
          child: Text(
            "Belum ada data pengeluaran 😴",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(18),
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
                  const SizedBox(height: 8),
                  Text(
                    formatRupiah(totalExpense),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Pengeluaran per Kategori",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 260,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 45,
                  sectionsSpace: 3,
                  sections: data.entries.map((entry) {
                    final percent =
                        (entry.value / totalExpense) * 100;

                    return PieChartSectionData(
                      value: entry.value,
                      title:
                      "${percent.toStringAsFixed(0)}%",
                      radius: 85,
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

            const SizedBox(height: 24),

            const Text(
              "Detail Kategori",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: data.entries.map((entry) {
                  final percent =
                      (entry.value / totalExpense) * 100;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: getCategoryColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
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

                        Text(
                          formatRupiah(entry.value.toInt()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}