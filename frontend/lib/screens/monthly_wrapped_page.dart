import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
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
      final wrapped = await DashboardService.getMonthlyWrapped(
        _month.year,
        _month.month,
      );

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

  Future<Uint8List> _captureImageBytes() async {
    final boundary =
    _wrappedKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  Future<void> _shareWrappedImage({
    required String failMessage,
  }) async {
    setState(() => _isExporting = true);

    try {
      final bytes = await _captureImageBytes();
      final filename =
          'monmon_wrapped_${DateFormat('yyyy_MM').format(_month)}.png';

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: filename,
            mimeType: 'image/png',
          ),
        ],
        text: 'Monthly Wrapped MonMon',
      );
    } catch (e) {
      if (!mounted) return;

      showAppSnack(
        context,
        failMessage,
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _downloadImage() async {
    await _shareWrappedImage(
      failMessage: 'Gagal menyiapkan gambar',
    );
  }

  Future<void> _shareImage() async {
    await _shareWrappedImage(
      failMessage: 'Gagal membagikan gambar',
    );
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
      setState(() {
        _month = DateTime(picked.year, picked.month);
      });

      _loadWrapped();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F1F8),
      appBar: AppBar(
        title: const Text('Monthly Wrapped'),
        elevation: 0,
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
          ? AppErrorState(
        message: _errorMessage!,
        onRetry: _loadWrapped,
      )
          : RefreshIndicator(
        onRefresh: _loadWrapped,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 620,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: _pickMonth,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('MMMM yyyy').format(_month),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.expand_more,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    key: _wrappedKey,
                    child: _WrappedCard(
                      wrapped: _wrapped!,
                      month: _month,
                    ),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Monthly Wrapped',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${wrapped.savingRate.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Text(
            'Saving rate bulan ini',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 22),

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
            const SizedBox(height: 20),
            ...wrapped.insights.map(
                  (insight) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 12),

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
      constraints: const BoxConstraints(
        minHeight: 74,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}