import 'picture_cache.dart';

/// Provides diagnostic information for the Iconify SDK.
final class IconifyDiagnostics {
  IconifyDiagnostics._();

  /// Returns information about the [IconifyPictureCache].
  static PictureCacheStats get pictureCacheStats => PictureCacheStats(
        length: IconifyPictureCache.instance.length,
        maxEntries: IconifyPictureCache.instance.maxEntries,
        hits: IconifyPictureCache.instance.hits,
        misses: IconifyPictureCache.instance.misses,
      );

  /// Resets all diagnostic counters and clears caches.
  static void reset() {
    IconifyPictureCache.instance.clear();
  }
}

/// Statistics for the [IconifyPictureCache].
final class PictureCacheStats {
  const PictureCacheStats({
    required this.length,
    required this.maxEntries,
    required this.hits,
    required this.misses,
  });

  final int length;
  final int maxEntries;
  final int hits;
  final int misses;

  /// The hit rate of the cache (0.0 to 1.0).
  double get hitRate {
    final total = hits + misses;
    if (total == 0) return 0.0;
    return hits / total;
  }

  @override
  String toString() =>
      'PictureCacheStats(length: $length/$maxEntries, hits: $hits, misses: $misses, hitRate: ${hitRate.toStringAsFixed(2)})';
}
