import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import '../parser/binary_icon_format.dart';
import '../parser/iconify_json_parser.dart';
import 'file_system_iconify_provider.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] that reads optimized `.iconbin` files from the filesystem.
///
/// This provider is significantly faster than [FileSystemIconifyProvider] because
/// it avoids JSON parsing and supports lazy decoding of individual icons.
final class BinaryIconifyProvider extends IconifyProvider {
  BinaryIconifyProvider({
    required this.root,
    bool preload = false,
    this.preloadPrefixes,
  }) : _root = Directory(root) {
    if (preload || (preloadPrefixes?.isNotEmpty ?? false)) {
      _preloadAll();
    }
  }

  final String root;
  final Directory _root;

  /// Optional list of collection prefixes to preload.
  final List<String>? preloadPrefixes;

  /// Cache of raw bytes for each collection.
  final _cache = <String, Uint8List>{};

  /// Cache of fully decoded collections (lazy).
  final _decodedCache = <String, ParsedCollection>{};

  Future<void> _preloadAll() async {
    if (!_root.existsSync()) return;

    final prefixes = <String>[];
    if (preloadPrefixes != null) {
      prefixes.addAll(preloadPrefixes!);
    } else {
      final discoveredPrefixes = <String>{};
      await for (final entity in _root.list()) {
        if (entity is File) {
          final path = entity.path;
          if (path.endsWith('.iconbin') || path.endsWith('.iconbin.gz')) {
            final fileName = entity.uri.pathSegments.last;
            final prefix = fileName.split('.').first;
            discoveredPrefixes.add(prefix);
          }
        }
      }
      prefixes.addAll(discoveredPrefixes);
    }

    // Parallel load using Isolate.run for reading files off-thread
    final results = await Future.wait(prefixes.map((p) => _loadInIsolate(p)));
    for (var i = 0; i < prefixes.length; i++) {
      if (results[i] != null) {
        _cache[prefixes[i]] = results[i]!;
      }
    }
  }

  Future<Uint8List?> _loadInIsolate(String prefix) async {
    final binPath = '${_root.path}/$prefix.iconbin';
    final gzPath = '$binPath.gz';

    File file = File(gzPath);
    bool isGzipped = true;
    if (!file.existsSync()) {
      file = File(binPath);
      isGzipped = false;
    }

    if (!file.existsSync()) return null;

    try {
      final bytes = await Isolate.run(() => file.readAsBytesSync());
      if (isGzipped) {
        return await Isolate.run(() => Uint8List.fromList(gzip.decode(bytes)));
      }
      return bytes;
    } catch (e) {
      // Diagnostic logging for developers.
      // ignore: avoid_print
      print('Iconify SDK [BINARY]: Failed to preload $prefix: $e');
      return null;
    }
  }

  Future<Uint8List?> _loadCollectionBytes(String prefix) async {
    if (_cache.containsKey(prefix)) return _cache[prefix];

    final binPath = '${_root.path}/$prefix.iconbin';
    final gzPath = '$binPath.gz';

    File file = File(gzPath);
    bool isGzipped = true;
    if (!file.existsSync()) {
      file = File(binPath);
      isGzipped = false;
    }

    if (!file.existsSync()) return null;

    try {
      final bytes = await file.readAsBytes();
      final decodedBytes =
          isGzipped ? Uint8List.fromList(gzip.decode(bytes)) : bytes;
      _cache[prefix] = decodedBytes;
      return decodedBytes;
    } catch (e) {
      // BinaryIconifyProvider uses print for developer diagnostics.
      // ignore: avoid_print
      print('Iconify SDK [BINARY]: Failed to read $prefix: $e');
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
      // BinaryIconifyProvider uses print for developer diagnostics.
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
