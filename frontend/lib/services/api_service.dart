import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static String? _token;

  // Initialize token from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Check if logged in
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // Get token
  static String? get token => _token;

  // Headers
  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // GET request
  static Future<ApiResponse> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 30),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
        statusCode: 0,
      );
    }
  }

  // POST request
  static Future<ApiResponse> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
        statusCode: 0,
      );
    }
  }

  // PUT request
  static Future<ApiResponse> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
        statusCode: 0,
      );
    }
  }

  // DELETE request
  static Future<ApiResponse> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: _getErrorMessage(e),
        statusCode: 0,
      );
    }
  }

  // Download file (for export)
  static Future<http.Response?> download(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        return response;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Handle response
  static ApiResponse _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      // Handle validation errors
      if (response.statusCode == 422 && body['errors'] != null) {
        final errors = body['errors'] as Map<String, dynamic>;
        final firstError = errors.values.first;
        final message = firstError is List ? firstError.first : firstError.toString();
        return ApiResponse(
          success: false,
          message: message,
          data: body,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: body['success'] ?? (response.statusCode >= 200 && response.statusCode < 300),
        message: body['message'] ?? '',
        data: body['data'],
        statusCode: response.statusCode,
        rawBody: body,
      );
    } catch (e) {
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }

  static String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server. Pastikan backend sudah berjalan.';
    }
    if (error.toString().contains('TimeoutException')) {
      return 'Koneksi timeout. Coba lagi.';
    }
    return 'Terjadi kesalahan: ${error.toString()}';
  }
}

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;
  final Map<String, dynamic>? rawBody;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
    this.rawBody,
  });
}
