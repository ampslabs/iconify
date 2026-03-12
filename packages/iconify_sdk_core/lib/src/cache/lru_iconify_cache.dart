import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_cache.dart';

/// An in-memory LRU (Least Recently Used) implementation of [IconifyCache].
///
/// When the cache reaches [maxEntries], the least recently used entry
/// is evicted to make room for the new entry.
///
/// This cache is not thread-safe. Do not use from concurrent isolates.
final class LruIconifyCache implements IconifyCache {
  LruIconifyCache({
    this.maxEntries = 500,
  }) : assert(maxEntries > 0, 'maxEntries must be positive');

  /// Maximum number of entries before LRU eviction occurs.
  final int maxEntries;

  // LinkedHashMap preserves insertion order, which gives us LRU for free
  // when we remove+re-insert on access.
  final _store = <IconifyName, _CacheEntry>{};

  @override
  Future<IconifyIconData?> get(IconifyName name) async {
    final entry = _store[name];
    if (entry == null) return null;

    // Move to end (most recently used)
    _store.remove(name);
    _store[name] = entry;

    return entry.data;
  }

  @override
  Future<void> put(IconifyName name, IconifyIconData data) async {
    // If already present, remove first so re-insertion puts it at the end
    _store.remove(name);

    // Evict LRU entry if at capacity
    if (_store.length >= maxEntries) {
      final lruKey = _store.keys.first;
      _store.remove(lruKey);
    }

    _store[name] = _CacheEntry(data: data, insertedAt: DateTime.now());
  }

  @override
  Future<void> remove(IconifyName name) async => _store.remove(name);

  @override
  Future<void> clear() async => _store.clear();

  @override
  Future<int> size() async => _store.length;

  @override
  Future<bool> contains(IconifyName name) async => _store.containsKey(name);

  /// Returns cache statistics for diagnostics.
  LruCacheStats get stats {
    return LruCacheStats(
      currentSize: _store.length,
      maxSize: maxEntries,
    );
  }
}

final class _CacheEntry {
  const _CacheEntry({required this.data, required this.insertedAt});
  final IconifyIconData data;
  final DateTime insertedAt;
}

/// Diagnostic statistics for [LruIconifyCache].
final class LruCacheStats {
  const LruCacheStats({
    required this.currentSize,
    required this.maxSize,
  });

  final int currentSize;
  final int maxSize;

  double get fillRatio => maxSize == 0 ? 0.0 : currentSize / maxSize;

  @override
  String toString() => 'LruCacheStats($currentSize/$maxSize, ${(fillRatio * 100).toStringAsFixed(1)}% full)';
}
