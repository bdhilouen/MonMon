import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import '../utils/formatter.dart';
import '../data/app_data.dart';



class HomePage extends StatefulWidget {

  final Function(int) onTabChange;

  const HomePage({
    super.key,
    required this.onTabChange,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

Color getCategoryColor(String category) {
  switch (category) {
    case "Makan":
      return Colors.orange;
    case "Transport":
      return Colors.blue;
    case "Hiburan":
      return Colors.purple;
    case "Pemasukan":
      return Colors.green;
    default:
      return Colors.grey;
  }
}

class _HomePageState extends State<HomePage> {
  bool isIncome = false;

  String selectedCategory = "Makan";
  List<String> categories = [
    "Makan",
    "Transport",
    "Hiburan",
    "Lainnya",
  ];

  TextEditingController controller = TextEditingController();
  TextEditingController searchController =
  TextEditingController();
  String searchQuery = "";
  TextEditingController amountController = TextEditingController();



  Map<String, int> getTotalPerCategory() {
    Map<String, int> result = {};

    for (var t in transaksi) {
      if (!t.isIncome) {
        result[t.category] = (result[t.category] ?? 0) + t.amount;
      }
    }

    return result;
  }
  List<Transaction> getFilteredTransactions() {

    if (searchQuery.isEmpty) {
      return transaksi;
    }

    return transaksi.where((t) {

      return t.title
          .toLowerCase()
          .contains(
        searchQuery.toLowerCase(),
      );

    }).toList();
  }
  int getTotalIncome() {
    int total = 0;

    for (var t in transaksi) {
      if (t.isIncome) {
        total += t.amount;
      }
    }

    return total;
  }

  int getTotalExpense() {
    int total = 0;

    for (var t in transaksi) {
      if (!t.isIncome) {
        total += t.amount;
      }
    }

    return total;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("MonMon")),
      body: Padding(
        padding : const EdgeInsets.all(16),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Saldo: ${formatRupiah(saldo)}",
                style: TextStyle(
                  fontSize:24,
                  fontWeight: FontWeight.bold,
                  color: saldo >= 0 ? Colors.green : Colors.red,
                ),
            ),
            SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Pemasukan",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          formatRupiah(getTotalIncome()),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Pengeluaran",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          formatRupiah(getTotalExpense()),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            TextField(
              controller: searchController,

              decoration: InputDecoration(
                hintText: "Cari transaksi...",

                prefixIcon: Icon(Icons.search),

                filled: true,
                fillColor: Colors.grey.shade100,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),

              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            SizedBox(height: 16),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [


                Text(
                  "Transaksi Terbaru",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    widget.onTabChange(1);
                  },

                  child: Text("Lihat Semua"),
                ),
              ],
            ),

            SizedBox(height: 20),




            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: getTotalPerCategory().entries.map((entry) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 6),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${entry.key}: Rp ${entry.value}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),

            transaksi.isEmpty
                ? Center(
              child: Text("Belum ada transaksi 😴"),
            )

            : Expanded(



              child: ListView.builder(
                itemCount: getFilteredTransactions().length > 3
                    ? 3
                    : getFilteredTransactions().length,
                itemBuilder: (context, index) {
                  final filtered = getFilteredTransactions();
                  final transaction = filtered[index];
                  return Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.circle,
                        color: getCategoryColor(transaction.category),
                      ),
                      title: Text(transaction.title),
                      subtitle: Text(
                        "${transaction.isIncome ? '+' : '-'} ${NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(transaction.amount)}\n${DateFormat('dd MMM yyyy').format(transaction.date)}",
                      ),
                      onTap: () {
                        TextEditingController editTitle =
                        TextEditingController(text: transaction.title);

                        TextEditingController editAmount =
                        TextEditingController(text: transaction.amount.toString());

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Edit Transaksi"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(controller: editTitle),
                                  TextField(
                                    controller: editAmount,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Batal"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      int newAmount =
                                          int.tryParse(editAmount.text) ?? 0;

                                      if (transaction.isIncome) {
                                        saldo -= transaction.amount;
                                      } else {
                                        saldo += transaction.amount;
                                      }

                                      transaction.title = editTitle.text;
                                      transaction.amount = newAmount;

                                      if (transaction.isIncome) {
                                        saldo += newAmount;
                                      } else {
                                        saldo -= newAmount;
                                      }

                                      saveData();
                                    });

                                    Navigator.pop(context);
                                  },
                                  child: Text("Simpan"),
                                ),
                              ],
                            );
                          },
                        );
                      },

                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            if (transaction.isIncome) {
                              saldo -= transaction.amount;
                            } else {
                              saldo += transaction.amount;
                            }
                            transaksi.remove(transaction);
                            saveData();
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    controller.dispose();
    searchController.dispose();
    amountController.dispose();
    super.dispose();
  }
}