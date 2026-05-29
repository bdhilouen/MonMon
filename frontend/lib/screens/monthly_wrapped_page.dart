import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/monthly_wrapped.dart';
import '../services/app_refresh_service.dart';
import '../services/dashboard_service.dart';
import '../utils/formatter.dart';
import '../widgets/app_state_widgets.dart';

class MonthlyWrappedPage extends StatefulWidget {
  const MonthlyWrappedPage({super.key});

  @override
  State<MonthlyWrappedPage> createState() => _MonthlyWrappedPageState();
}

class _MonthlyWrappedPageState extends State<MonthlyWrappedPage> {
  final _wrappedKey = GlobalKey();
  MonthlyWrapped? _wrapped;
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    AppRefreshService.transactionsVersion.addListener(_loadWrapped);
    _loadWrapped();
  }

  @override
  void dispose() {
    AppRefreshService.transactionsVersion.removeListener(_loadWrapped);
    super.dispose();
  }

  Future<void> _loadWrapped() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wrapped =
          await DashboardService.getMonthlyWrapped(_month.year, _month.month);
      if (!mounted) return;
      setState(() {
        _wrapped = wrapped;
        _errorMessage = wrapped == null ? 'Gagal memuat Monthly Wrapped' : null;
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

  Future<File> _captureImage() async {
    final boundary =
        _wrappedKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final directory = await getApplicationDocumentsDirectory();
    final filename = 'monmon_wrapped_${DateFormat('yyyy_MM').format(_month)}.png';
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _downloadImage() async {
    setState(() => _isExporting = true);
    try {
      final file = await _captureImage();
      if (!mounted) return;
      showAppSnack(context, 'Gambar tersimpan: ${file.path}');
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, 'Gagal menyimpan gambar', success: false);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareImage() async {
    setState(() => _isExporting = true);
    try {
      final file = await _captureImage();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Monthly Wrapped MonMon',
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, 'Gagal membagikan gambar', success: false);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
      _loadWrapped();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Wrapped'),
        actions: [
          IconButton(
            onPressed: _isExporting || _wrapped == null ? null : _shareImage,
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share',
          ),
          IconButton(
            onPressed: _isExporting || _wrapped == null ? null : _downloadImage,
            icon: const Icon(Icons.download),
            tooltip: 'Download',
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoading()
          : _errorMessage != null
              ? AppErrorState(message: _errorMessage!, onRetry: _loadWrapped)
              : RefreshIndicator(
                  onRefresh: _loadWrapped,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: _pickMonth,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('MMMM yyyy').format(_month),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.expand_more,
                                    color: Colors.grey.shade600),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          key: _wrappedKey,
                          child: _WrappedCard(wrapped: _wrapped!, month: _month),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _WrappedCard extends StatelessWidget {
  final MonthlyWrapped wrapped;
  final DateTime month;

  const _WrappedCard({
    required this.wrapped,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM yyyy').format(month),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${wrapped.savingRate.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Saving rate bulan ini',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _WrappedMetric(
                  label: 'Pemasukan',
                  value: formatRupiah(wrapped.totalIncome),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WrappedMetric(
                  label: 'Pengeluaran',
                  value: formatRupiah(wrapped.totalExpense),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _WrappedMetric(
                  label: 'Top category',
                  value: wrapped.topCategory ?? '-',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WrappedMetric(
                  label: 'Transaksi',
                  value: '${wrapped.totalTransactions}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WrappedMetric(
            label: 'Streak',
            value: '${wrapped.streak} hari',
          ),
          if (wrapped.insights.isNotEmpty) ...[
            const SizedBox(height: 18),
            ...wrapped.insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'MonMon',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WrappedMetric extends StatelessWidget {
  final String label;
  final String value;

  const _WrappedMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
