import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class ExportService {
  // Export CSV
  static Future<({bool success, String message, String? filePath})> exportCSV({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await ApiService.download('/export/csv', queryParams: {
        'start_date': startDate,
        'end_date': endDate,
      });

      if (response != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'monmon_transactions_${DateTime.now().toString().split(' ')[0]}.csv';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        return (
          success: true,
          message: 'CSV berhasil diexport: $fileName',
          filePath: file.path,
        );
      }

      return (
        success: false,
        message: 'Gagal mengexport CSV',
        filePath: null,
      );
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
      final response = await ApiService.download('/export/pdf', queryParams: {
        'start_date': startDate,
        'end_date': endDate,
      });

      if (response != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'monmon_report_${DateTime.now().toString().split(' ')[0]}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        return (
          success: true,
          message: 'PDF berhasil diexport: $fileName',
          filePath: file.path,
        );
      }

      return (
        success: false,
        message: 'Gagal mengexport PDF',
        filePath: null,
      );
    } catch (e) {
      return (
        success: false,
        message: 'Error: ${e.toString()}',
        filePath: null,
      );
    }
  }
}
