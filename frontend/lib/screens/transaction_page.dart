import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/app_refresh_service.dart';
import '../utils/category_icons.dart';
import '../utils/formatter.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/responsive_content.dart';
import 'home_page.dart' show getCategoryColor, getCategoryColorFromHex;

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";
  String _selectedFilter = 'all'; // 'all', 'income', 'expense'
  bool _isLoading = true;
  List<Transaction> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    AppRefreshService.transactionsVersion.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await TransactionService.getAll();
    if (!mounted) return;

    setState(() {
      _allTransactions = transactions;
      _isLoading = false;
    });
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

  // Seluruh histori (sepanjang waktu)
  int getTotalIncome() {
    int total = 0;
    for (var t in _allTransactions) {
      if (t.isIncome) total += t.amount.toInt();
    }
    return total;
  }

  int getTotalExpense() {
    int total = 0;
    for (var t in _allTransactions) {
      if (!t.isIncome) total += t.amount.toInt();
    }
    return total;
  }

  List<Transaction> getFilteredTransactions() {
    List<Transaction> result;

    if (searchQuery.trim().isEmpty) {
      result = List.of(_allTransactions);
    } else {
      result = _allTransactions.where((t) {
        return t.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            t.category.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by type
    if (_selectedFilter == 'income') {
      result = result.where((t) => t.isIncome).toList();
    } else if (_selectedFilter == 'expense') {
      result = result.where((t) => !t.isIncome).toList();
    }

    // Urutkan dari transaksi terbaru ke terlama (descending by date).
    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }

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
                final int newAmount = int.tryParse(editAmount.text.trim()) ?? 0;
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
    final bool isSearching = searchQuery.trim().isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("Transaksi"), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: ResponsiveContent(
          maxWidth: 920,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: "Pemasukan",
                        value: formatRupiah(getTotalIncome()),
                        subtitle: "Sepanjang waktu",
                        icon: Icons.arrow_downward,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        title: "Pengeluaran",
                        value: formatRupiah(getTotalExpense()),
                        subtitle: "Sepanjang waktu",
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Cari transaksi atau kategori...",
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

                const SizedBox(height: 14),

                // Filter chips
                _FilterChips(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSearching ? "Hasil Pencarian" : "Daftar Transaksi",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${filteredTransactions.length} item",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: _allTransactions.isEmpty
                      ? const _EmptyState(
                          icon: Icons.receipt_long,
                          title: "Belum ada transaksi",
                          subtitle:
                              "Tambahkan transaksi pertama lewat tombol +.",
                        )
                      : filteredTransactions.isEmpty
                      ? const _EmptyState(
                          icon: Icons.search_off,
                          title: "Transaksi tidak ditemukan",
                          subtitle: "Coba cari nama atau kategori lain.",
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];

                            return _TransactionItem(
                              transaction: transaction,
                              color: transaction.categoryColor != null
                                  ? getCategoryColorFromHex(
                                      transaction.categoryColor,
                                    )
                                  : getCategoryColor(transaction.category),
                              icon: categoryIconFor(
                                icon: transaction.categoryIcon,
                                name: transaction.category,
                                isIncome: transaction.isIncome,
                              ),
                              onTap: () => editTransaction(transaction),
                              onDelete: () => deleteTransaction(transaction),
                            );
                          },
                        ),
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

// ─── Filter Chips ───────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip('all', 'Semua', Colors.blue),
        const SizedBox(width: 8),
        _buildChip('income', '↓ Pemasukan', Colors.green),
        const SizedBox(width: 8),
        _buildChip('expense', '↑ Pengeluaran', Colors.red),
      ],
    );
  }

  Widget _buildChip(String value, String label, Color color) {
    final bool isSelected = selectedFilter == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => onFilterChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? color : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Summary Card ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              "($subtitle)",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Transaction Item ───────────────────────────────────────────────────────

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransactionItem({
    required this.transaction,
    required this.color,
    required this.icon,
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
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : icon,
            color: color,
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
        trailing: SizedBox(
          width: 128,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  "${isIncome ? '+' : '-'} ${formatRupiah(transaction.amount.toInt())}",
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────

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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
