import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/app_refresh_service.dart';
import '../widgets/achievement_unlocked_dialog.dart';
import 'add_transaction_page.dart';
import 'home_page.dart';
import 'transaction_page.dart';
import 'report_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  final _homeKey = GlobalKey<HomePageState>();
  final _transactionKey = GlobalKey<TransactionPageState>();
  final _reportKey = GlobalKey<ReportPageState>();

  Future<void> _handleTransactionResult(dynamic result) async {
    final changed = result == true ||
        (result is Map && result['changed'] == true);
    if (!changed) return;

    AppRefreshService.notifyAllChanged();
    _homeKey.currentState?.loadDashboard();
    _transactionKey.currentState?.loadTransactions();
    _reportKey.currentState?.loadChartData();

    final achievementsJson =
        result is Map ? result['achievements'] as List? : null;
    if (achievementsJson != null && achievementsJson.isNotEmpty && mounted) {
      for (final item in achievementsJson) {
        if (!mounted) return;
        final achievement = Achievement.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        await showAchievementUnlockedDialog(context, achievement);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,

      body: IndexedStack(
        index: currentIndex,
        children: [
          HomePage(
            key: _homeKey,
            onTabChange: (index) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
          TransactionPage(key: _transactionKey),
          ReportPage(key: _reportKey),
          const ProfilePage(),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionPage(),
            ),
          );

          await _handleTransactionResult(result);
        },
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.blue,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Riwayat Transaksi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Laporan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
