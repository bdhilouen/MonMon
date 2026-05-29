import 'package:flutter/material.dart';
import '../models/category.dart' as cat;
import '../services/transaction_service.dart';
import '../services/category_service.dart';
import '../widgets/app_state_widgets.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isIncome = false;
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  DateTime _selectedDate = DateTime.now();

  List<cat.Category> _incomeCategories = [];
  List<cat.Category> _expenseCategories = [];
  cat.Category? _selectedCategory;

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
      _isLoadingCategories = false;

      // Select first category
      if (_isIncome && _incomeCategories.isNotEmpty) {
        _selectedCategory = _incomeCategories.first;
      } else if (!_isIncome && _expenseCategories.isNotEmpty) {
        _selectedCategory = _expenseCategories.first;
      }
    });
  }

  List<cat.Category> get _currentCategories =>
      _isIncome ? _incomeCategories : _expenseCategories;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final icons = ['🍔', '🚗', '🎮', '🏠', '📚', '💊', '👕', '🎁', '💼', '💰', '📱', '✈️'];
    String selectedIcon = icons.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Tambah Kategori"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: "Nama kategori",
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Pilih Icon:", style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: icons.map((icon) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedIcon == icon
                                ? Colors.blue.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: selectedIcon == icon
                                ? Border.all(color: Colors.blue)
                                : null,
                          ),
                          child: Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
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
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final result = await CategoryService.create(
                      name: name,
                      icon: selectedIcon,
                      color: '#4CAF50',
                      type: _isIncome ? 'income' : 'expense',
                    );

                    if (!mounted) return;
                    Navigator.pop(context);

                    if (result.success && result.category != null) {
                      setState(() {
                        if (_isIncome) {
                          _incomeCategories.add(result.category!);
                        } else {
                          _expenseCategories.add(result.category!);
                        }
                        _selectedCategory = result.category;
                      });
                      showAppSnack(this.context, 'Kategori berhasil ditambahkan');
                    } else {
                      showAppSnack(this.context, result.message, success: false);
                    }
                  },
                  child: const Text("Tambah"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCategoryManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final categories = _currentCategories;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Kelola Kategori',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (categories.where((c) => c.isCustom).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: AppEmptyState(
                          icon: Icons.category_outlined,
                          title: 'Belum ada custom category',
                        ),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: categories
                              .where((category) => category.isCustom)
                              .map(
                                (category) => ListTile(
                                  leading: CircleAvatar(
                                    child: Text(category.icon),
                                  ),
                                  title: Text(category.name),
                                  subtitle: Text(category.type),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          await _showEditCategoryDialog(category);
                                          if (!mounted) return;
                                          Navigator.pop(context);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () async {
                                          await _deleteCategory(category);
                                          if (!mounted) return;
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditCategoryDialog(cat.Category category) async {
    final nameController = TextEditingController(text: category.name);
    final iconController = TextEditingController(text: category.icon);
    final colorController = TextEditingController(text: category.color);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(labelText: 'Icon'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Warna hex'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    final result = await CategoryService.update(
      category.id,
      name: nameController.text.trim(),
      icon: iconController.text.trim(),
      color: colorController.text.trim(),
    );

    if (!mounted) return;
    if (result.success) {
      showAppSnack(context, 'Kategori berhasil diupdate');
      await _loadCategories();
    } else {
      showAppSnack(context, result.message, success: false);
    }
  }

  Future<void> _deleteCategory(cat.Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori ${category.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await CategoryService.delete(category.id);
    if (!mounted) return;
    if (result.success) {
      showAppSnack(context, 'Kategori berhasil dihapus');
      await _loadCategories();
    } else {
      showAppSnack(context, result.message, success: false);
    }
  }

  Future<void> _addTransaction() async {
    final amountText = _amountController.text.trim();
    final note = _noteController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus diisi')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await TransactionService.create(
      type: _isIncome ? 'income' : 'expense',
      amount: amount,
      categoryId: _selectedCategory!.id,
      note: note.isNotEmpty ? note : null,
      date: _selectedDate,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Show achievement notification if any
      if (result.newAchievements != null &&
          result.newAchievements!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🏆 Achievement baru! (${result.newAchievements!.length})'),
            backgroundColor: Colors.amber.shade700,
          ),
        );
      }

      Navigator.pop(context, {
        'changed': true,
        'achievements': result.newAchievements ?? [],
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Tambah Transaksi"),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Pengeluaran"),
                      Switch(
                        value: _isIncome,
                        onChanged: (value) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _isIncome = value;
                            _selectedCategory = _currentCategories.isNotEmpty
                                ? _currentCategories.first
                                : null;
                          });
                        },
                      ),
                      const Text("Pemasukan"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Nominal",
                      prefixText: "Rp ",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Note
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: "Catatan (opsional)",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Date picker
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category dropdown
                  if (_currentCategories.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedCategory?.id,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Kategori",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _currentCategories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text("${category.icon} ${category.name}"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = _currentCategories
                              .firstWhere((c) => c.id == value);
                        });
                      },
                    ),

                  if (_currentCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Belum ada kategori. Tambah kategori baru.",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _showCategoryManager,
                          icon: const Icon(Icons.tune, size: 18),
                          label: const Text("Kelola"),
                        ),
                        TextButton.icon(
                          onPressed: _showAddCategoryDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Tambah Kategori"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Tambah Transaksi",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
