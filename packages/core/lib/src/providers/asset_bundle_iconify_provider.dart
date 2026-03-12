import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import '../parser/iconify_json_parser.dart';
import 'iconify_provider.dart';

/// Abstract base for providers that read from a Flutter asset bundle.
///
/// The concrete implementation (`FlutterAssetBundleIconifyProvider`)
/// lives in the `iconify_flutter` package which has a Flutter dependency.
///
/// This abstract class exists in core so that `iconify_sdk_core`
/// can reference asset-bundle providers in composite chains without
/// importing Flutter.
abstract class AssetBundleIconifyProvider extends IconifyProvider {
  const AssetBundleIconifyProvider({
    required this.assetPrefix,
  });

  /// The asset path prefix where Iconify JSON files are stored.
  /// Example: `'assets/iconify'`
  final String assetPrefix;

  /// Reads the raw string of an asset at [path].
  /// Implemented by platform-specific subclasses (e.g. using `rootBundle`).
  Future<String> loadAssetString(String path);

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    try {
      final path = '$assetPrefix/${name.prefix}.json';
      final jsonString = await loadAssetString(path);
      return IconifyJsonParser.parseCollectionString(jsonString)
          .getIcon(name.iconName);
    } catch (e) {
      // ignore: avoid_print
      print('Iconify SDK: Failed to load asset for ${name.prefix}: $e');
      return null;
    }
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    try {
      final path = '$assetPrefix/$prefix.json';
      final jsonString = await loadAssetString(path);
      return IconifyJsonParser.parseCollectionString(jsonString).info;
    } catch (e) {
      // ignore: avoid_print
      print('Iconify SDK: Failed to load collection asset for $prefix: $e');
      return null;
    }
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    try {
      return await getIcon(name) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    try {
      return await getCollection(prefix) != null;
    } catch (_) {
      return false;
    }
  }
}
