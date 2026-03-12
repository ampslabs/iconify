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
  AssetBundleIconifyProvider({
    required this.assetPrefix,
  });

  /// The asset path prefix where Iconify JSON files are stored.
  /// Example: `'assets/iconify'`
  final String assetPrefix;

  /// Internal cache to avoid re-parsing JSON for every icon request.
  final _cache = <String, ParsedCollection>{};

  /// Tracks active loading operations to prevent redundant I/O for concurrent requests.
  final _loading = <String, Future<ParsedCollection?>>{};

  /// Reads the raw string of an asset at [path].
  /// Implemented by platform-specific subclasses (e.g. using `rootBundle`).
  Future<String> loadAssetString(String path);

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    final collection = await _getOrLoadCollection(name.prefix);
    return collection?.getIcon(name.iconName);
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    final collection = await _getOrLoadCollection(prefix);
    return collection?.info;
  }

  Future<ParsedCollection?> _getOrLoadCollection(String prefix) async {
    // 1. Check completed cache
    if (_cache.containsKey(prefix)) {
      return _cache[prefix];
    }

    // 2. Check if already loading
    if (_loading.containsKey(prefix)) {
      return _loading[prefix];
    }

    // 3. Start loading
    final loadFuture = _load(prefix);
    _loading[prefix] = loadFuture;

    try {
      final result = await loadFuture;
      if (result != null) {
        _cache[prefix] = result;
      }
      return result;
    } finally {
      _loading.remove(prefix);
    }
  }

  Future<ParsedCollection?> _load(String prefix) async {
    try {
      final path = '$assetPrefix/$prefix.json';
      final jsonString = await loadAssetString(path);
      final collection = IconifyJsonParser.parseCollectionString(jsonString);

      // Diagnostic logging for debugging.
      // ignore: avoid_print
      if (collection.iconCount > 0) {
        print(
            'Iconify SDK [LOCAL]: Loaded collection $prefix (${collection.iconCount} icons) from bundle');
      }
      return collection;
    } catch (e) {
      // Diagnostic logging for debugging.
      // ignore: avoid_print
      print('Iconify SDK [LOCAL]: Failed to load asset for $prefix: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    _cache.clear();
    _loading.clear();
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
