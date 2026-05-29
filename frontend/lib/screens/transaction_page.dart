import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_data.dart';
import '../models/transaction.dart';
import '../utils/formatter.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";

  Color getCategoryColor(String category) {
    switch (category) {
      case "Makan":
        return Colors.orange;
      case "Transport":
        return Colors.blue;
      case "Hiburan":
        return Colors.purple;
      case "Lainnya":
        return Colors.grey;
      case "Pemasukan":
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
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

  int getTotalIncome() {
    int total = 0;

    for (var t in transaksi) {
      if (t.isIncome) {
        total += t.amount.toInt();
      }
    }

    return total;
  }

  int getTotalExpense() {
    int total = 0;

    for (var t in transaksi) {
      if (!t.isIncome) {
        total += t.amount.toInt();
      }
    }

    return total;
  }

  List<Transaction> getFilteredTransactions() {
    if (searchQuery.trim().isEmpty) {
      return transaksi.reversed.toList();
    }

    return transaksi
        .where((t) {
      return t.title.toLowerCase().contains(
        searchQuery.toLowerCase(),
      ) ||
          t.category.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
    })
        .toList()
        .reversed
        .toList();
  }

  void editTransaction(Transaction transaction) {
    final TextEditingController editTitle =
    TextEditingController(text: transaction.title);

    final TextEditingController editAmount =
    TextEditingController(text: transaction.amount.toString());

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
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),

            TextButton(
              onPressed: () {
                final int newAmount =
                    int.tryParse(editAmount.text.trim()) ?? 0;

                if (editTitle.text.trim().isEmpty || newAmount <= 0) {
                  return;
                }

                setState(() {
                  if (transaction.isIncome) {
                    saldo -= transaction.amount.toInt();
                  } else {
                    saldo += transaction.amount.toInt();
                  }

                  transaction.title = editTitle.text.trim();
                  transaction.amount = newAmount;

                  if (transaction.isIncome) {
                    saldo += newAmount;
                  } else {
                    saldo -= newAmount;
                  }

                  saveData();
                });

                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void deleteTransaction(Transaction transaction) {
    setState(() {
      if (transaction.isIncome) {
        saldo -= transaction.amount.toInt();
      } else {
        saldo += transaction.amount.toInt();
      }

      transaksi.remove(transaction);
      saveData();
    });
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
              child: transaksi.isEmpty
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
                  final transaction =
                  filteredTransactions[index];

                  return _TransactionItem(
                    transaction: transaction,
                    color: getCategoryColor(
                      transaction.category,
                    ),
                    icon: getCategoryIcon(
                      transaction.category,
                    ),
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