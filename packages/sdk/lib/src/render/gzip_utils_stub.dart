import 'dart:io';
import 'dart:typed_data';

/// Native implementation of GZIP decompression.
Future<Uint8List> decompressGZip(Uint8List bytes) async {
  return Uint8List.fromList(gzip.decode(bytes));
}
