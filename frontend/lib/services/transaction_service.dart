import '../models/transaction.dart';
import 'api_service.dart';

class TransactionService {
  // Get all transactions
  static Future<List<Transaction>> getAll() async {
    final response = await ApiService.get('/transactions');
    if (response.success && response.data != null) {
      final list = response.data as List;
      return list.map((t) => Transaction.fromJson(t)).toList();
    }
    return [];
  }

  // Get single transaction
  static Future<Transaction?> getById(String id) async {
    final response = await ApiService.get('/transactions/$id');
    if (response.success && response.data != null) {
      return Transaction.fromJson(response.data);
    }
    return null;
  }

  // Create transaction
  static Future<({bool success, String message, Transaction? transaction, List<dynamic>? newAchievements})> create({
    required String type,
    required double amount,
    required String categoryId,
    String? note,
    required DateTime date,
    String currency = 'IDR',
  }) async {
    final response = await ApiService.post('/transactions', body: {
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'note': note,
      'date': date.toIso8601String().split('T')[0],
      'currency': currency,
    });

    if (response.success && response.data != null) {
      return (
        success: true,
        message: response.message,
        transaction: Transaction.fromJson(response.data),
        newAchievements: response.rawBody?['new_achievements'] as List?,
      );
    }

    return (
      success: false,
      message: response.message,
      transaction: null,
      newAchievements: null,
    );
  }

  // Update transaction
  static Future<({bool success, String message})> update(
    String id, {
    String? type,
    double? amount,
    String? categoryId,
    String? note,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{};
    if (type != null) body['type'] = type;
    if (amount != null) body['amount'] = amount;
    if (categoryId != null) body['category_id'] = categoryId;
    if (note != null) body['note'] = note;
    if (date != null) body['date'] = date.toIso8601String().split('T')[0];

    final response = await ApiService.put('/transactions/$id', body: body);
    return (success: response.success, message: response.message);
  }

  // Delete transaction
  static Future<({bool success, String message})> delete(String id) async {
    final response = await ApiService.delete('/transactions/$id');
    return (success: response.success, message: response.message);
  }
}
