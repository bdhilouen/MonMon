import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../utils/formatter.dart';

enum BadgeRule {
  streak,
  firstTransaction,
  activeRecorder,
  categoryCollector,
  positiveBalance,
  controlledExpense,
  expenseAnalyzer,
  incomeRecorder,
}

class WalletBadge {
  final String name;
  final String subtitle;
  final String lockedText;
  final IconData icon;
  final Color color;
  final BadgeRule rule;
  final int target;

  const WalletBadge({
    required this.name,
    required this.subtitle,
    required this.lockedText,
    required this.icon,
    required this.color,
    required this.rule,
    required this.target,
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const List<String> defaultCategories = [
    "Makan",
    "Transport",
    "Hiburan",
    "Lainnya",
  ];

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

  int getExpenseCategoryCount() {
    final Set<String> expenseCategories = {};

    for (var t in transaksi) {
      if (!t.isIncome) {
        expenseCategories.add(t.category);
      }
    }

    return expenseCategories.length;
  }

  bool isDefaultCategory(String category) {
    return defaultCategories.any(
          (item) => item.toLowerCase() == category.toLowerCase(),
    );
  }

  bool isCategoryUsed(String category) {
    return transaksi.any(
          (transaction) =>
      !transaction.isIncome &&
          transaction.category.toLowerCase() == category.toLowerCase(),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showAddCategoryDialog(
      BuildContext context,
      StateSetter refreshSheet,
      ) {
    final TextEditingController categoryController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
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

                final alreadyExists = categories.any(
                      (category) =>
                  category.toLowerCase() ==
                      newCategory.toLowerCase(),
                );

                if (alreadyExists) {
                  showMessage("Kategori sudah ada");
                  return;
                }

                setState(() {
                  categories.add(newCategory);
                });

                refreshSheet(() {});

                await saveData();

                if (!mounted) return;

                Navigator.pop(dialogContext);
                showMessage("Kategori berhasil ditambahkan");
              },
              child: const Text("Tambah"),
            ),
          ],
        );
      },
    );
  }

  void showEditCategoryDialog(
      BuildContext context,
      StateSetter refreshSheet,
      String oldCategory,
      ) {
    if (isDefaultCategory(oldCategory)) {
      showMessage("Kategori bawaan tidak bisa diedit");
      return;
    }

    final TextEditingController categoryController =
    TextEditingController(text: oldCategory);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Kategori"),
          content: TextField(
            controller: categoryController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Nama kategori baru",
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

                final alreadyExists = categories.any(
                      (category) =>
                  category.toLowerCase() ==
                      newCategory.toLowerCase() &&
                      category.toLowerCase() !=
                          oldCategory.toLowerCase(),
                );

                if (alreadyExists) {
                  showMessage("Kategori sudah ada");
                  return;
                }

                setState(() {
                  final index = categories.indexOf(oldCategory);

                  if (index != -1) {
                    categories[index] = newCategory;
                  }

                  for (var transaction in transaksi) {
                    if (!transaction.isIncome &&
                        transaction.category == oldCategory) {
                      transaction.category = newCategory;
                    }
                  }
                });

                refreshSheet(() {});

                await saveData();

                if (!mounted) return;

                Navigator.pop(dialogContext);
                showMessage("Kategori berhasil diubah");
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
      String category,
      ) async {
    if (isDefaultCategory(category)) {
      showMessage("Kategori bawaan tidak bisa dihapus");
      return;
    }

    if (isCategoryUsed(category)) {
      showMessage("Kategori masih dipakai transaksi");
      return;
    }

    setState(() {
      categories.remove(category);
    });

    refreshSheet(() {});

    await saveData();

    if (!mounted) return;

    showMessage("Kategori berhasil dihapus");
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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Edit dan hapus hanya berlaku untuk kategori custom.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 14),

                  ElevatedButton.icon(
                    onPressed: () {
                      showAddCategoryDialog(
                        context,
                        refreshSheet,
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Tambah Kategori"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isDefault = isDefaultCategory(category);
                        final isUsed = isCategoryUsed(category);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
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
                                  isDefault
                                      ? Icons.bookmark
                                      : Icons.category,
                                  color: isDefault
                                      ? Colors.blue
                                      : Colors.purple,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isDefault
                                          ? "Kategori bawaan"
                                          : isUsed
                                          ? "Sedang dipakai transaksi"
                                          : "Kategori custom",
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

  List<WalletBadge> getWalletBadges() {
    return const [
      WalletBadge(
        name: "Dompet Defender",
        subtitle: "Login selama 7 hari berturut-turut.",
        lockedText: "Butuh streak 7 hari",
        icon: Icons.shield,
        color: Color(0xFF35B7E8),
        rule: BadgeRule.streak,
        target: 7,
      ),
      WalletBadge(
        name: "Dompet Guardian",
        subtitle: "Login selama 14 hari berturut-turut.",
        lockedText: "Butuh streak 14 hari",
        icon: Icons.verified_user,
        color: Color(0xFF2ECC71),
        rule: BadgeRule.streak,
        target: 14,
      ),
      WalletBadge(
        name: "Dompet Sentinel",
        subtitle: "Login selama 30 hari berturut-turut.",
        lockedText: "Butuh streak 30 hari",
        icon: Icons.visibility,
        color: Color(0xFFF1C40F),
        rule: BadgeRule.streak,
        target: 30,
      ),
      WalletBadge(
        name: "Dompet Vanguard",
        subtitle: "Login selama 60 hari berturut-turut.",
        lockedText: "Butuh streak 60 hari",
        icon: Icons.lock,
        color: Color(0xFFE67E22),
        rule: BadgeRule.streak,
        target: 60,
      ),
      WalletBadge(
        name: "Dompet Commander",
        subtitle: "Login selama 90 hari berturut-turut.",
        lockedText: "Butuh streak 90 hari",
        icon: Icons.military_tech,
        color: Color(0xFF9B59B6),
        rule: BadgeRule.streak,
        target: 90,
      ),
      WalletBadge(
        name: "Dompet Strategist",
        subtitle: "Login selama 120 hari berturut-turut.",
        lockedText: "Butuh streak 120 hari",
        icon: Icons.emoji_events,
        color: Color(0xFF34495E),
        rule: BadgeRule.streak,
        target: 120,
      ),
      WalletBadge(
        name: "Dompet Sovereign",
        subtitle: "Login selama 365 hari berturut-turut.",
        lockedText: "Butuh streak 365 hari",
        icon: Icons.workspace_premium,
        color: Color(0xFFD4AF37),
        rule: BadgeRule.streak,
        target: 365,
      ),
      WalletBadge(
        name: "Transaksi Pertama",
        subtitle: "Kamu sudah mencatat transaksi pertama.",
        lockedText: "Catat minimal 1 transaksi",
        icon: Icons.flag,
        color: Colors.blue,
        rule: BadgeRule.firstTransaction,
        target: 1,
      ),
      WalletBadge(
        name: "Pencatat Aktif",
        subtitle: "Kamu sudah mencatat minimal 10 transaksi.",
        lockedText: "Catat minimal 10 transaksi",
        icon: Icons.edit_note,
        color: Colors.orange,
        rule: BadgeRule.activeRecorder,
        target: 10,
      ),
      WalletBadge(
        name: "Kolektor Kategori",
        subtitle: "Kamu punya minimal 5 kategori transaksi.",
        lockedText: "Miliki minimal 5 kategori",
        icon: Icons.category,
        color: Colors.purple,
        rule: BadgeRule.categoryCollector,
        target: 5,
      ),
      WalletBadge(
        name: "Saldo Aman",
        subtitle: "Saldo kamu masih bernilai positif.",
        lockedText: "Jaga saldo tetap positif",
        icon: Icons.safety_check,
        color: Colors.green,
        rule: BadgeRule.positiveBalance,
        target: 1,
      ),
      WalletBadge(
        name: "Pengeluaran Terkontrol",
        subtitle: "Pemasukanmu masih menahan pengeluaran.",
        lockedText: "Pemasukan harus minimal sama dengan pengeluaran",
        icon: Icons.balance,
        color: Colors.teal,
        rule: BadgeRule.controlledExpense,
        target: 1,
      ),
      WalletBadge(
        name: "Analis Dompet",
        subtitle: "Pengeluaranmu tersebar di minimal 3 kategori.",
        lockedText: "Catat pengeluaran di minimal 3 kategori",
        icon: Icons.pie_chart,
        color: Colors.red,
        rule: BadgeRule.expenseAnalyzer,
        target: 3,
      ),
      WalletBadge(
        name: "Ada Pemasukan",
        subtitle: "Kamu sudah mencatat transaksi pemasukan.",
        lockedText: "Catat minimal 1 pemasukan",
        icon: Icons.savings,
        color: Colors.indigo,
        rule: BadgeRule.incomeRecorder,
        target: 1,
      ),
    ];
  }

  bool isBadgeUnlocked({
    required WalletBadge badge,
    required int totalTransaction,
    required int totalCategory,
    required int expenseCategoryCount,
    required int totalIncome,
    required int totalExpense,
  }) {
    switch (badge.rule) {
      case BadgeRule.streak:
        return loginStreak >= badge.target;

      case BadgeRule.firstTransaction:
        return totalTransaction >= badge.target;

      case BadgeRule.activeRecorder:
        return totalTransaction >= badge.target;

      case BadgeRule.categoryCollector:
        return totalCategory >= badge.target;

      case BadgeRule.positiveBalance:
        return saldo > 0;

      case BadgeRule.controlledExpense:
        return totalIncome > 0 &&
            totalExpense > 0 &&
            totalIncome >= totalExpense;

      case BadgeRule.expenseAnalyzer:
        return totalExpense > 0 &&
            expenseCategoryCount >= badge.target;

      case BadgeRule.incomeRecorder:
        return totalIncome > 0;
    }
  }

  double getBadgeProgress({
    required WalletBadge badge,
    required int totalTransaction,
    required int totalCategory,
    required int expenseCategoryCount,
    required int totalIncome,
    required int totalExpense,
  }) {
    switch (badge.rule) {
      case BadgeRule.streak:
        return (loginStreak / badge.target)
            .clamp(0.0, 1.0)
            .toDouble();

      case BadgeRule.firstTransaction:
      case BadgeRule.activeRecorder:
        return (totalTransaction / badge.target)
            .clamp(0.0, 1.0)
            .toDouble();

      case BadgeRule.categoryCollector:
        return (totalCategory / badge.target)
            .clamp(0.0, 1.0)
            .toDouble();

      case BadgeRule.positiveBalance:
        return saldo > 0 ? 1 : 0;

      case BadgeRule.controlledExpense:
        if (totalIncome <= 0 || totalExpense <= 0) {
          return 0;
        }

        return (totalIncome / totalExpense)
            .clamp(0.0, 1.0)
            .toDouble();

      case BadgeRule.expenseAnalyzer:
        return (expenseCategoryCount / badge.target)
            .clamp(0.0, 1.0)
            .toDouble();

      case BadgeRule.incomeRecorder:
        return totalIncome > 0 ? 1 : 0;
    }
  }

  WalletBadge getCurrentStreakBadge() {
    final streakBadges = getWalletBadges()
        .where((badge) => badge.rule == BadgeRule.streak)
        .toList();

    for (final badge in streakBadges.reversed) {
      if (loginStreak >= badge.target) {
        return badge;
      }
    }

    return const WalletBadge(
      name: "Belum Mulai",
      subtitle: "Login harian untuk membuka badge streak.",
      lockedText: "Butuh streak 7 hari",
      icon: Icons.lock_outline,
      color: Colors.grey,
      rule: BadgeRule.streak,
      target: 7,
    );
  }

  WalletBadge? getNextStreakBadge() {
    final streakBadges = getWalletBadges()
        .where((badge) => badge.rule == BadgeRule.streak)
        .toList();

    for (final badge in streakBadges) {
      if (loginStreak < badge.target) {
        return badge;
      }
    }

    return null;
  }

  String getWalletStatus({
    required int totalIncome,
    required int totalExpense,
  }) {
    if (transaksi.isEmpty) {
      return "Mulai catat transaksi pertamamu";
    }

    if (saldo < 0) {
      return "Dompet sedang bocor";
    }

    if (totalIncome > totalExpense) {
      return "Keuangan cukup aman";
    }

    if (totalExpense > totalIncome) {
      return "Pengeluaran perlu diawasi";
    }

    return "Keuangan seimbang";
  }

  void showAllBadges(
      BuildContext context, {
        required List<WalletBadge> badges,
        required int totalTransaction,
        required int totalCategory,
        required int expenseCategoryCount,
        required int totalIncome,
        required int totalExpense,
      }) {
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
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
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
                    "Semua Badge Dompet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: ListView(
                  children: badges.map((badge) {
                    final unlocked = isBadgeUnlocked(
                      badge: badge,
                      totalTransaction: totalTransaction,
                      totalCategory: totalCategory,
                      expenseCategoryCount: expenseCategoryCount,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                    );

                    final progress = getBadgeProgress(
                      badge: badge,
                      totalTransaction: totalTransaction,
                      totalCategory: totalCategory,
                      expenseCategoryCount: expenseCategoryCount,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                    );

                    return _BadgeItem(
                      badge: badge,
                      unlocked: unlocked,
                      progress: progress,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = getTotalIncome();
    final totalExpense = getTotalExpense();
    final totalTransaction = transaksi.length;
    final totalCategory = categories.length;
    final expenseCategoryCount = getExpenseCategoryCount();

    final badges = getWalletBadges();
    final currentStreakBadge = getCurrentStreakBadge();
    final nextStreakBadge = getNextStreakBadge();

    final walletStatus = getWalletStatus(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );

    final streakProgress = nextStreakBadge == null
        ? 1.0
        : (loginStreak / nextStreakBadge.target)
        .clamp(0.0, 1.0)
        .toDouble();

    final unlockedBadges = badges.where((badge) {
      return isBadgeUnlocked(
        badge: badge,
        totalTransaction: totalTransaction,
        totalCategory: totalCategory,
        expenseCategoryCount: expenseCategoryCount,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
      );
    }).length;

    final unlockedBadgeList = badges.where((badge) {
      return isBadgeUnlocked(
        badge: badge,
        totalTransaction: totalTransaction,
        totalCategory: totalCategory,
        expenseCategoryCount: expenseCategoryCount,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
      );
    }).toList();

    final lockedBadgeList = badges.where((badge) {
      return !isBadgeUnlocked(
        badge: badge,
        totalTransaction: totalTransaction,
        totalCategory: totalCategory,
        expenseCategoryCount: expenseCategoryCount,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
      );
    }).toList();

    final unlockedPreviewBadges = unlockedBadgeList.take(3).toList();

    final visibleBadges = [
      ...unlockedPreviewBadges,
      ...lockedBadgeList.take(
        3 - unlockedPreviewBadges.length,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(
              badge: currentStreakBadge,
              status: walletStatus,
            ),

            const SizedBox(height: 18),

            _GamificationCard(
              currentBadge: currentStreakBadge,
              nextBadge: nextStreakBadge,
              progress: streakProgress,
              loginStreak: loginStreak,
              unlockedBadges: unlockedBadges,
              totalBadges: badges.length,
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: "Transaksi",
                    value: "$totalTransaction",
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoCard(
                    title: "Kategori",
                    value: "$totalCategory",
                    icon: Icons.category,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: "Pemasukan",
                    value: formatRupiah(totalIncome),
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoCard(
                    title: "Pengeluaran",
                    value: formatRupiah(totalExpense),
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _CategoryManagerCard(
              totalCategory: totalCategory,
              previewCategories: categories.take(5).toList(),
              onManage: () {
                showManageCategories(context);
              },
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Badge Dompet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showAllBadges(
                      context,
                      badges: badges,
                      totalTransaction: totalTransaction,
                      totalCategory: totalCategory,
                      expenseCategoryCount: expenseCategoryCount,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                    );
                  },
                  child: Text(
                    "Lihat Semua ($unlockedBadges/${badges.length})",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Column(
              children: visibleBadges.map((badge) {
                final unlocked = isBadgeUnlocked(
                  badge: badge,
                  totalTransaction: totalTransaction,
                  totalCategory: totalCategory,
                  expenseCategoryCount: expenseCategoryCount,
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                );

                final progress = getBadgeProgress(
                  badge: badge,
                  totalTransaction: totalTransaction,
                  totalCategory: totalCategory,
                  expenseCategoryCount: expenseCategoryCount,
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                );

                return _BadgeItem(
                  badge: badge,
                  unlocked: unlocked,
                  progress: progress,
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            const Text(
              "Tentang Aplikasi",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileMenuItem(
                    icon: Icons.account_balance_wallet,
                    title: "MonMon",
                    subtitle: "Aplikasi pencatatan keuangan pribadi",
                  ),
                  Divider(),
                  _ProfileMenuItem(
                    icon: Icons.storage,
                    title: "Penyimpanan Lokal",
                    subtitle: "Data disimpan menggunakan SharedPreferences",
                  ),
                  Divider(),
                  _ProfileMenuItem(
                    icon: Icons.phone_android,
                    title: "Versi",
                    subtitle: "1.0.0",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final WalletBadge badge;
  final String status;

  const _ProfileHeader({
    required this.badge,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badge.color,
            badge.color.withValues(alpha: 0.78),
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
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Icon(
              badge.icon,
              size: 48,
              color: badge.color,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            "Pengguna MonMon",
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            badge.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GamificationCard extends StatelessWidget {
  final WalletBadge currentBadge;
  final WalletBadge? nextBadge;
  final double progress;
  final int loginStreak;
  final int unlockedBadges;
  final int totalBadges;

  const _GamificationCard({
    required this.currentBadge,
    required this.nextBadge,
    required this.progress,
    required this.loginStreak,
    required this.unlockedBadges,
    required this.totalBadges,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();

    final String progressText = nextBadge == null
        ? "Semua badge streak sudah terbuka"
        : "${(nextBadge!.target - loginStreak).clamp(0, 999)} hari lagi menuju ${nextBadge!.name}";

    final Color progressColor =
    nextBadge == null ? currentBadge.color : nextBadge!.color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: currentBadge.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  currentBadge.icon,
                  color: currentBadge.color,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentBadge.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$loginStreak hari streak aktif",
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

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 9,
              backgroundColor: Colors.grey.shade300,
              color: progressColor,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            progressText,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title: "Badge",
                  value: "$unlockedBadges/$totalBadges",
                  icon: Icons.military_tech,
                  color: currentBadge.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  title: "Streak",
                  value: "$loginStreak hari",
                  icon: Icons.local_fire_department,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final WalletBadge badge;
  final bool unlocked;
  final double progress;

  const _BadgeItem({
    required this.badge,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? badge.color : Colors.grey;
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked
            ? badge.color.withValues(alpha: 0.12)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? badge.color.withValues(alpha: 0.24)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(
              unlocked ? badge.icon : Icons.lock_outline,
              color: color,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: unlocked
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  unlocked ? badge.subtitle : badge.lockedText,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: safeProgress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Icon(
            unlocked ? Icons.check_circle : Icons.lock,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
      constraints: const BoxConstraints(
        minHeight: 105,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
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

class _CategoryManagerCard extends StatelessWidget {
  final int totalCategory;
  final List<String> previewCategories;
  final VoidCallback onManage;

  const _CategoryManagerCard({
    required this.totalCategory,
    required this.previewCategories,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.purple,
                ),
              ),

              const SizedBox(width: 12),

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
                      "$totalCategory kategori tersedia",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: onManage,
                child: const Text("Kelola"),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: previewCategories.map((category) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blue,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}