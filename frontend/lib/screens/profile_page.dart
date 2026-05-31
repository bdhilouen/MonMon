import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/category.dart' as cat_model;
import '../models/achievement.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/achievement_service.dart';
import '../services/app_refresh_service.dart';
import '../utils/category_icons.dart';
import '../utils/formatter.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/responsive_content.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  User? _user;
  List<cat_model.Category> _incomeCategories = [];
  List<cat_model.Category> _expenseCategories = [];
  List<Achievement> _achievements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    AppRefreshService.transactionsVersion.addListener(_onDataChanged);
    AppRefreshService.achievementsVersion.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    _loadData();
  }

  Future<void> _loadData() async {
    final futures = await Future.wait([
      AuthService.getUser(),
      CategoryService.getAll(),
      AchievementService.getAll(),
    ]);

    if (!mounted) return;

    final user = futures[0] as User?;
    final categories =
        futures[1]
            as ({
              List<cat_model.Category> income,
              List<cat_model.Category> expense,
            });
    final achievements = futures[2] as List<Achievement>;

    setState(() {
      _user = user;
      _incomeCategories = categories.income;
      _expenseCategories = categories.expense;
      _achievements = achievements;
      _isLoading = false;
    });
  }

  List<cat_model.Category> get _allCategories => [
    ..._incomeCategories,
    ..._expenseCategories,
  ];

  int get _unlockedCount => _achievements.where((a) => a.isUnlocked).length;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// Shows a bottom sheet GridView for picking a Material icon key.
  Future<String?> showIconPickerSheet(BuildContext context, String currentKey) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Pilih Icon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: kPickableIcons.length,
                itemBuilder: (_, index) {
                  final key = kPickableIcons.keys.elementAt(index);
                  final iconData = kPickableIcons[key]!;
                  final isSelected = key == currentKey;

                  return GestureDetector(
                    onTap: () => Navigator.pop(sheetContext, key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        iconData,
                        color: isSelected ? Colors.blue : Colors.grey.shade700,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showAddCategoryDialog(BuildContext context, StateSetter refreshSheet) {
    final TextEditingController categoryController = TextEditingController();
    String selectedType = 'expense';
    String selectedIconKey = defaultCategoryIconKey('expense');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Tambah Kategori"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: categoryController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Nama kategori",
                      hintText: "Contoh: Kuliah",
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Icon picker row
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          iconDataFor(selectedIconKey),
                          color: Colors.blue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showIconPickerSheet(
                              context,
                              selectedIconKey,
                            );
                            if (picked != null) {
                              setDialogState(() => selectedIconKey = picked);
                            }
                          },
                          icon: const Icon(Icons.grid_view_rounded, size: 18),
                          label: const Text('Pilih Icon'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Type selector
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Pengeluaran"),
                          selected: selectedType == 'expense',
                          onSelected: (_) => setDialogState(() {
                            selectedType = 'expense';
                            if (selectedIconKey == 'payments') {
                              selectedIconKey = 'sell';
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Pemasukan"),
                          selected: selectedType == 'income',
                          onSelected: (_) => setDialogState(() {
                            selectedType = 'income';
                            if (selectedIconKey == 'sell') {
                              selectedIconKey = 'payments';
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newCategory = categoryController.text.trim();

                    if (newCategory.isEmpty) {
                      showMessage("Nama kategori tidak boleh kosong");
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final result = await CategoryService.create(
                      name: newCategory,
                      icon: selectedIconKey,
                      color: '#607D8B',
                      type: selectedType,
                    );

                    if (result.success) {
                      await _loadData();
                      refreshSheet(() {});
                      showMessage("Kategori berhasil ditambahkan");
                    } else {
                      showMessage(result.message);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Tambah"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showEditCategoryDialog(
    BuildContext context,
    StateSetter refreshSheet,
    cat_model.Category category,
  ) {
    if (!category.isCustom) {
      showMessage("Kategori bawaan tidak bisa diedit");
      return;
    }

    final TextEditingController categoryController = TextEditingController(
      text: category.name,
    );
    String selectedIconKey = category.icon;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Edit Kategori"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: categoryController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Nama kategori baru",
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Icon picker row
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          iconDataFor(selectedIconKey),
                          color: Colors.blue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showIconPickerSheet(
                              context,
                              selectedIconKey,
                            );
                            if (picked != null) {
                              setDialogState(() => selectedIconKey = picked);
                            }
                          },
                          icon: const Icon(Icons.grid_view_rounded, size: 18),
                          label: const Text('Ganti Icon'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newName = categoryController.text.trim();

                    if (newName.isEmpty) {
                      showMessage("Nama kategori tidak boleh kosong");
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final result = await CategoryService.update(
                      category.id,
                      name: newName,
                      icon: selectedIconKey,
                    );

                    if (result.success) {
                      await _loadData();
                      refreshSheet(() {});
                      showMessage("Kategori berhasil diubah");
                    } else {
                      showMessage(result.message);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteCategory(
    BuildContext context,
    StateSetter refreshSheet,
    cat_model.Category category,
  ) async {
    if (!category.isCustom) {
      showMessage("Kategori bawaan tidak bisa dihapus");
      return;
    }

    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: "Hapus Kategori?",
      message:
          "Kategori \"${category.name}\" akan dihapus. Pastikan kategori ini tidak sedang dipakai transaksi.",
    );
    if (!confirmed || !mounted) return;

    final result = await CategoryService.delete(category.id);

    if (result.success) {
      await _loadData();
      refreshSheet(() {});
      showMessage("Kategori berhasil dihapus");
    } else {
      showMessage(result.message);
    }
  }

  void showManageCategories(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, refreshSheet) {
            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.82,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Kelola Kategori",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Edit dan hapus hanya berlaku untuk kategori custom.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      showAddCategoryDialog(context, refreshSheet);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Tambah Kategori"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allCategories.length,
                      itemBuilder: (context, index) {
                        final category = _allCategories[index];
                        final isDefault = !category.isCustom;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isDefault
                                      ? Colors.blue.withValues(alpha: 0.12)
                                      : Colors.purple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  categoryIconFor(
                                    icon: category.icon,
                                    name: category.name,
                                    type: category.type,
                                  ),
                                  color: isDefault
                                      ? Colors.blue
                                      : Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isDefault
                                          ? "Kategori bawaan (${category.type})"
                                          : "Kategori custom (${category.type})",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: isDefault
                                    ? null
                                    : () {
                                        showEditCategoryDialog(
                                          context,
                                          refreshSheet,
                                          category,
                                        );
                                      },
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed: isDefault
                                    ? null
                                    : () {
                                        deleteCategory(
                                          context,
                                          refreshSheet,
                                          category,
                                        );
                                      },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showAllAchievements(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Semua Achievements",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "$_unlockedCount dari ${_achievements.length} achievement terbuka",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: _achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = _achievements[index];
                    final isUnlocked = achievement.isUnlocked;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? Colors.amber.withValues(alpha: 0.08)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isUnlocked
                              ? Colors.amber.withValues(alpha: 0.3)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isUnlocked
                                  ? Icons.emoji_events
                                  : Icons.lock_outline,
                              color: isUnlocked
                                  ? Colors.amber.shade700
                                  : Colors.grey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  achievement.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isUnlocked
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  achievement.description,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUnlocked)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 22),
              SizedBox(width: 10),
              Text(
                'Konfirmasi Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ya, Keluar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profil"), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: ResponsiveContent(
            maxWidth: 920,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 46,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _user?.name ?? 'Pengguna MonMon',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        title: "Level",
                        value: "${_user?.level ?? 1}",
                        icon: Icons.star,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoCard(
                        title: "Points",
                        value: "${_user?.points ?? 0}",
                        icon: Icons.emoji_events,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        title: "Streak",
                        value: "${_user?.streak ?? 0} hari",
                        icon: Icons.local_fire_department,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Achievements section
                InkWell(
                  onTap: () => showAllAchievements(context),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.emoji_events,
                            color: Colors.amber.shade700,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Achievements",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$_unlockedCount dari ${_achievements.length} terbuka",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Categories section
                InkWell(
                  onTap: () => showManageCategories(context),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.category,
                            color: Colors.blue,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Kelola Kategori",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${_allCategories.length} kategori",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // App Info menu
                InkWell(
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'MonMon',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.account_balance_wallet, size: 48, color: Colors.blue),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.green,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Info Aplikasi",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tentang aplikasi MonMon",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Logout button
                OutlinedButton.icon(
                  onPressed: _showLogoutConfirmation,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
    AppRefreshService.transactionsVersion.removeListener(_onDataChanged);
    AppRefreshService.achievementsVersion.removeListener(_onDataChanged);
    super.dispose();
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
