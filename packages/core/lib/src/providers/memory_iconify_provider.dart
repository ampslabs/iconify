import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] backed by in-memory maps.
///
/// Use for:
/// - Tests (pre-populate with known fixtures)
/// - Generated icon subsets (populate at startup from generated code)
/// - Temporary holding during app lifetime
///
/// Thread-safety: Not safe for concurrent modification. Do all [putIcon]
/// calls before any [getIcon] calls, or synchronize externally.
final class MemoryIconifyProvider extends IconifyProvider {
  MemoryIconifyProvider({
    Map<IconifyName, IconifyIconData>? icons,
    Map<String, IconifyCollectionInfo>? collections,
  })  : _icons = icons ?? {},
        _collections = collections ?? {};

  final Map<IconifyName, IconifyIconData> _icons;
  final Map<String, IconifyCollectionInfo> _collections;

  /// Stores an icon in this provider.
  void putIcon(IconifyName name, IconifyIconData data) {
    _icons[name] = data;
  }

  /// Stores collection metadata in this provider.
  void putCollection(IconifyCollectionInfo info) {
    _collections[info.prefix] = info;
  }

  /// Removes an icon from this provider.
  void removeIcon(IconifyName name) {
    _icons.remove(name);
  }

  /// Removes all icons and collections.
  void clear() {
    _icons.clear();
    _collections.clear();
  }

  /// Number of icons currently stored.
  int get iconCount => _icons.length;

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async => _icons[name];

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async =>
      _collections[prefix];

  @override
  Future<bool> hasIcon(IconifyName name) async => _icons.containsKey(name);

  @override
  Future<bool> hasCollection(String prefix) async =>
      _collections.containsKey(prefix);
}
