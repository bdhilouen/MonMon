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
      case 'home':
        return Icons.home;
      case 'local_cafe':
      case 'coffee':
      case 'kopi':
        return Icons.local_cafe;
      case 'directions_car':
        return Icons.directions_car;
      case 'flight':
      case 'travel':
        return Icons.flight;
      case 'fitness_center':
      case 'gym':
        return Icons.fitness_center;
      case 'pets':
        return Icons.pets;
      case 'child_care':
        return Icons.child_care;
      case 'phonelink':
      case 'gadget':
      case 'electronics':
        return Icons.phonelink;
      case 'build':
      case 'repair':
        return Icons.build;
      case 'attach_money':
      case 'bonus':
        return Icons.attach_money;
    }
  }

  return isIncome == true || type == 'income' ? Icons.payments : Icons.sell;
}

/// Direct icon lookup by key (used by the icon picker).
IconData iconDataFor(String key) {
  return kPickableIcons[key] ?? Icons.category;
}

String defaultCategoryIconKey(String type) {
  return type == 'income' ? 'payments' : 'sell';
}

/// Curated list of icons available in the icon-picker.
/// Key = string stored in DB / model; Value = IconData rendered in UI.
const Map<String, IconData> kPickableIcons = {
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe,
  'shopping_bag': Icons.shopping_bag,
  'directions_bus': Icons.directions_bus,
  'directions_car': Icons.directions_car,
  'flight': Icons.flight,
  'home': Icons.home,
  'school': Icons.school,
  'local_hospital': Icons.local_hospital,
  'fitness_center': Icons.fitness_center,
  'sports_esports': Icons.sports_esports,
  'pets': Icons.pets,
  'child_care': Icons.child_care,
  'phonelink': Icons.phonelink,
  'build': Icons.build,
  'receipt_long': Icons.receipt_long,
  'payments': Icons.payments,
  'savings': Icons.savings,
  'attach_money': Icons.attach_money,
  'account_balance_wallet': Icons.account_balance_wallet,
  'sell': Icons.sell,
  'more_horiz': Icons.more_horiz,
};
