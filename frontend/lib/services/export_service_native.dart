import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<({bool success, String message, String? filePath})> saveFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
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
