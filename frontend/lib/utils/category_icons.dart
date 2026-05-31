import 'package:flutter/material.dart';

IconData categoryIconFor({
  String? icon,
  String? name,
  String? type,
  bool? isIncome,
}) {
  final candidates = [icon, name, type, if (isIncome == true) 'income']
      .whereType<String>()
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty);

  for (final value in candidates) {
    switch (value) {
      case 'restaurant':
      case 'food':
      case 'makan':
      case 'meal':
        return Icons.restaurant;
      case 'directions_bus':
      case 'transport':
      case 'transportasi':
      case 'car':
        return Icons.directions_bus;
      case 'sports_esports':
      case 'game':
      case 'games':
      case 'hiburan':
      case 'entertainment':
        return Icons.sports_esports;
      case 'shopping_bag':
      case 'shopping_cart':
      case 'belanja':
      case 'shop':
        return Icons.shopping_bag;
      case 'receipt_long':
      case 'bill':
      case 'bills':
      case 'tagihan':
        return Icons.receipt_long;
      case 'school':
      case 'education':
      case 'kuliah':
      case 'pendidikan':
        return Icons.school;
      case 'local_hospital':
      case 'health':
      case 'kesehatan':
        return Icons.local_hospital;
      case 'payments':
      case 'salary':
      case 'gaji':
      case 'income':
      case 'pemasukan':
        return Icons.payments;
      case 'savings':
      case 'saving':
      case 'tabungan':
        return Icons.savings;
      case 'account_balance_wallet':
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'sell':
      case 'label':
        return Icons.sell;
      case 'more_horiz':
      case 'lainnya':
      case 'other':
        return Icons.more_horiz;
      case 'category':
      case 'package':
        return Icons.category;
    }
  }

  return isIncome == true || type == 'income' ? Icons.payments : Icons.sell;
}

String defaultCategoryIconKey(String type) {
  return type == 'income' ? 'payments' : 'sell';
}
