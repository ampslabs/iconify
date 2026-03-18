import 'package:flutter/services.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import '../render/gzip_utils.dart';

/// A [LivingCacheStorage] implementation that reads from the Flutter [AssetBundle].
///
/// This is read-only because assets cannot be modified at runtime in a Flutter app.
/// It is used in release mode to serve the icons bundled in `used_icons.json`.
class AssetBundleLivingCacheStorage implements LivingCacheStorage {
  AssetBundleLivingCacheStorage({
    this.bundle,
    this.path = 'assets/iconify/used_icons.json',
  });

  final AssetBundle? bundle;
  final String path;

  @override
  bool get isReadOnly => true;

  @override
  Future<Uint8List?> readBytes() async {
    try {
      final actualBundle = bundle ?? rootBundle;
      final byteData = await actualBundle.load(path);
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      if (path.endsWith('.gz')) {
        return await decompressGZip(bytes);
      }
      return bytes;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> writeBytes(Uint8List bytes) async {
    // Assets are read-only at runtime.
    // In development, FileSystemLivingCacheStorage should be used instead.
    throw UnsupportedError('Cannot write to AssetBundle at runtime.');
  }
}
