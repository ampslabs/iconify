// This file uses a pattern where futures are stored in a map for deduplication.
// These futures are intentionally not awaited at the point of assignment.
// ignore_for_file: unawaited_futures

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../guard/svg_sanitizer.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import '../parser/iconify_json_parser.dart';
import 'iconify_provider.dart';

/// Abstract base for providers that read from a Flutter asset bundle.
///
/// The concrete implementation (`FlutterAssetBundleIconifyProvider`)
/// lives in the `iconify_sdk` package which has a Flutter dependency.
///
/// This abstract class exists in core so that `iconify_sdk_core`
/// can reference asset-bundle providers in composite chains without
/// importing Flutter.
abstract class AssetBundleIconifyProvider extends IconifyProvider {
  AssetBundleIconifyProvider({
    required this.assetPrefix,
    this.sanitizer = const SvgSanitizer(mode: SanitizerMode.strict),
  });

  /// The asset path prefix where Iconify JSON files are stored.
  /// Example: `'assets/iconify'`
  final String assetPrefix;

  /// Optional sanitizer to apply to loaded icons.
  ///
  /// Defaults to a strict [SvgSanitizer] as asset bundles typically
  /// contain official starter sets.
  final SvgSanitizer? sanitizer;

  /// Internal cache to avoid re-parsing JSON for every icon request.
  final _cache = <String, ParsedCollection>{};

  /// Tracks active loading operations to prevent redundant I/O for concurrent requests.
  final _loading = <String, Future<ParsedCollection?>>{};

  /// Reads the raw bytes of an asset at [path].
  /// Implemented by platform-specific subclasses (e.g. using `rootBundle`).
  Future<Uint8List> loadAssetBytes(String path);

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
      return await _loading[prefix];
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
      final jsonPath = '$assetPrefix/$prefix.json';
      final gzPath = '$jsonPath.gz';

      Uint8List bytes;
      try {
        bytes = await loadAssetBytes(gzPath);
      } catch (_) {
        bytes = await loadAssetBytes(jsonPath);
      }

      // Decompression is handled by subclasses if they support it,
      // but if the bytes are still gzipped (e.g. core doesn't know how to decompress),
      // we might fail here. In practice, FlutterAssetBundleIconifyProvider
      // will handle the decompression before returning bytes if needed,
      // or core will use a utility.

      final jsonString = utf8.decode(bytes);
      final collection = IconifyJsonParser.parseCollectionString(
        jsonString,
        sanitizer: sanitizer,
      );

      if (collection.iconCount > 0) {
        // Use print for developer diagnostic logging in the console.
        // ignore: avoid_print
        print(
            'Iconify SDK [LOCAL]: Loaded collection $prefix (${collection.iconCount} icons) from bundle');
      }
      return collection;
    } catch (e) {
      // Use print for developer diagnostic logging in the console.
      // ignore: avoid_print
      print('Iconify SDK [LOCAL]: Failed to load asset for $prefix: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    _cache.clear();
    final loading = _loading.values.toList();
    _loading.clear();
    await Future.wait(loading);
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    try {
      final icon = await getIcon(name);
      return icon != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    try {
      final info = await getCollection(prefix);
      return info != null;
    } catch (_) {
      return false;
    }
  }
}
