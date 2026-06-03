import 'package:flutter/material.dart';

import 'add_transaction_page.dart';
import 'home_page.dart';
import 'transaction_page.dart';
import 'report_page.dart';
import 'profile_page.dart';
import '../models/achievement.dart';
import '../widgets/achievement_unlocked_dialog.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Future<void> openAddTransactionPage() async {
    // AddTransactionPage returns a List<Achievement> of newly unlocked
    // achievements via Navigator.pop(context, newAchievements).
    final newAchievements = await Navigator.push<List<Achievement>>(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionPage()),
    );

    // The form page is now fully closed. It's safe to show dialogs here
    // using this widget's context without risk of using a disposed context.
    if (mounted && newAchievements != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaksi berhasil dicatat!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (mounted && newAchievements != null && newAchievements.isNotEmpty) {
      for (final achievement in newAchievements) {
        if (mounted) {
          await showAchievementUnlockedDialog(context, achievement);
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,

      body: [
        HomePage(onTabChange: changePage),
        const TransactionPage(),
        const ReportPage(),
        const ProfilePage(),
      ][currentIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: openAddTransactionPage,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          changePage(index);
        },

        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Transaksi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Laporan",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
