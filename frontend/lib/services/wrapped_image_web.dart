import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web implementation — triggers a browser file download via an anchor element.

Future<String> saveWrappedImage(Uint8List bytes, String filename) async {
  final base64 = base64Encode(bytes);
  final dataUrl = 'data:image/png;base64,$base64';

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = dataUrl;
  anchor.download = filename;
  anchor.style.display = 'none';

  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();

  return filename;
}

Future<void> shareWrappedImage(Uint8List bytes, String filename) async {
  // Web doesn't have native share — fall back to download.
  await saveWrappedImage(bytes, filename);
}
