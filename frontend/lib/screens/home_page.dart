import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_data.dart';
import '../models/transaction.dart';
import '../services/app_refresh_service.dart';
import '../services/dashboard_service.dart';
import '../services/transaction_service.dart';
import '../utils/formatter.dart';

class HomePage extends StatefulWidget {
  final Function(int) onTabChange;

  const HomePage({
    super.key,
    required this.onTabChange,
  });

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  DashboardData? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppRefreshService.transactionsVersion.addListener(loadDashboard);
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboard = await DashboardService.getDashboard();
      if (!mounted) return;

      if (dashboard != null) {
        setState(() {
          _dashboard = dashboard;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data dashboard';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Transaction> _getFilteredTransactions() {
    final transactions = _dashboard?.recentTransactions ?? [];
    if (_searchQuery.isEmpty) return transactions;

    return transactions.where((t) {
      return t.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.note ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await TransactionService.delete(transaction.id);
      if (result.success) {
        loadDashboard();
        AppRefreshService.notifyTransactionsChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil dihapus'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getCategoryColor(Transaction t) {
    if (t.categorySnapshot != null && t.categoryColor != '#999999') {
      try {
        final hex = t.categoryColor.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    if (t.isIncome) return Colors.green;
    return Colors.orange;
  }

  @override
  void dispose() {
    AppRefreshService.transactionsVersion.removeListener(loadDashboard);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("MonMon")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadDashboard,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadDashboard,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Balance
                            Text(
                              "Saldo: ${formatRupiah(_dashboard!.user.balance)}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _dashboard!.user.balance >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Income & Expense cards
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Pemasukan",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          formatRupiah(
                                              _dashboard!.monthlyStats.totalIncome),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Pengeluaran",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          formatRupiah(
                                              _dashboard!.monthlyStats.totalExpense),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Search
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "Cari transaksi...",
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Transaksi Terbaru",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    widget.onTabChange(1);
                                  },
                                  child: const Text("Lihat Semua"),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                          ]),
                        ),
                      ),

                      // Transaction List
                      if (_getFilteredTransactions().isEmpty)
                        const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text("Belum ada transaksi 😴"),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final transaction =
                                    _getFilteredTransactions()[index];
                                return Card(
                                  elevation: 5,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.circle,
                                      color: _getCategoryColor(transaction),
                                    ),
                                    title: Text(transaction.categoryName),
                                    subtitle: Text(
                                      "${transaction.isIncome ? '+' : '-'} ${formatRupiah(transaction.amount)}\n${DateFormat('dd MMM yyyy').format(transaction.date)}",
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        _deleteTransaction(transaction);
                                      },
                                    ),
                                  ),
                                );
                              },
                              childCount: _getFilteredTransactions().length > 5
                                  ? 5
                                  : _getFilteredTransactions().length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
