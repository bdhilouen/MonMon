import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category.dart' as category_model;
import '../services/category_service.dart';
import '../services/transaction_service.dart';
import '../utils/formatter.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController controller = TextEditingController();

  bool isIncome = false;
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  List<category_model.Category> _incomeCategories = [];
  List<category_model.Category> _expenseCategories = [];
  category_model.Category? selectedCategory;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  List<category_model.Category> get activeCategories {
    return isIncome ? _incomeCategories : _expenseCategories;
  }

  Future<void> loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final result = await CategoryService.getAll();

      if (!mounted) return;

      setState(() {
        _incomeCategories = result.income;
        _expenseCategories = result.expense;
        _isLoadingCategories = false;
      });

      syncSelectedCategory();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingCategories = false);
      showMessage("Gagal memuat kategori");
    }
  }

  void syncSelectedCategory() {
    final list = activeCategories;

    setState(() {
      if (list.isEmpty) {
        selectedCategory = null;
        return;
      }

      final stillExists = selectedCategory != null &&
          list.any((category) => category.id == selectedCategory!.id);

      if (!stillExists) {
        selectedCategory = list.first;
      }
    });
  }

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

  Future<void> showAddCategoryDialog() async {
    final TextEditingController categoryController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isIncome ? "Tambah Kategori Pemasukan" : "Tambah Kategori Pengeluaran",
          ),
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
                Navigator.pop(dialogContext);
              },
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                final newCategory = categoryController.text.trim();

                if (newCategory.isEmpty) {
                  showMessage("Nama kategori tidak boleh kosong");
                  return;
                }

                final alreadyExists = activeCategories.any(
                      (category) =>
                  category.name.toLowerCase() == newCategory.toLowerCase(),
                );

                if (alreadyExists) {
                  showMessage("Kategori itu sudah ada");
                  return;
                }

                final result = await CategoryService.create(
                  name: newCategory,
                  icon: isIncome ? "💰" : "📦",
                  color: isIncome ? "#4CAF50" : "#9B59B6",
                  type: isIncome ? "income" : "expense",
                );

                if (!mounted) return;

                if (result.success && result.category != null) {
                  setState(() {
                    if (isIncome) {
                      _incomeCategories.add(result.category!);
                    } else {
                      _expenseCategories.add(result.category!);
                    }

                    selectedCategory = result.category!;
                  });

                  Navigator.pop(dialogContext);
                  showMessage("Kategori berhasil ditambahkan");
                } else {
                  showMessage(result.message);
                }
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

    if (selectedCategory == null) {
      showMessage("Kategori belum tersedia");
      return;
    }

    setState(() => _isSaving = true);

    final result = await TransactionService.create(
      type: isIncome ? "income" : "expense",
      amount: amount.toDouble(),
      categoryId: selectedCategory!.id,
      note: title,
      date: DateTime.now(),
      currency: "IDR",
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result.success) {
      showMessage("Transaksi berhasil ditambahkan");
      Navigator.pop(context, true);
    } else {
      showMessage(result.message);
    }
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

                syncSelectedCategory();
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
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: typeColor,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                      prefixIcon: const Icon(Icons.account_balance_wallet),
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
                        int.tryParse(amountController.text.trim()) ?? 0,
                      )}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  _isLoadingCategories
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                      : activeCategories.isEmpty
                      ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Belum ada kategori ${isIncome ? 'pemasukan' : 'pengeluaran'}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  )
                      : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<category_model.Category>(
                        value: selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: activeCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Text(
                                  category.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _isSaving ? null : showAddCategoryDialog,
                      icon: const Icon(Icons.add),
                      label: Text(
                        isIncome
                            ? "Tambah Kategori Pemasukan"
                            : "Tambah Kategori Pengeluaran",
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _isSaving ? null : addTransaction,
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
              child: _isSaving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                isIncome ? "Tambah Pemasukan" : "Tambah Pengeluaran",
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