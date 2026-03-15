import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

/// A global cache for [Picture] objects to avoid re-parsing SVG bodies.
///
/// This is an LRU cache that stores heavy [Picture] objects.
/// When an entry is evicted, [Picture.dispose] is called to free native resources.
class IconifyPictureCache {
  IconifyPictureCache({this.maxEntries = 200});

  final int maxEntries;
  final _cache = <String, PictureInfo>{};

  /// Returns a cached [PictureInfo] if it exists.
  PictureInfo? get(String key) {
    final info = _cache.remove(key);
    if (info != null) {
      _cache[key] = info;
    }
    return info;
  }

  /// Puts a [PictureInfo] into the cache.
  void put(String key, PictureInfo info) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxEntries) {
      final firstKey = _cache.keys.first;
      final evicted = _cache.remove(firstKey);
      evicted?.picture.dispose();
    }
    _cache[key] = info;
  }

  /// Clears the cache and disposes all pictures.
  void clear() {
    for (final info in _cache.values) {
      info.picture.dispose();
    }
    _cache.clear();
  }

  /// The current number of entries in the cache.
  int get length => _cache.length;

  /// Singleton instance
  static final IconifyPictureCache instance = IconifyPictureCache();
}

/// A key for the [IconifyPictureCache].
class PictureCacheKey {
  PictureCacheKey({
    required this.name,
    required this.size,
    this.color,
  });

  final IconifyName name;
  final int? color;
  final double size;

  @override
  String toString() => '$name:$color:$size';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PictureCacheKey &&
          name == other.name &&
          color == other.color &&
          size == other.size;

  @override
  int get hashCode => Object.hash(name, color, size);
}
