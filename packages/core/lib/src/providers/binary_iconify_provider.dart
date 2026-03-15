import 'dart:io';
import 'dart:typed_data';

import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import '../parser/binary_icon_format.dart';
import '../parser/iconify_json_parser.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] that reads optimized `.iconbin` files from the filesystem.
///
/// This provider is significantly faster than [FileSystemIconifyProvider] because
/// it avoids JSON parsing and supports lazy decoding of individual icons.
final class BinaryIconifyProvider extends IconifyProvider {
  BinaryIconifyProvider({
    required this.root,
    bool preload = false,
  }) : _root = Directory(root) {
    if (preload) {
      _preloadAll();
    }
  }

  final String root;
  final Directory _root;
  
  /// Cache of raw bytes for each collection.
  final _cache = <String, Uint8List>{};

  /// Cache of fully decoded collections (lazy).
  final _decodedCache = <String, ParsedCollection>{};

  Future<void> _preloadAll() async {
    if (!_root.existsSync()) return;
    await for (final entity in _root.list()) {
      if (entity is File && entity.path.endsWith('.iconbin')) {
        final prefix = entity.uri.pathSegments.last.replaceAll('.iconbin', '');
        await _loadCollectionBytes(prefix);
      }
    }
  }

  Future<Uint8List?> _loadCollectionBytes(String prefix) async {
    if (_cache.containsKey(prefix)) return _cache[prefix];

    final file = File('${_root.path}/$prefix.iconbin');
    if (!file.existsSync()) return null;

    try {
      final bytes = await file.readAsBytes();
      _cache[prefix] = bytes;
      return bytes;
    } catch (e) {
      // ignore: avoid_print
      print('Iconify SDK [BINARY]: Failed to read $prefix.iconbin: $e');
      return null;
    }
  }

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    final bytes = await _loadCollectionBytes(name.prefix);
    if (bytes == null) return null;

    // Use fast single-icon extraction
    return BinaryIconFormat.decodeIcon(bytes, name.iconName);
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    if (_decodedCache.containsKey(prefix)) {
      return _decodedCache[prefix]!.info;
    }

    final bytes = await _loadCollectionBytes(prefix);
    if (bytes == null) return null;

    try {
      final collection = BinaryIconFormat.decode(bytes);
      _decodedCache[prefix] = collection;
      return collection.info;
    } catch (e) {
      // ignore: avoid_print
      print('Iconify SDK [BINARY]: Failed to decode $prefix.iconbin: $e');
      return null;
    }
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    // hasIcon still requires finding the icon in the index.
    // decodeIcon returns null if not found, so it's a good proxy.
    final icon = await getIcon(name);
    return icon != null;
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    if (_cache.containsKey(prefix)) return true;
    return File('${_root.path}/$prefix.iconbin').existsSync();
  }

  @override
  Future<void> dispose() async {
    _cache.clear();
    _decodedCache.clear();
  }
}
