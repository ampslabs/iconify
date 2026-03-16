import 'package:flutter/services.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import '../render/gzip_utils.dart';

/// An [IconifyProvider] that reads Iconify JSON files from a Flutter [AssetBundle].
///
/// This is the primary provider for bundled icon collections.
class FlutterAssetBundleIconifyProvider extends AssetBundleIconifyProvider {
  FlutterAssetBundleIconifyProvider({
    required super.assetPrefix,
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<Uint8List> loadAssetBytes(String path) async {
    final byteData = await _bundle.load(path);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    if (path.endsWith('.gz')) {
      return decompressGZip(bytes);
    }
    return bytes;
  }
}
