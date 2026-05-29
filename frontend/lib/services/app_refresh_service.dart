import 'package:flutter/foundation.dart';

class AppRefreshService {
  static final ValueNotifier<int> transactionsVersion = ValueNotifier<int>(0);
  static final ValueNotifier<int> achievementsVersion = ValueNotifier<int>(0);

  static void notifyTransactionsChanged() {
    transactionsVersion.value++;
  }

  static void notifyAchievementsChanged() {
    achievementsVersion.value++;
  }

  static void notifyAllChanged() {
    notifyTransactionsChanged();
    notifyAchievementsChanged();
  }
}
