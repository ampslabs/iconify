import 'dart:io';
import 'dart:typed_data';
import 'living_cache_provider.dart';

/// A [LivingCacheStorage] implementation that uses [dart:io] for filesystem access.
///
/// This is used in CLI and in Flutter (development mode) to update the cache file.
class FileSystemLivingCacheStorage implements LivingCacheStorage {
  FileSystemLivingCacheStorage({required this.path});

  final String path;

  @override
  bool get isReadOnly => false;

  @override
  Future<Uint8List?> readBytes() async {
    final file = File(path);
    if (!file.existsSync()) return null;

    final bytes = await file.readAsBytes();
    if (path.endsWith('.gz')) {
      return Uint8List.fromList(gzip.decode(bytes));
    }
    return bytes;
  }

  @override
  Future<void> writeBytes(Uint8List bytes) async {
    final file = File(path);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final Uint8List dataToWrite;
    if (path.endsWith('.gz')) {
      dataToWrite = Uint8List.fromList(gzip.encode(bytes));
    } else {
      dataToWrite = bytes;
    }

    // Atomic write: write to a temporary file then rename
    final tempFile = File('$path.tmp');
    await tempFile.writeAsBytes(dataToWrite);
    await tempFile.rename(path);
  }
}
