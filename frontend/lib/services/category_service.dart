import '../models/category.dart';
import 'api_service.dart';

class CategoryService {
  // Get all categories (grouped by type)
  static Future<({List<Category> income, List<Category> expense})> getAll() async {
    final response = await ApiService.get('/categories');
    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;

      final incomeList = (data['income'] as List?)
              ?.map((c) => Category.fromJson(c))
              .toList() ??
          [];
      final expenseList = (data['expense'] as List?)
              ?.map((c) => Category.fromJson(c))
              .toList() ??
          [];

      return (income: incomeList, expense: expenseList);
    }
    return (income: <Category>[], expense: <Category>[]);
  }

  // Get all categories as flat list
  static Future<List<Category>> getAllFlat() async {
    final result = await getAll();
    return [...result.income, ...result.expense];
  }

  // Create custom category
  static Future<({bool success, String message, Category? category})> create({
    required String name,
    required String icon,
    required String color,
    required String type,
  }) async {
    final response = await ApiService.post('/categories', body: {
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
    });

    if (response.success && response.data != null) {
      return (
        success: true,
        message: response.message,
        category: Category.fromJson(response.data),
      );
    }

    return (success: false, message: response.message, category: null);
  }

  // Update custom category
  static Future<({bool success, String message})> update(
    String id, {
    String? name,
    String? icon,
    String? color,
    String? type,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (icon != null) body['icon'] = icon;
    if (color != null) body['color'] = color;
    if (type != null) body['type'] = type;

    final response = await ApiService.put('/categories/$id', body: body);
    return (success: response.success, message: response.message);
  }

  // Delete custom category
  static Future<({bool success, String message})> delete(String id) async {
    final response = await ApiService.delete('/categories/$id');
    return (success: response.success, message: response.message);
  }
}
