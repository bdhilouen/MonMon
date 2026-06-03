import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Native implementation — uses dart:io, path_provider, and share_plus.

Future<String> saveWrappedImage(Uint8List bytes, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}

Future<void> shareWrappedImage(Uint8List bytes, String filename) async {
  final filePath = await saveWrappedImage(bytes, filename);
  await Share.shareXFiles(
    [XFile(filePath)],
    text: 'Monthly Wrapped MonMon',
  );
}
