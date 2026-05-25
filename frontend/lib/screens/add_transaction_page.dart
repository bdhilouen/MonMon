import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/transaction.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() =>
      _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController amountController =
  TextEditingController();

  final TextEditingController controller =
  TextEditingController();

  bool isIncome = false;

  String selectedCategory = "Makan";

  void showAddCategoryDialog() {
    final TextEditingController categoryController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tambah Kategori"),
          content: TextField(
            controller: categoryController,
            decoration: const InputDecoration(
              hintText: "Nama kategori",
            ),
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
                final newCategory =
                categoryController.text.trim();

                if (newCategory.isNotEmpty &&
                    !categories.contains(newCategory)) {
                  setState(() {
                    categories.add(newCategory);
                    selectedCategory = newCategory;
                    saveData();
                  });
                }

                Navigator.pop(context);
              },
              child: const Text("Tambah"),
            ),
          ],
        );
      },
    );
  }

  Future<void> addTransaction() async {
    final title = controller.text.trim();
    final amountText = amountController.text.trim();

    if (title.isEmpty || amountText.isEmpty) {
      return;
    }

    final int amount = int.tryParse(amountText) ?? 0;

    if (amount <= 0) {
      return;
    }

    transaksi.add(
      Transaction(
        title: title,
        amount: amount,
        isIncome: isIncome,
        date: DateTime.now(),
        category: isIncome ? "Pemasukan" : selectedCategory,
      ),
    );

    if (isIncome) {
      saldo += amount;
    } else {
      saldo -= amount;
    }

    await saveData();

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    controller.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Tambah Transaksi"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Nama Transaksi",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Nominal",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (!isIncome)
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),

            if (!isIncome)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: showAddCategoryDialog,
                  child: const Text("Tambah Kategori"),
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Pengeluaran"),
                Switch(
                  value: isIncome,
                  onChanged: (value) {
                    FocusScope.of(context).unfocus();

                    setState(() {
                      isIncome = value;
                    });
                  },
                ),
                const Text("Pemasukan"),
              ],
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: addTransaction,
              child: const Text("Tambah Transaksi"),
            ),
          ],
        ),
      ),
    );
  }
}