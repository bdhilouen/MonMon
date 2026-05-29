import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_data.dart';
import '../models/transaction.dart';
import '../utils/formatter.dart';

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

  Map<String, int> getTotalPerCategory() {
    Map<String, int> result = {};

    for (var t in transaksi) {
      if (!t.isIncome) {
        result[t.category] =
            (result[t.category] ?? 0) + t.amount.toInt();
      }
    }

    return result;
  }

  List<Transaction> getFilteredTransactions() {
    if (searchQuery.trim().isEmpty) {
      return transaksi;
    }

    return transaksi.where((t) {
      return t.title.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
    }).toList();
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
                    int.tryParse(editAmount.text) ?? 0;

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
    final latestTransactions = filteredTransactions.reversed.take(3).toList();
    final categoryData = getTotalPerCategory();

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
              saldo: saldo,
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

            const SizedBox(height: 18),

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

            if (transaksi.isEmpty)
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
            color: getCategoryColor(transaction.category)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isIncome
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: getCategoryColor(transaction.category),
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