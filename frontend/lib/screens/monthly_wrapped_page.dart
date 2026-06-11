import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

// Conditional import: Web gets the stub, native gets dart:io + share_plus.
import '../services/wrapped_image_native.dart'
    if (dart.library.js_interop) '../services/wrapped_image_web.dart'
    as wrapped_io;

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
  bool _hideAmounts = false;
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

  /// Captures the wrapped card widget as PNG bytes.
  Future<Uint8List> _captureBytes() async {
    final boundary =
        _wrappedKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  String get _filename =>
      'monmon_wrapped_${DateFormat('yyyy_MM').format(_month)}.png';

  Future<void> _downloadImage() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _captureBytes();
      final filePath = await wrapped_io.saveWrappedImage(
        bytes,
        _filename,
      );
      if (!mounted) return;
      showAppSnack(context, 'Gambar tersimpan: $filePath');
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
      final bytes = await _captureBytes();
      await wrapped_io.shareWrappedImage(bytes, _filename);
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
          // Share only available on native (mobile/desktop).
          if (!kIsWeb)
            IconButton(
              onPressed: _isExporting || _wrapped == null ? null : _shareImage,
              icon: const Icon(Icons.ios_share),
              tooltip: 'Share',
            ),
          // Download available on all platforms (native + web).
          IconButton(
            onPressed:
                _isExporting || _wrapped == null ? null : _downloadImage,
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
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
                                    Icon(
                                      Icons.expand_more,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Privacy toggle – outside RepaintBoundary so it
                            // does NOT appear in shared/downloaded images.
                            _PrivacyToggle(
                              hidden: _hideAmounts,
                              onChanged: (v) =>
                                  setState(() => _hideAmounts = v),
                            ),
                            const SizedBox(height: 10),
                            RepaintBoundary(
                              key: _wrappedKey,
                              child: _WrappedCard(
                                wrapped: _wrapped!,
                                month: _month,
                                hideAmounts: _hideAmounts,
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
  final bool hideAmounts;

  const _WrappedCard({
    required this.wrapped,
    required this.month,
    this.hideAmounts = false,
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
              SvgPicture.asset(
                'assets/images/monmon_logo.svg',
                height: 80,
                width: 80,
              ),
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
          if (!hideAmounts) ...[
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
          ],
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
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orange.shade300,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Streak',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${wrapped.streak} hari',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wrapped.streak >= 7
                      ? 'Luar biasa, pertahankan! 🔥'
                      : wrapped.streak >= 3
                          ? 'Keren, lanjutkan streak ini'
                          : 'Tetap konsisten 🔥',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (wrapped.insights.isNotEmpty) ...[
            const SizedBox(height: 18),
            ...wrapped.insights.map(
              (insight) => Padding(
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

/// A toggle pill that lets the user hide or reveal nominal amounts.
/// Placed outside [RepaintBoundary] so it never appears in exports.
class _PrivacyToggle extends StatelessWidget {
  final bool hidden;
  final ValueChanged<bool> onChanged;

  const _PrivacyToggle({required this.hidden, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!hidden),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hidden ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hidden ? Colors.blue.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hidden ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: hidden ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              hidden ? 'Nominal disembunyikan' : 'Sembunyikan nominal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hidden ? Colors.blue.shade700 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WrappedMetric extends StatelessWidget {
  final String label;
  final String value;

  const _WrappedMetric({required this.label, required this.value});

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
