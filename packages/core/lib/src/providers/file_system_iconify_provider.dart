import 'dart:convert';
import 'dart:io';
import '../errors/iconify_exception.dart';
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
  }) : _root = Directory(root) {
    if (preload) {
      // Fire and forget; load will happen on first access otherwise
      _preloadAll();
    }
  }

  final String root;
  final Directory _root;
  final _cache = <String, Map<String, dynamic>>{};

  Future<void> _preloadAll() async {
    if (!_root.existsSync()) return;
    await for (final entity in _root.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final prefix = entity.uri.pathSegments.last.replaceAll('.json', '');
        await _loadCollection(prefix);
      }
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
    return IconifyJsonParser.extractIcon(json, name.iconName);
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
    return File('${_root.path}/$prefix.json').existsSync();
  }
}
