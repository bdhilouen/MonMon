import '../models/transaction.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

List<String> categories = [
  "Makan",
  "Transport",
  "Hiburan",
  "Lainnya",
];

List<Transaction> transaksi = [];

int saldo = 0;

int loginStreak = 0;
String lastOpenDate = "";

String getDateKey(DateTime date) {
  return "${date.year.toString().padLeft(4, '0')}-"
      "${date.month.toString().padLeft(2, '0')}-"
      "${date.day.toString().padLeft(2, '0')}";
}

Future<void> updateLoginStreak() async {
  final today = getDateKey(DateTime.now());

  if (lastOpenDate == today) {
    if (loginStreak <= 0) {
      loginStreak = 1;
      await saveData();
    }

    return;
  }

  if (lastOpenDate.isEmpty) {
    loginStreak = 1;
  } else {
    final lastDate = DateTime.tryParse(lastOpenDate);
    final nowDate = DateTime.parse(today);

    if (lastDate == null) {
      loginStreak = 1;
    } else {
      final difference = nowDate.difference(lastDate).inDays;

      if (difference == 1) {
        loginStreak += 1;
      } else if (difference > 1) {
        loginStreak = 1;
      } else {
        if (loginStreak <= 0) {
          loginStreak = 1;
        }
      }
    }
  }

  lastOpenDate = today;

  await saveData();
}

Future<void> saveData() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setInt('saldo', saldo);

  await prefs.setInt('loginStreak', loginStreak);

  await prefs.setString('lastOpenDate', lastOpenDate);

  await prefs.setStringList(
    'categories',
    categories,
  );

  List<String> transaksiJson = transaksi.map((t) {
    return jsonEncode(t.toJson());
  }).toList();

  await prefs.setStringList(
    'transaksi',
    transaksiJson,
  );
}

Future<void> loadData() async {
  final prefs = await SharedPreferences.getInstance();

  saldo = prefs.getInt('saldo') ?? 0;

  loginStreak = prefs.getInt('loginStreak') ?? 0;

  lastOpenDate = prefs.getString('lastOpenDate') ?? "";

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

  transaksi = transaksiJson.map((item) {
    return Transaction.fromJson(
      jsonDecode(item),
    );
  }).toList();
}