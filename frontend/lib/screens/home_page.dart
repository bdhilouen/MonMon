import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../utils/formatter.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';
import '../services/transaction_service.dart';
import '../services/app_refresh_service.dart';

enum HomeBadgeRule {
  streak,
  firstTransaction,
  activeRecorder,
  categoryCollector,
  positiveBalance,
  controlledExpense,
  expenseAnalyzer,
  incomeRecorder,
}

class HomeWalletBadge {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final HomeBadgeRule rule;
  final int target;

  const HomeWalletBadge({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.rule,
    required this.target,
  });
}

class HomePage extends StatefulWidget {
  final Function(int) onTabChange;

  const HomePage({
    super.key,
    required this.onTabChange,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

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

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";

  DashboardData? _dashboard;
  bool _isLoadingDashboard = true;
  String? _dashboardErrorMessage;

  @override
  void initState() {
    super.initState();
    AppRefreshService.transactionsVersion.addListener(loadDashboard);
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardErrorMessage = null;
    });

    try {
      final result = await DashboardService.getDashboard();

      if (!mounted) return;

      setState(() {
        _dashboard = result;
        _isLoadingDashboard = false;
        _dashboardErrorMessage =
        result == null ? "Gagal memuat dashboard" : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _dashboardErrorMessage = e.toString();
        _isLoadingDashboard = false;
      });
    }
  }

  List<Transaction> get dashboardTransactions {
    return _dashboard?.recentTransactions ?? [];
  }

