import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_data.dart';
import '../models/transaction.dart';
import '../utils/formatter.dart';

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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color getTypeColor() {
    return isIncome ? Colors.green : Colors.red;
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
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Nama kategori",
              hintText: "Contoh: Kuliah",
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

                final bool alreadyExists = categories.any(
                      (category) =>
                  category.toLowerCase() ==
                      newCategory.toLowerCase(),
                );

                if (newCategory.isEmpty) {
                  Navigator.pop(context);
                  showMessage("Nama kategori tidak boleh kosong");
                  return;
                }

                if (alreadyExists) {
                  Navigator.pop(context);
                  showMessage("Kategori itu sudah ada");
                  return;
                }

                setState(() {
                  categories.add(newCategory);
                  selectedCategory = newCategory;
                  saveData();
                });

                Navigator.pop(context);
                showMessage("Kategori berhasil ditambahkan");
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

    if (title.isEmpty) {
      showMessage("Nama transaksi tidak boleh kosong");
      return;
    }

    if (amountText.isEmpty) {
      showMessage("Nominal tidak boleh kosong");
      return;
    }

    final int amount = int.tryParse(amountText) ?? 0;

    if (amount <= 0) {
      showMessage("Nominal harus lebih dari 0");
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
    final typeColor = getTypeColor();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Tambah Transaksi"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TypeSelector(
              isIncome: isIncome,
              onChanged: (value) {
                FocusScope.of(context).unfocus();

                setState(() {
                  isIncome = value;
                });
              },
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: typeColor,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              isIncome
                                  ? "Transaksi Pemasukan"
                                  : "Transaksi Pengeluaran",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isIncome
                                  ? "Catat uang yang masuk ke saldo."
                                  : "Catat uang yang keluar dari saldo.",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Contoh: Ngopi",
                      prefixIcon: const Icon(Icons.edit_note),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: "Contoh: 15000",
                      prefixIcon:
                      const Icon(Icons.account_balance_wallet),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),

                  if (amountController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Preview: ${formatRupiah(
                        int.tryParse(
                          amountController.text.trim(),
                        ) ??
                            0,
                      )}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  if (!isIncome) ...[
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    getCategoryIcon(category),
                                    size: 20,
                                    color: Colors.blueGrey,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(category),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: showAddCategoryDialog,
                        icon: const Icon(Icons.add),
                        label: const Text("Tambah Kategori"),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: addTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                isIncome
                    ? "Tambah Pemasukan"
                    : "Tambah Pengeluaran",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final bool isIncome;
  final ValueChanged<bool> onChanged;

  const _TypeSelector({
    required this.isIncome,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              title: "Pengeluaran",
              icon: Icons.arrow_upward,
              isSelected: !isIncome,
              color: Colors.red,
              onTap: () {
                onChanged(false);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TypeButton(
              title: "Pemasukan",
              icon: Icons.arrow_downward,
              isSelected: isIncome,
              color: Colors.green,
              onTap: () {
                onChanged(true);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}