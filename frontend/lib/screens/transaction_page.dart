import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../utils/formatter.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController searchController = TextEditingController();

  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await TransactionService.getAll();

      if (!mounted) return;

      setState(() {
        _transactions = result;
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

  Color parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.blueGrey;
    }

    final cleanHex = hexColor.replaceAll('#', '');

    if (cleanHex.length != 6) {
      return Colors.blueGrey;
    }

    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  Color getTransactionColor(Transaction transaction) {
    if (transaction.isIncome) {
      return Colors.green;
    }

    return parseColor(transaction.categoryColor);
  }

  IconData getFallbackIcon(Transaction transaction) {
    if (transaction.isIncome) {
      return Icons.arrow_downward;
    }

    return Icons.category;
  }

  int getTotalIncome() {
    int total = 0;

    for (var transaction in _transactions) {
      if (transaction.isIncome) {
        total += transaction.amount;
      }
    }

    return total;
  }

  int getTotalExpense() {
    int total = 0;

    for (var transaction in _transactions) {
      if (!transaction.isIncome) {
        total += transaction.amount;
      }
    }

    return total;
  }

  List<Transaction> getFilteredTransactions() {
    final sortedTransactions = [..._transactions]
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
                final int newAmount =
                    int.tryParse(editAmount.text.trim()) ?? 0;

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

    final String newTitle = result["title"] as String;
    final int newAmount = result["amount"] as int;

    final updateResult = await TransactionService.update(
      transaction.id,
      amount: newAmount.toDouble(),
      note: newTitle,
    );

    if (!mounted) return;

    if (updateResult.success) {
      showMessage("Transaksi berhasil diubah");
      await loadTransactions();
    } else {
      showMessage(updateResult.message);
    }
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Hapus Transaksi"),
          content: Text(
            "Hapus transaksi '${transaction.title}'?",
          ),
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
      showMessage("Transaksi berhasil dihapus");
      await loadTransactions();
    } else {
      showMessage(result.message);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = getFilteredTransactions();
    final bool isSearching = searchQuery.trim().isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Transaksi"),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: loadTransactions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
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

            const SizedBox(height: 18),

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
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : _errorMessage != null
                  ? _ErrorState(
                message: "Gagal memuat transaksi",
                onRetry: loadTransactions,
              )
                  : _transactions.isEmpty
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
                subtitle:
                "Coba cari nama atau kategori lain.",
              )
                  : RefreshIndicator(
                onRefresh: loadTransactions,
                child: ListView.builder(
                  padding:
                  const EdgeInsets.only(bottom: 100),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction =
                    filteredTransactions[index];

                    return _TransactionItem(
                      transaction: transaction,
                      color:
                      getTransactionColor(transaction),
                      fallbackIcon:
                      getFallbackIcon(transaction),
                      onTap: () {
                        editTransaction(transaction);
                      },
                      onDelete: () {
                        deleteTransaction(transaction);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final Color color;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransactionItem({
    required this.transaction,
    required this.color,
    required this.fallbackIcon,
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
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: transaction.categoryIcon != null
                ? Text(
              transaction.categoryIcon!,
              style: const TextStyle(fontSize: 20),
            )
                : Icon(
              isIncome ? Icons.arrow_downward : fallbackIcon,
              color: color,
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
        trailing: SizedBox(
          width: 128,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  "${isIncome ? '+' : '-'} ${formatRupiah(transaction.amount)}",
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
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 42,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onRetry,
              child: const Text("Coba Lagi"),
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
      ),
    );
  }
}