  Map<String, int> getTotalPerCategory() {
    final Map<String, int> result = {};

    for (var transaction in dashboardTransactions) {
      if (!transaction.isIncome) {
        result[transaction.category] =
            (result[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return result;
  }

  List<Transaction> getFilteredTransactions() {
    final sortedTransactions = [...dashboardTransactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    if (searchQuery.trim().isEmpty) {
      return sortedTransactions;
    }

    final query = searchQuery.toLowerCase();

    return sortedTransactions.where((transaction) {
      return transaction.title.toLowerCase().contains(query) ||
          transaction.category.toLowerCase().contains(query);
    }).toList();
  }

  int getTotalIncome() {
    return _dashboard?.monthlyStats.totalIncome.toInt() ?? 0;
  }

  int getTotalExpense() {
    return _dashboard?.monthlyStats.totalExpense.toInt() ?? 0;
  }

  int getExpenseCategoryCount() {
    return getTotalPerCategory().length;
  }

  List<HomeWalletBadge> getHomeBadges() {
    return const [
      HomeWalletBadge(
        name: "Dompet Defender",
        subtitle: "Login selama 7 hari berturut-turut.",
        icon: Icons.shield,
        color: Color(0xFF35B7E8),
        rule: HomeBadgeRule.streak,
        target: 7,
      ),
      HomeWalletBadge(
        name: "Dompet Guardian",
        subtitle: "Login selama 14 hari berturut-turut.",
        icon: Icons.verified_user,
        color: Color(0xFF2ECC71),
        rule: HomeBadgeRule.streak,
        target: 14,
      ),
      HomeWalletBadge(
        name: "Dompet Sentinel",
        subtitle: "Login selama 30 hari berturut-turut.",
        icon: Icons.visibility,
        color: Color(0xFFF1C40F),
        rule: HomeBadgeRule.streak,
        target: 30,
      ),
      HomeWalletBadge(
        name: "Dompet Vanguard",
        subtitle: "Login selama 60 hari berturut-turut.",
        icon: Icons.lock,
        color: Color(0xFFE67E22),
        rule: HomeBadgeRule.streak,
        target: 60,
      ),
      HomeWalletBadge(
        name: "Dompet Commander",
        subtitle: "Login selama 90 hari berturut-turut.",
        icon: Icons.military_tech,
        color: Color(0xFF9B59B6),
        rule: HomeBadgeRule.streak,
        target: 90,
      ),
      HomeWalletBadge(
        name: "Dompet Strategist",
        subtitle: "Login selama 120 hari berturut-turut.",
        icon: Icons.emoji_events,
        color: Color(0xFF34495E),
        rule: HomeBadgeRule.streak,
        target: 120,
      ),
      HomeWalletBadge(
        name: "Dompet Sovereign",
        subtitle: "Login selama 365 hari berturut-turut.",
        icon: Icons.workspace_premium,
        color: Color(0xFFD4AF37),
        rule: HomeBadgeRule.streak,
        target: 365,
      ),

      HomeWalletBadge(
        name: "Transaksi Pertama",
        subtitle: "Kamu sudah mencatat transaksi pertama.",
        icon: Icons.flag,
        color: Colors.blue,
        rule: HomeBadgeRule.firstTransaction,
        target: 1,
      ),
      HomeWalletBadge(
        name: "Pencatat Aktif",
        subtitle: "Kamu sudah mencatat minimal 10 transaksi.",
        icon: Icons.edit_note,
        color: Colors.orange,
        rule: HomeBadgeRule.activeRecorder,
        target: 10,
      ),
      HomeWalletBadge(
        name: "Kolektor Kategori",
        subtitle: "Kamu punya minimal 5 kategori transaksi.",
        icon: Icons.category,
        color: Colors.purple,
        rule: HomeBadgeRule.categoryCollector,
        target: 5,
      ),
      HomeWalletBadge(
        name: "Saldo Aman",
        subtitle: "Saldo kamu masih bernilai positif.",
        icon: Icons.safety_check,
        color: Colors.green,
        rule: HomeBadgeRule.positiveBalance,
        target: 1,
      ),
      HomeWalletBadge(
        name: "Pengeluaran Terkontrol",
        subtitle: "Pemasukanmu masih menahan pengeluaran.",
        icon: Icons.balance,
        color: Colors.teal,
        rule: HomeBadgeRule.controlledExpense,
        target: 1,
      ),
      HomeWalletBadge(
        name: "Analis Dompet",
        subtitle: "Pengeluaranmu tersebar di minimal 3 kategori.",
        icon: Icons.pie_chart,
        color: Colors.red,
        rule: HomeBadgeRule.expenseAnalyzer,
        target: 3,
      ),
      HomeWalletBadge(
        name: "Ada Pemasukan",
        subtitle: "Kamu sudah mencatat transaksi pemasukan.",
        icon: Icons.savings,
        color: Colors.indigo,
        rule: HomeBadgeRule.incomeRecorder,
        target: 1,
      ),
    ];
  }

  bool isHomeBadgeUnlocked({
    required int streak,
    required int balance,
    required HomeWalletBadge badge,
    required int totalTransaction,
    required int totalCategory,
    required int expenseCategoryCount,
    required int totalIncome,
    required int totalExpense,
  }) {
    switch (badge.rule) {
      case HomeBadgeRule.streak:
        return streak >= badge.target;

      case HomeBadgeRule.firstTransaction:
        return totalTransaction >= badge.target;

      case HomeBadgeRule.activeRecorder:
        return totalTransaction >= badge.target;

      case HomeBadgeRule.categoryCollector:
        return totalCategory >= badge.target;

      case HomeBadgeRule.positiveBalance:
        return balance > 0;

      case HomeBadgeRule.controlledExpense:
        return totalIncome > 0 &&
            totalExpense > 0 &&
            totalIncome >= totalExpense;

      case HomeBadgeRule.expenseAnalyzer:
        return totalExpense > 0 &&
            expenseCategoryCount >= badge.target;

      case HomeBadgeRule.incomeRecorder:
        return totalIncome > 0;
    }
  }

  HomeWalletBadge? getLatestUnlockedBadge() {
    final dashboard = _dashboard;

    if (dashboard == null) {
      return null;
    }

    final totalIncome = getTotalIncome();
    final totalExpense = getTotalExpense();
    final totalTransaction =
        dashboard.monthlyStats.incomeCount + dashboard.monthlyStats.expenseCount;
    final totalCategory = getTotalPerCategory().length;
    final expenseCategoryCount = getExpenseCategoryCount();
    final streak = dashboard.user.streak;
    final balance = dashboard.user.balance.toInt();

    final unlockedBadges = getHomeBadges().where((badge) {
      return isHomeBadgeUnlocked(
        badge: badge,
        totalTransaction: totalTransaction,
        totalCategory: totalCategory,
        expenseCategoryCount: expenseCategoryCount,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        streak: streak,
        balance: balance,
      );
    }).toList();

    if (unlockedBadges.isEmpty) {
      return null;
    }

    return unlockedBadges.last;
  }

  Future<void> editTransaction(Transaction transaction) async {
    final TextEditingController editTitle =
    TextEditingController(text: transaction.title);

    final TextEditingController editAmount =
    TextEditingController(text: transaction.amount.toString());

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Transaksi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editTitle,
                decoration: const InputDecoration(
                  labelText: "Nama transaksi",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: editAmount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Nominal",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                final title = editTitle.text.trim();
                final int newAmount = int.tryParse(editAmount.text.trim()) ?? 0;

                if (title.isEmpty || newAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Nama dan nominal harus valid"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, {
                  "title": title,
                  "amount": newAmount,
                });
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );

    editTitle.dispose();
    editAmount.dispose();

    if (result == null) {
      return;
    }

    final updateResult = await TransactionService.update(
      transaction.id,
      amount: (result["amount"] as int).toDouble(),
      note: result["title"] as String,
    );

    if (!mounted) return;

    if (updateResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Transaksi berhasil diubah"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await loadDashboard();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updateResult.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Hapus Transaksi"),
          content: Text("Hapus transaksi '${transaction.title}'?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                "Hapus",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    final result = await TransactionService.delete(transaction.id);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Transaksi berhasil dihapus"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await loadDashboard();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDashboard) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("MonMon"),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_dashboardErrorMessage != null || _dashboard == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("MonMon"),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Gagal memuat dashboard",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: loadDashboard,
                  child: const Text("Coba Lagi"),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final dashboard = _dashboard!;
    final filteredTransactions = getFilteredTransactions();
    final latestTransactions = filteredTransactions.take(3).toList();
    final categoryData = getTotalPerCategory();
    final latestBadge = getLatestUnlockedBadge();
    final currentBalance = dashboard.user.balance.toInt();
    final currentStreak = dashboard.user.streak;

    final bool isSearching = searchQuery.trim().isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("MonMon"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BalanceCard(
              saldo: currentBalance,
            ),

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

            if (latestBadge != null) ...[
              _LatestBadgeCard(
                badge: latestBadge,
                loginStreak: currentStreak,
                onTap: () {
                  widget.onTabChange(3);
                },
              ),
              const SizedBox(height: 18),
            ] else ...[
              _NoBadgeCard(
                onTap: () {
                  widget.onTabChange(3);
                },
              ),
              const SizedBox(height: 18),
            ],

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
                    onPressed: () {
                      widget.onTabChange(2);
                    },
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
                        color: getCategoryColor(entry.key)
                            .withValues(alpha: 0.12),
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
                  isSearching
                      ? "Hasil Pencarian"
                      : "Transaksi Terbaru",
                  style: const TextStyle(
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

            const SizedBox(height: 10),

            if (dashboardTransactions.isEmpty)
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
                    onTap: () {
                      editTransaction(transaction);
                    },
                    onDelete: () {
                      deleteTransaction(transaction);
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    AppRefreshService.transactionsVersion.removeListener(loadDashboard);
    searchController.dispose();
    super.dispose();
  }
}

class _BalanceCard extends StatelessWidget {
  final int saldo;

  const _BalanceCard({
    required this.saldo,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = saldo >= 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [
            Colors.blue.shade700,
            Colors.blue.shade500,
          ]
              : [
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
            "Saldo Saat Ini",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
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
                isPositive
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isPositive
                    ? "Keuangan masih aman"
                    : "Pengeluaran melebihi pemasukan",
                style: const TextStyle(
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
      constraints: const BoxConstraints(
        minHeight: 105,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
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

    final Color tileColor = isIncome
        ? Colors.green
        : getCategoryColor(transaction.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tileColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: transaction.categoryIcon != null
                ? Text(
              transaction.categoryIcon!,
              style: const TextStyle(fontSize: 20),
            )
                : Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: tileColor,
              size: 22,
            ),
          ),
        ),
        title: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "${transaction.category} • ${DateFormat('dd MMM yyyy').format(transaction.date)}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
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
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
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
          Icon(
            icon,
            size: 42,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
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
class _LatestBadgeCard extends StatelessWidget {
  final HomeWalletBadge badge;
  final int loginStreak;
  final VoidCallback onTap;

  const _LatestBadgeCard({
    required this.badge,
    required this.loginStreak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isStreakBadge = badge.rule == HomeBadgeRule.streak;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: badge.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badge.color.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                badge.icon,
                color: badge.color,
                size: 28,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Badge Terakhir Didapat",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    badge.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: badge.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    isStreakBadge
                        ? "$loginStreak hari streak aktif"
                        : badge.subtitle,
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

            Icon(
              Icons.chevron_right,
              color: badge.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBadgeCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NoBadgeCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.lock_outline,
                color: Colors.grey.shade600,
                size: 28,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Belum Ada Badge",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Mulai catat transaksi untuk membuka badge.",
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

            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}