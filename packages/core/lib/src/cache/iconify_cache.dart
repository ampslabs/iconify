import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';

/// Abstract interface for Iconify icon caches.
///
/// The cache is a pure key-value store for [IconifyIconData].
/// It does not validate data — that is the provider's responsibility.
///
/// Implementations of this interface should document their eviction
/// policy (e.g., LRU, FIFO, or no eviction).
abstract interface class IconifyCache {
  /// Retrieves cached icon data for [name], or null if not cached.
  Future<IconifyIconData?> get(IconifyName name);

  /// Stores [data] under [name] in the cache.
  Future<void> put(IconifyName name, IconifyIconData data);

  /// Removes the entry for [name] from the cache.
  Future<void> remove(IconifyName name);

  /// Removes all entries from the cache.
  Future<void> clear();

  /// Returns the number of entries currently in the cache.
  Future<int> size();

  /// Returns true if the cache contains an entry for [name].
  Future<bool> contains(IconifyName name);
}
