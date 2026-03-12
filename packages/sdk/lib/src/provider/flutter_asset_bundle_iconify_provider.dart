import 'package:flutter/services.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

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
  Future<String> loadAssetString(String path) {
    return _bundle.loadString(path);
  }
}
