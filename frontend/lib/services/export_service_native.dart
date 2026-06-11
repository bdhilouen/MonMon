import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const MethodChannel _downloadsChannel = MethodChannel('monmon/downloads');

Future<({bool success, String message, String? filePath})> saveFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    if (Platform.isAndroid) {
      final savedPath = await _downloadsChannel.invokeMethod<String>(
        'saveToDownloads',
        {
          'bytes': bytes,
          'fileName': fileName,
          'mimeType': mimeType,
        },
      );

      return (
        success: true,
        message:
            '${mimeType.contains('pdf') ? 'PDF' : 'CSV'} berhasil didownload ke folder Download: $fileName',
        filePath: savedPath,
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    return (
      success: true,
      message:
          '${mimeType.contains('pdf') ? 'PDF' : 'CSV'} berhasil diexport: $fileName',
      filePath: file.path,
    );
  } catch (e) {
    return (
      success: false,
      message: 'Error saving file: ${e.toString()}',
      filePath: null,
    );
  }
}
