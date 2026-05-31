import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';
import '../services/app_refresh_service.dart';
import '../utils/formatter.dart';
import '../widgets/responsive_content.dart';
import 'home_page.dart' show getCategoryColorFromHex;
import 'package:intl/intl.dart';
import '../services/export_service.dart';
import 'monthly_wrapped_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _isLoading = true;
  bool _isExporting = false;
  ChartDataResponse? _chartData;
  int _totalExpense = 0;

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _loadData();
    AppRefreshService.transactionsVersion.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    _loadData();
  }

  Future<void> _loadData() async {
    final startDate = _startDate.toIso8601String().split('T')[0];
    final endDate = _endDate.toIso8601String().split('T')[0];

    final chartData = await DashboardService.getChartData(
      startDate: startDate,
      endDate: endDate,
      groupBy: 'day',
    );

    if (!mounted) return;

    int totalExpense = 0;
    if (chartData != null) {
      for (final cat in chartData.categoryBreakdown) {
        totalExpense += cat.total.toInt();
      }
    }

    setState(() {
      _chartData = chartData;
      _totalExpense = totalExpense;
      _isLoading = false;
    });
  }

  Color _getCategoryColor(CategoryBreakdown cat) {
    return getCategoryColorFromHex(cat.categoryColor);
  }

  Future<void> _exportCSV() async {
    setState(() => _isExporting = true);
    final result = await ExportService.exportCSV(
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
    );
    if (!mounted) return;
    setState(() => _isExporting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _exportPDF() async {
    setState(() => _isExporting = true);
    final result = await ExportService.exportPDF(
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
    );
    if (!mounted) return;
    setState(() => _isExporting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _chartData?.categoryBreakdown ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan"),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            enabled: !_isExporting,
            onSelected: (value) {
              if (value == 'csv') _exportCSV();
              if (value == 'pdf') _exportPDF();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
            ],
          ),
        ],
      ),
      body: data.isEmpty
          ? const _EmptyReport()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: ResponsiveContent(
                  maxWidth: 920,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TotalExpenseCard(totalExpense: _totalExpense),

                      const SizedBox(height: 16),

                      FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MonthlyWrappedPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Monthly Wrapped'),
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
                                  sections: data.map((cat) {
                                    final percent = _totalExpense > 0
                                        ? (cat.total / _totalExpense) * 100
                                        : 0.0;

                                    return PieChartSectionData(
                                      value: cat.total,
                                      title: "${percent.toStringAsFixed(0)}%",
                                      radius: 66,
                                      color: _getCategoryColor(cat),
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
                        children: data.map((cat) {
                          final percent = _totalExpense > 0
                              ? (cat.total / _totalExpense) * 100
                              : 0.0;

                          return _CategoryReportItem(
                            category: cat.categoryName,
                            amount: cat.total.toInt(),
                            percent: percent,
                            color: _getCategoryColor(cat),
                          icon: _mapIcon(cat.categoryIcon),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  IconData _mapIcon(String iconStr) {
    switch (iconStr) {
      case '🍔':
        return Icons.restaurant;
      case '🚗':
        return Icons.directions_bus;
      case '🎮':
        return Icons.sports_esports;
      case '💰':
        return Icons.account_balance_wallet;
      case 'sell':
        return Icons.sell;
      case 'payments':
        return Icons.payments;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'sports_esports':
        return Icons.sports_esports;
      default:
        return Icons.category;
    }
  }

  @override
  void dispose() {
    AppRefreshService.transactionsVersion.removeListener(_onDataChanged);
    super.dispose();
  }
}

class _TotalExpenseCard extends StatelessWidget {
  final int totalExpense;

  const _TotalExpenseCard({required this.totalExpense});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade400],
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
            style: TextStyle(color: Colors.white70, fontSize: 14),
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
              Icon(Icons.pie_chart, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                "Ringkasan pengeluaran kamu",
                style: TextStyle(color: Colors.white, fontSize: 13),
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
        border: Border.all(color: Colors.grey.shade200),
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
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                "Tambahkan transaksi pengeluaran dulu supaya grafik bisa muncul.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
