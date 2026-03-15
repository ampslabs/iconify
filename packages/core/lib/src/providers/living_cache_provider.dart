import 'dart:async';
import 'dart:convert';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_provider.dart';

/// An abstraction for reading and writing the living cache file.
///
/// This allows [LivingCacheProvider] to work in both Flutter (via rootBundle/assets)
/// and CLI (via dart:io).
abstract interface class LivingCacheStorage {
  /// Reads the content of the living cache file.
  ///
  /// Returns null if the file does not exist.
  Future<String?> read();

  /// Writes the content of the living cache file.
  Future<void> write(String content);
}

/// A provider that manages a "living cache" of icons used by the application.
///
/// This provider serves two purposes:
/// 1. **Production Bundle:** It reads from `assets/iconify/used_icons.json`,
///    which contains exactly the icons needed by the app, eliminating the
///    need for large starter assets in production.
/// 2. **Development Write-back:** In development, it can be updated with
///    icons fetched from remote or local sources, making them available
///    offline for subsequent runs.
final class LivingCacheProvider extends IconifyProvider {
  LivingCacheProvider({
    required this.storage,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  final LivingCacheStorage storage;
  final Duration debounceDuration;

  bool _loaded = false;
  int _schemaVersion = 1;
  Map<String, IconifyIconData> _icons = {};
  final Map<String, String> _sources = {};

  Timer? _flushTimer;
  Completer<void>? _flushCompleter;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    try {
      final content = await storage.read();
      if (content != null && content.isNotEmpty) {
        final json = jsonDecode(content) as Map<String, dynamic>;
        _schemaVersion = json['schemaVersion'] as int? ?? 1;

        final iconsJson = json['icons'] as Map<String, dynamic>? ?? {};
        _icons = iconsJson.map((key, value) {
          final iconData =
              IconifyIconData.fromJson(value as Map<String, dynamic>);
          // Extract source info if present in the JSON
          final source = value['source'] as String?;
          if (source != null) {
            _sources[key] = source;
          }
          return MapEntry(key, iconData);
        });
      }
    } catch (e) {
      // If load fails, we start with an empty cache
      _icons = {};
    } finally {
      _loaded = true;
    }
  }

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    await _ensureLoaded();
    final key = name.toString();
    final icon = _icons[key];
    if (icon == null) return null;

    // Attach source info back to the raw data for runtime use
    if (_sources.containsKey(key)) {
      return icon.copyWith(raw: {...icon.raw, 'source': _sources[key]});
    }
    return icon;
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    // LivingCache is a flat map of icons, it doesn't represent full collections.
    return null;
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    await _ensureLoaded();
    return _icons.containsKey(name.toString());
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    // We don't track collection existence, only individual icons.
    return false;
  }

  /// Adds an icon to the living cache.
  ///
  /// [source] indicates where the icon came from (e.g., "remote", "starter").
  Future<void> addIcon(IconifyName name, IconifyIconData data,
      {String? source}) async {
    await _ensureLoaded();

    final key = name.toString();
    _icons[key] = data;
    if (source != null) {
      _sources[key] = source;
    }

    _scheduleFlush();
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushCompleter ??= Completer<void>();

    _flushTimer = Timer(debounceDuration, () async {
      final completer = _flushCompleter;
      _flushCompleter = null;

      try {
        await flush();
        completer?.complete();
      } catch (e) {
        completer?.completeError(e);
      }
    });
  }

  /// Forces a write of the current cache to storage.
  Future<void> flush() async {
    final iconsJson = <String, Map<String, dynamic>>{};

    _icons.forEach((key, data) {
      final json = data.toJson();
      if (_sources.containsKey(key)) {
        json['source'] = _sources[key];
      }
      iconsJson[key] = json;
    });

    final json = {
      'schemaVersion': _schemaVersion,
      'generated': DateTime.now().toUtc().toIso8601String(),
      'icons': iconsJson,
    };

    final content = const JsonEncoder.withIndent('  ').convert(json);
    await storage.write(content);
  }

  @override
  Future<void> dispose() async {
    _flushTimer?.cancel();
    // Note: We don't await flush here as dispose is usually synchronous.
    // Users should call flush() explicitly if they want to ensure persistence.
  }
}
