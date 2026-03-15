import 'dart:io';
import 'living_cache_provider.dart';

/// A [LivingCacheStorage] implementation that uses [dart:io] for filesystem access.
///
/// This is used in CLI and in Flutter (development mode) to update the cache file.
class FileSystemLivingCacheStorage implements LivingCacheStorage {
  FileSystemLivingCacheStorage({required this.path});

  final String path;

  @override
  Future<String?> read() async {
    final file = File(path);
    if (file.existsSync()) {
      return file.readAsString();
    }
    return null;
  }

  @override
  Future<void> write(String content) async {
    final file = File(path);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Atomic write: write to a temporary file then rename
    final tempFile = File('$path.tmp');
    await tempFile.writeAsString(content);
    await tempFile.rename(path);
  }
}
