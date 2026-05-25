import '../models/transaction.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

List<String> categories = [
  "Makan",
  "Transport",
  "Hiburan",
];

List<Transaction> transaksi = [];

int saldo = 0;

Future<void> saveData() async {

  final prefs =
  await SharedPreferences.getInstance();

  prefs.setInt('saldo', saldo);

  prefs.setStringList(
    'categories',
    categories,
  );

  List<String> transaksiJson =
  transaksi.map((t) {

    return jsonEncode(t.toJson());

  }).toList();

  prefs.setStringList(
    'transaksi',
    transaksiJson,
  );
}

Future<void> loadData() async {

  final prefs =
  await SharedPreferences.getInstance();

  saldo = prefs.getInt('saldo') ?? 0;

  categories =
      prefs.getStringList('categories') ??
          [
            "Makan",
            "Transport",
            "Hiburan",
            "Lainnya",
          ];

  List<String> transaksiJson =
      prefs.getStringList('transaksi') ?? [];

  transaksi =
      transaksiJson.map((item) {

        return Transaction.fromJson(
          jsonDecode(item),
        );

      }).toList();
}