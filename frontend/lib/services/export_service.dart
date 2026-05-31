import 'api_service.dart';

// Conditional imports for web vs native
import 'export_service_native.dart'
    if (dart.library.js_interop) 'export_service_web.dart'
    as platform_export;

class ExportService {
  // Export CSV
  static Future<({bool success, String message, String? filePath})> exportCSV({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await ApiService.download(
        '/export/csv',
        queryParams: {'start_date': startDate, 'end_date': endDate},
      );

      if (response != null) {
        final fileName =
            'monmon_transactions_${DateTime.now().toString().split(' ')[0]}.csv';

        return platform_export.saveFile(
          bytes: response.bodyBytes,
          fileName: fileName,
          mimeType: 'text/csv',
        );
      }

      return (success: false, message: 'Gagal mengexport CSV', filePath: null);
    } catch (e) {
      return (
        success: false,
        message: 'Error: ${e.toString()}',
        filePath: null,
      );
    }
  }

  // Export PDF
  static Future<({bool success, String message, String? filePath})> exportPDF({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await ApiService.download(
        '/export/pdf',
        queryParams: {'start_date': startDate, 'end_date': endDate},
      );

      if (response != null) {
        final fileName =
            'monmon_report_${DateTime.now().toString().split(' ')[0]}.pdf';

        return platform_export.saveFile(
          bytes: response.bodyBytes,
          fileName: fileName,
          mimeType: 'application/pdf',
        );
      }

      return (success: false, message: 'Gagal mengexport PDF', filePath: null);
    } catch (e) {
      return (
        success: false,
        message: 'Error: ${e.toString()}',
        filePath: null,
      );
    }
  }
}
