import 'dart:typed_data';
import 'gzip_utils_stub.dart' if (dart.library.js_interop) 'gzip_utils_web.dart'
    as impl;

/// Decompresses GZIP-encoded bytes.
///
/// Uses `dart:io` on native platforms and the Web Compression Streams API on Web.
Future<Uint8List> decompressGZip(Uint8List bytes) {
  return impl.decompressGZip(bytes);
}
