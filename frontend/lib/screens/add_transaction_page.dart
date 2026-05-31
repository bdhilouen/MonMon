import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category.dart';
import '../services/category_service.dart';
import '../services/transaction_service.dart';
import '../services/app_refresh_service.dart';
import '../utils/category_icons.dart';
import '../utils/formatter.dart';
import '../models/achievement.dart';
import '../widgets/achievement_unlocked_dialog.dart';
import '../widgets/responsive_content.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController controller = TextEditingController();

  bool isIncome = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await CategoryService.getAll();
    if (!mounted) return;

    setState(() {
      _incomeCategories = result.income;
      _expenseCategories = result.expense;
      _isLoading = false;

      // Select first category by default
      final list = isIncome ? _incomeCategories : _expenseCategories;
      if (list.isNotEmpty) {
        _selectedCategory = list.first;
      }
    });
  }

  List<Category> get _currentCategories =>
      isIncome ? _incomeCategories : _expenseCategories;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Color getTypeColor() {
    return isIncome ? Colors.green : Colors.red;
  }

  IconData getCategoryIcon(String iconStr) {
    // Map emoji/string icons to material icons
    switch (iconStr) {
      case '🍔':
      case 'restaurant':
        return Icons.restaurant;
      case '🚗':
      case 'directions_bus':
        return Icons.directions_bus;
      case '🎮':
      case 'sports_esports':
        return Icons.sports_esports;
      case '💰':
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case '📦':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  void showAddCategoryDialog() {
    final TextEditingController categoryController = TextEditingController();

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
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                final newCategoryName = categoryController.text.trim();

                if (newCategoryName.isEmpty) {
                  Navigator.pop(context);
                  showMessage("Nama kategori tidak boleh kosong");
                  return;
                }

                // Check if already exists
                final alreadyExists = _currentCategories.any(
                  (cat) =>
                      cat.name.toLowerCase() == newCategoryName.toLowerCase(),
                );

                if (alreadyExists) {
                  Navigator.pop(context);
                  showMessage("Kategori itu sudah ada");
                  return;
                }

                Navigator.pop(context);

                final result = await CategoryService.create(
                  name: newCategoryName,
                  icon: defaultCategoryIconKey(isIncome ? 'income' : 'expense'),
                  color: '#607D8B',
                  type: isIncome ? 'income' : 'expense',
                );

                if (result.success && result.category != null) {
                  await _loadCategories();
                  if (mounted) {
                    setState(() {
                      _selectedCategory = result.category;
                    });
                    showMessage("Kategori berhasil ditambahkan");
                  }
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

    if (_selectedCategory == null) {
      showMessage("Pilih kategori terlebih dahulu");
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await TransactionService.create(
      type: isIncome ? 'income' : 'expense',
      amount: amount.toDouble(),
      categoryId: _selectedCategory!.id,
      note: title,
      date: DateTime.now(),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.success) {
      AppRefreshService.notifyAllChanged();

      // Check for new achievements
      if (result.newAchievements != null &&
          result.newAchievements!.isNotEmpty) {
        for (final achievementData in result.newAchievements!) {
          if (mounted && achievementData is Map<String, dynamic>) {
            final achievement = Achievement.fromJson(achievementData);
            showAchievementUnlockedDialog(context, achievement);
          }
        }
      }

      Navigator.pop(context);
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final typeColor = getTypeColor();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("Tambah Transaksi"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: ResponsiveContent(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TypeSelector(
                isIncome: isIncome,
                onChanged: (value) {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    isIncome = value;
                    // Reset selected category for new type
                    final list = isIncome
                        ? _incomeCategories
                        : _expenseCategories;
                    _selectedCategory = list.isNotEmpty ? list.first : null;
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                        "Preview: ${formatRupiah(int.tryParse(amountController.text.trim()) ?? 0)}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Category dropdown (for both income and expense)
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
                          value: _selectedCategory?.id,
                          isExpanded: true,
                          hint: const Text("Pilih kategori"),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: _currentCategories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Row(
                                children: [
                                  Icon(
                                    categoryIconFor(
                                      icon: cat.icon,
                                      name: cat.name,
                                      type: cat.type,
                                    ),
                                    size: 20,
                                    color: Colors.blueGrey,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(cat.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = _currentCategories.firstWhere(
                                (cat) => cat.id == value,
                              );
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
                ),
              ),

              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: _isSubmitting ? null : addTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSubmitting
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final bool isIncome;
  final ValueChanged<bool> onChanged;

  const _TypeSelector({required this.isIncome, required this.onChanged});

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
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TypeButton(
              title: "Pemasukan",
              icon: Icons.arrow_downward,
              isSelected: isIncome,
              color: Colors.green,
              onTap: () => onChanged(true),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : color),
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
