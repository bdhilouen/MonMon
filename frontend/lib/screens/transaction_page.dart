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

  int getTotalIncome() {
    int total = 0;

    for (var t in transaksi) {
      if (t.isIncome) {
        total += t.amount;
      }
    }

    return total;
  }

  int getTotalExpense() {
    int total = 0;

    for (var t in transaksi) {
      if (!t.isIncome) {
        total += t.amount;
      }
    }

    return total;
  }

  void editTransaction(Transaction transaction ) {
    final editTitle = TextEditingController(text: transaction.title);
    final editAmount =
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
                final newAmount = int.tryParse(editAmount.text) ?? 0;

                if (editTitle.text.trim().isEmpty || newAmount <= 0) {
                  return;
                }

                setState(() {
                  if (transaction.isIncome) {
                    saldo -= transaction.amount;
                  } else {
                    saldo += transaction.amount;
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
        saldo -= transaction.amount;
      } else {
        saldo += transaction.amount;
      }

      transaksi.remove(transaction);
      saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaksi"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: transaksi.isEmpty
            ? Center(
          child: Text(
            "Belum ada transaksi 😴",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Pemasukan",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatRupiah(getTotalIncome()),
                          style: const TextStyle(
                            color: Colors.white,
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Pengeluaran",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatRupiah(getTotalExpense()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "Daftar Transaksi",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: transaksi.length,
                itemBuilder: (context, index) {
                  final transaction = transaksi[index];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        getCategoryColor(transaction.category),
                        radius: 8,
                      ),
                      title: Text(
                        transaction.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${transaction.category}\n${DateFormat('dd MMM yyyy').format(transaction.date)}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${transaction.isIncome ? '+' : '-'} ${formatRupiah(transaction.amount)}",
                            style: TextStyle(
                              color: transaction.isIncome
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              deleteTransaction(transaction);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        editTransaction(transaction);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}