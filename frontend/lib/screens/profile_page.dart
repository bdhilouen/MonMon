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

  void showAddCategoryDialog(BuildContext context, StateSetter refreshSheet) {
    final TextEditingController categoryController = TextEditingController();
    String selectedType = 'expense';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Pengeluaran"),
                          selected: selectedType == 'expense',
                          onSelected: (_) =>
                              setDialogState(() => selectedType = 'expense'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Pemasukan"),
                          selected: selectedType == 'income',
                          onSelected: (_) =>
                              setDialogState(() => selectedType = 'income'),
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
                TextButton(
                  onPressed: () async {
                    final newCategory = categoryController.text.trim();

                    if (newCategory.isEmpty) {
                      showMessage("Nama kategori tidak boleh kosong");
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final result = await CategoryService.create(
                      name: newCategory,
                      icon: defaultCategoryIconKey(selectedType),
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

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Kategori"),
          content: TextField(
            controller: categoryController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: "Nama kategori baru"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal"),
            ),
            TextButton(
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
                );

                if (result.success) {
                  await _loadData();
                  refreshSheet(() {});
                  showMessage("Kategori berhasil diubah");
                } else {
                  showMessage(result.message);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
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
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
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
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          (_user?.name ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _user?.name ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _UserStat(
                            label: "Saldo",
                            value: formatRupiah(_user?.balance.toInt() ?? 0),
                          ),
                          _UserStat(
                            label: "Level",
                            value: "${_user?.level ?? 1}",
                          ),
                          _UserStat(
                            label: "Streak",
                            value: "${_user?.streak ?? 0} hari",
                          ),
                          _UserStat(
                            label: "Poin",
                            value: "${_user?.points ?? 0}",
                          ),
                        ],
                      ),
                    ],
                  ),
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

                const SizedBox(height: 30),

                // Logout button
                OutlinedButton.icon(
                  onPressed: _logout,
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

class _UserStat extends StatelessWidget {
  final String label;
  final String value;

  const _UserStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
