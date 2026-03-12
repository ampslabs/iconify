import '../cache/iconify_cache.dart';
import '../cache/lru_iconify_cache.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] decorator that caches results from [inner].
///
/// On a cache miss, delegates to [inner] and stores the result.
/// On a cache hit, returns the cached value without calling [inner].
///
/// ```dart
/// final provider = CachingIconifyProvider(
///   inner: RemoteIconifyProvider(),
///   cache: LruIconifyCache(maxEntries: 300),
/// );
/// ```
final class CachingIconifyProvider implements IconifyProvider {
  CachingIconifyProvider({
    required this.inner,
    IconifyCache? cache,
  }) : _cache = cache ?? LruIconifyCache();

  final IconifyProvider inner;
  final IconifyCache _cache;

  int _hits = 0;
  int _misses = 0;

  /// Number of cache hits since this provider was created.
  int get hits => _hits;

  /// Number of cache misses since this provider was created.
  int get misses => _misses;

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    final cached = await _cache.get(name);
    if (cached != null) {
      _hits++;
      return cached;
    }

    _misses++;
    final result = await inner.getIcon(name);
    if (result != null) {
      await _cache.put(name, result);
    }
    return result;
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) =>
      inner.getCollection(prefix);

  @override
  Future<bool> hasIcon(IconifyName name) async {
    if (await _cache.contains(name)) return true;
    return inner.hasIcon(name);
  }

  @override
  Future<bool> hasCollection(String prefix) => inner.hasCollection(prefix);

  @override
  Future<void> dispose() async {
    await inner.dispose();
    await _cache.clear();
  }

  /// Resets hit/miss counters (for diagnostics).
  void resetStats() {
    _hits = 0;
    _misses = 0;
  }
}
