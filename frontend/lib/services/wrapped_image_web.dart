import 'dart:typed_data';

/// Stub implementation for Web — these features are not available.

Future<String> saveWrappedImage(Uint8List bytes, String filename) async {
  throw UnsupportedError('saveWrappedImage is not supported on Web');
}

Future<void> shareWrappedImage(Uint8List bytes, String filename) async {
  throw UnsupportedError('shareWrappedImage is not supported on Web');
}
