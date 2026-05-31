import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<({bool success, String message, String? filePath})> saveFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();

    // Cleanup
    web.document.body?.removeChild(anchor);
    web.URL.revokeObjectURL(url);

    return (
      success: true,
      message:
          '${mimeType.contains('pdf') ? 'PDF' : 'CSV'} berhasil didownload: $fileName',
      filePath: null,
    );
  } catch (e) {
    return (
      success: false,
      message: 'Error downloading file: ${e.toString()}',
      filePath: null,
    );
  }
}
