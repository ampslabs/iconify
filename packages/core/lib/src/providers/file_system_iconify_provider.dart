import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import '../errors/iconify_exception.dart';
import '../guard/svg_sanitizer.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import '../parser/iconify_json_parser.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] that reads Iconify JSON files from the filesystem.
///
/// Expects files in the structure:
/// ```
/// [root]/
///   mdi.json       ← full collection JSON
///   lucide.json
///   tabler.json
/// ```
///
/// Each JSON file must be a valid Iconify collection JSON
/// (same format as the `@iconify-json/{prefix}/icons.json` npm package).
final class FileSystemIconifyProvider extends IconifyProvider {
  FileSystemIconifyProvider({
    required this.root,
    bool preload = false,
    this.preloadPrefixes,
    this.sanitizer = const SvgSanitizer(mode: SanitizerMode.lenient),
  }) : _root = Directory(root) {
    if (preload || (preloadPrefixes?.isNotEmpty ?? false)) {
      _preloadAll();
    }
  }

  final String root;
  final Directory _root;
  final List<String>? preloadPrefixes;
  final _cache = <String, Map<String, dynamic>>{};

  /// Optional sanitizer to apply to icons loaded from the file system.
  ///
  /// Defaults to a lenient [SvgSanitizer].
  final SvgSanitizer? sanitizer;

  Future<void> _preloadAll() async {
    if (!_root.existsSync()) return;

    final prefixes = <String>[];
    if (preloadPrefixes != null) {
      prefixes.addAll(preloadPrefixes!);
    } else {
      await for (final entity in _root.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          final prefix = entity.uri.pathSegments.last.replaceAll('.json', '');
          // used_icons.json is usually in this dir but shouldn't be preloaded as a collection
          if (prefix != 'used_icons') {
            prefixes.add(prefix);
          }
        }
      }
    }

    // Parallel load using Isolate.run for parsing large JSONs if supported (Dart 2.19+)
    final results = await Future.wait(prefixes.map((p) => _loadInIsolate(p)));
    for (var i = 0; i < prefixes.length; i++) {
      if (results[i] != null) {
        _cache[prefixes[i]] = results[i]!;
      }
    }
  }

  Future<Map<String, dynamic>?> _loadInIsolate(String prefix) async {
    final path = '${_root.path}/$prefix.json';
    final file = File(path);
    if (!file.existsSync()) return null;

    try {
      final content = await file.readAsString();
      // Offload JSON decoding to a background isolate to avoid blocking the main thread
      return await Isolate.run(
          () => jsonDecode(content) as Map<String, dynamic>);
    } catch (e) {
      // Diagnostic logging for developers.
      // ignore: avoid_print
      print('Iconify SDK [LOCAL]: Failed to preload $prefix.json: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadCollection(String prefix) async {
    if (_cache.containsKey(prefix)) return _cache[prefix];

    final file = File('${_root.path}/$prefix.json');
    if (!file.existsSync()) return null;

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _cache[prefix] = json;
      return json;
    } catch (e) {
      throw IconifyParseException(
        message: 'Failed to parse $prefix.json: $e',
        field: 'file',
        rawValue: file.path,
      );
    }
  }

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    final json = await _loadCollection(name.prefix);
    if (json == null) return null;
    return IconifyJsonParser.extractIcon(
      json,
      name.iconName,
      sanitizer: sanitizer,
    );
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    final json = await _loadCollection(prefix);
    if (json == null) return null;
    return IconifyCollectionInfo.fromJson(prefix, json);
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    final json = await _loadCollection(name.prefix);
    if (json == null) return false;
    final icons = json['icons'] as Map<String, dynamic>?;
    return icons?.containsKey(name.iconName) ?? false;
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    if (_cache.containsKey(prefix)) return true;
    return File('${_root.path}/$prefix.json').existsSync();
  }
}
