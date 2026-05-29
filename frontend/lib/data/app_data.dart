import 'package:shared_preferences/shared_preferences.dart';

// Token-only storage (transactions & categories now come from API)
Future<String?> getAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

Future<void> saveAuthToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<void> clearAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
}

Future<void> clearAllLocalData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}