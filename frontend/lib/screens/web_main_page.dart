import 'package:flutter/material.dart';

import 'add_transaction_page.dart';
import 'home_page.dart';
import 'transaction_page.dart';
import 'report_page.dart';
import 'profile_page.dart';

class WebMainPage extends StatefulWidget {
  const WebMainPage({super.key});

  @override
  State<WebMainPage> createState() => _WebMainPageState();
}

class _WebMainPageState extends State<WebMainPage> {
  int currentIndex = 0;

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  List<Widget> get pages {
    return [
      HomePage(
        onTabChange: changePage,
      ),
      const TransactionPage(),
      const ReportPage(),
      const ProfilePage(),
    ];
  }

  final List<_WebMenuItem> menuItems = const [
    _WebMenuItem(
      title: "Beranda",
      icon: Icons.home,
    ),
    _WebMenuItem(
      title: "Transaksi",
      icon: Icons.receipt_long,
    ),
    _WebMenuItem(
      title: "Laporan",
      icon: Icons.bar_chart,
    ),
    _WebMenuItem(
      title: "Profil",
      icon: Icons.person,
    ),
  ];

  Future<void> openAddTransactionPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionPage(),
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: Colors.blue.shade700,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "MonMon",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Money Monitoring Dashboard",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        final isSelected = currentIndex == index;

                        return _SidebarMenuTile(
                          title: item.title,
                          icon: item.icon,
                          isSelected: isSelected,
                          onTap: () {
                            changePage(index);
                          },
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: openAddTransactionPage,
                      icon: const Icon(Icons.add),
                      label: const Text("Tambah Transaksi"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: pages[currentIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebMenuItem {
  final String title;
  final IconData icon;

  const _WebMenuItem({
    required this.title,
    required this.icon,
  });
}

class _SidebarMenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarMenuTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}