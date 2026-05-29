import '../models/dashboard_data.dart';
import '../models/monthly_wrapped.dart';
import 'api_service.dart';

class DashboardService {
  // Get dashboard data
  static Future<DashboardData?> getDashboard({String? month}) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month;

    final response =
        await ApiService.get('/dashboard', queryParams: queryParams);
    if (response.success && response.data != null) {
      return DashboardData.fromJson(response.data);
    }
    return null;
  }

  // Get chart data
  static Future<ChartDataResponse?> getChartData({
    required String startDate,
    required String endDate,
    String groupBy = 'day',
  }) async {
    final response = await ApiService.get('/dashboard/chart', queryParams: {
      'start_date': startDate,
      'end_date': endDate,
      'group_by': groupBy,
    });

    if (response.success && response.data != null) {
      return ChartDataResponse.fromJson(response.data);
    }
    return null;
  }

  // Get monthly wrapped
  static Future<MonthlyWrapped?> getMonthlyWrapped(int year, int month) async {
    final response = await ApiService.get('/wrapped/$year/$month');
    if (response.success && response.data != null) {
      return MonthlyWrapped.fromJson(
        response.data,
        response.rawBody?['insights'] as List?,
      );
    }
    return null;
  }
}
