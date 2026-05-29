import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_data.dart';
import '../services/app_refresh_service.dart';
import '../services/dashboard_service.dart';
import '../services/export_service.dart';
import '../utils/formatter.dart';
import 'monthly_wrapped_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  ChartDataResponse? _chartData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isExporting = false;

  // Default: current month range
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    AppRefreshService.transactionsVersion.addListener(loadChartData);
    loadChartData();
  }

  @override
  void dispose() {
    AppRefreshService.transactionsVersion.removeListener(loadChartData);
    super.dispose();
  }

  Future<void> loadChartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await DashboardService.getChartData(
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        groupBy: 'day',
      );

      if (!mounted) return;
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      loadChartData();
    }
  }

  double get _totalExpense {
    if (_chartData == null) return 0;
    return _chartData!.categoryBreakdown.fold(0.0, (sum, c) => sum + c.total);
  }

  Color _parseColor(String hex) {
    try {
      final cleanHex = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan"),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      ElevatedButton(
                        onPressed: loadChartData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadChartData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Date range selector
                        InkWell(
                          onTap: _selectDateRange,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_drop_down,
                                    color: Colors.grey.shade600),
                              ],
                            ),
                          ),
                        ),

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

                        const SizedBox(height: 16),

                        // Total Expense Card
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
                                formatRupiah(_totalExpense),
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

                        if (_chartData != null &&
                            _chartData!.categoryBreakdown.isNotEmpty) ...[
                          const Text(
                            "Pengeluaran per Kategori",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Pie chart
                          SizedBox(
                            height: 260,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 45,
                                sectionsSpace: 3,
                                sections: _chartData!.categoryBreakdown
                                    .map((cat) {
                                  final percent = _totalExpense > 0
                                      ? (cat.total / _totalExpense) * 100
                                      : 0.0;

                                  return PieChartSectionData(
                                    value: cat.total,
                                    title:
                                        "${percent.toStringAsFixed(0)}%",
                                    radius: 85,
                                    color: _parseColor(cat.categoryColor),
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

                          // Category details
                          const Text(
                            "Detail Kategori",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ...(_chartData!.categoryBreakdown.map((cat) {
                            final percent = _totalExpense > 0
                                ? (cat.total / _totalExpense) * 100
                                : 0.0;

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
                                      color:
                                          _parseColor(cat.categoryColor),
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
                                          "${cat.categoryIcon} ${cat.categoryName}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${percent.toStringAsFixed(0)}% dari total • ${cat.count} transaksi",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(cat.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })),
                        ],

                        if (_chartData == null ||
                            _chartData!.categoryBreakdown.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                "Belum ada data pengeluaran 😴",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
