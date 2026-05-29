import '../models/achievement.dart';
import 'api_service.dart';

class AchievementService {
  // Get all achievements with unlock status
  static Future<List<Achievement>> getAll() async {
    final response = await ApiService.get('/achievements');
    if (response.success && response.data != null) {
      final list = response.data as List;
      return list.map((a) => Achievement.fromJson(a)).toList();
    }
    return [];
  }

  // Get user's unlocked achievements
  static Future<List<Achievement>> getMyAchievements() async {
    final response = await ApiService.get('/achievements/my');
    if (response.success && response.data != null) {
      final list = response.data as List;
      return list
          .map((a) => Achievement.fromJson({...a, 'is_unlocked': true}))
          .toList();
    }
    return [];
  }

  // Check and unlock new achievements
  static Future<List<dynamic>> checkAchievements() async {
    final response = await ApiService.post('/achievements/check');
    if (response.success && response.data != null) {
      return response.data['newly_unlocked'] as List? ?? [];
    }
    return [];
  }
}
