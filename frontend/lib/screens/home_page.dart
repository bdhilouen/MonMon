import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_data.dart';
import '../models/transaction.dart';
import '../services/dashboard_service.dart';
import '../services/transaction_service.dart';
import '../services/app_refresh_service.dart';
import '../utils/category_icons.dart';
import '../utils/formatter.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/responsive_content.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../widgets/achievement_unlocked_dialog.dart';

Color getCategoryColor(String category) {
  switch (category) {
    case "Makan":
      return Colors.orange;
    case "Transport":
      return Colors.blue;
    case "Hiburan":
      return Colors.purple;
    case "Pemasukan":
      return Colors.green;
    case "Lainnya":
      return Colors.grey;
    default:
      return Colors.blueGrey;
  }
}

Color getCategoryColorFromHex(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) return Colors.blueGrey;
  try {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  } catch (_) {
    return Colors.blueGrey;
  }
}

class HomePage extends StatefulWidget {
  final Function(int) onTabChange;

  const HomePage({super.key, required this.onTabChange});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";
  bool _isLoading = true;

  // Data from API
  DashboardData? _dashboardData;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    AppRefreshService.transactionsVersion.addListener(_onDataChanged);
    _checkInitialAchievements();
  }

  Future<void> _checkInitialAchievements() async {
    final newAchievements = await AchievementService.checkAchievements();
    if (!mounted || newAchievements.isEmpty) return;

    for (final achievementData in newAchievements) {
      if (mounted && achievementData is Map<String, dynamic>) {
        final achievement = Achievement.fromJson(achievementData);
        showAchievementUnlockedDialog(context, achievement);
      }
    }
  }

  void _onDataChanged() {
    _loadData();
  }

  Future<void> _loadData() async {
    final dashboard = await DashboardService.getDashboard();
    if (!mounted) return;

    setState(() {
      _dashboardData = dashboard;
      _transactions = dashboard?.recentTransactions ?? [];
      _isLoading = false;
    });
  }

  int get saldo => _dashboardData?.user.balance.toInt() ?? 0;
  int get loginStreak => _dashboardData?.user.streak ?? 0;

  Map<String, int> getTotalPerCategory() {
    Map<String, int> result = {};
    for (var t in _transactions) {
      if (!t.isIncome) {
        result[t.category] = (result[t.category] ?? 0) + t.amount.toInt();
      }
    }
    return result;
  }

  List<Transaction> getFilteredTransactions() {
    if (searchQuery.trim().isEmpty) {
      return _transactions;
    }
    return _transactions.where((t) {
      return t.title.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  int getTotalIncome() => _dashboardData?.monthlyStats.totalIncome.toInt() ?? 0;

  int getTotalExpense() =>
      _dashboardData?.monthlyStats.totalExpense.toInt() ?? 0;

  void editTransaction(Transaction transaction) {
    if (transaction.id == null) return;

    final TextEditingController editTitle = TextEditingController(
      text: transaction.title,
    );
    final TextEditingController editAmount = TextEditingController(
      text: transaction.amount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Transaksi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editTitle,
                decoration: const InputDecoration(labelText: "Nama transaksi"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: editAmount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Nominal"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                final int newAmount = int.tryParse(editAmount.text) ?? 0;
                if (editTitle.text.trim().isEmpty || newAmount <= 0) return;

                Navigator.pop(context);

                final result = await TransactionService.update(
                  transaction.id!,
                  note: editTitle.text.trim(),
                  amount: newAmount.toDouble(),
                );

                if (result.success) {
                  AppRefreshService.notifyTransactionsChanged();
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void deleteTransaction(Transaction transaction) async {
    if (transaction.id == null) return;

    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: "Hapus Transaksi?",
      message: "Transaksi \"${transaction.title}\" akan dihapus permanen.",
    );
    if (!confirmed || !mounted) return;

    final result = await TransactionService.delete(transaction.id!);
    if (result.success) {
      AppRefreshService.notifyTransactionsChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredTransactions = getFilteredTransactions();
    final latestTransactions = filteredTransactions.take(3).toList();
    final categoryData = getTotalPerCategory();

    final bool isSearching = searchQuery.trim().isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Halo, ${_dashboardData?.user.name ?? 'User'}!"),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: ResponsiveContent(
            maxWidth: 920,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BalanceCard(saldo: saldo),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: "Pemasukan",
                        value: formatRupiah(getTotalIncome()),
                        icon: Icons.arrow_downward,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: "Pengeluaran",
                        value: formatRupiah(getTotalExpense()),
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Cari transaksi...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: isSearching
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                searchController.clear();
                                searchQuery = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                if (categoryData.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Kategori Pengeluaran",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onTabChange(2),
                        child: const Text("Laporan"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: categoryData.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: getCategoryColor(
                              entry.key,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: getCategoryColor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${entry.key} • ${formatRupiah(entry.value)}",
                                style: TextStyle(
                                  color: getCategoryColor(entry.key),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSearching ? "Hasil Pencarian" : "Transaksi Terbaru",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.onTabChange(1),
                      child: const Text("Lihat Semua"),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (_transactions.isEmpty)
                  const _EmptyState(
                    icon: Icons.receipt_long,
                    title: "Belum ada transaksi",
                    subtitle: "Tambahkan transaksi pertama lewat tombol +.",
                  )
                else if (filteredTransactions.isEmpty)
                  const _EmptyState(
                    icon: Icons.search_off,
                    title: "Transaksi tidak ditemukan",
                    subtitle: "Coba pakai kata kunci lain.",
                  )
                else
                  Column(
                    children: latestTransactions.map((transaction) {
                      return _TransactionTile(
                        transaction: transaction,
                        onTap: () => editTransaction(transaction),
                        onDelete: () => deleteTransaction(transaction),
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

  @override
  void dispose() {
    searchController.dispose();
    AppRefreshService.transactionsVersion.removeListener(_onDataChanged);
    super.dispose();
  }
}

class _BalanceCard extends StatelessWidget {
  final int saldo;

  const _BalanceCard({required this.saldo});

  @override
  Widget build(BuildContext context) {
    final bool isPositive = saldo >= 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [Colors.blue.shade700, Colors.blue.shade500]
              : [Colors.red.shade700, Colors.red.shade400],
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
            "Saldo Saat Ini",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            formatRupiah(saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isPositive
                    ? "Keuangan masih aman"
                    : "Pengeluaran melebihi pemasukan",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 105),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.isIncome;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color:
                (transaction.categoryColor != null
                        ? getCategoryColorFromHex(transaction.categoryColor)
                        : getCategoryColor(transaction.category))
                    .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            categoryIconFor(
              icon: transaction.categoryIcon,
              name: transaction.category,
              isIncome: isIncome,
            ),
            color: transaction.categoryColor != null
                ? getCategoryColorFromHex(transaction.categoryColor)
                : getCategoryColor(transaction.category),
            size: 22,
          ),
        ),
        title: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${transaction.category} • ${DateFormat('dd MMM yyyy').format(transaction.date)}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${isIncome ? '+' : '-'} ${formatRupiah(transaction.amount.toInt())}",
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
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
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
