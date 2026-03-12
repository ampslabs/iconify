import '../errors/iconify_exception.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';

/// The core abstraction for resolving Iconify icon data.
///
/// Implement this interface to create custom icon sources:
/// - bundled assets
/// - remote APIs
/// - generated subsets
/// - in-memory maps
/// - composite chains
///
/// Implementations MUST NOT throw for "not found" cases —
/// return `null` instead. Only throw [IconifyException] subclasses
/// for unexpected failures (network errors, parse errors, etc.).
abstract class IconifyProvider {
  const IconifyProvider();

  /// Retrieves icon data for the given [name].
  ///
  /// Returns `null` if the icon is not available in this provider.
  /// Throws [IconifyNetworkException] on network failures.
  /// Throws [IconifyParseException] if the data is malformed.
  Future<IconifyIconData?> getIcon(IconifyName name);

  /// Retrieves collection metadata for the given [prefix].
  ///
  /// Returns `null` if the collection is not available.
  Future<IconifyCollectionInfo?> getCollection(String prefix);

  /// Returns true if this provider has data for the given [name].
  ///
  /// Must not throw. Returns `false` on any error.
  Future<bool> hasIcon(IconifyName name);

  /// Returns true if this provider has metadata for the given [prefix].
  ///
  /// Must not throw. Returns `false` on any error.
  Future<bool> hasCollection(String prefix);

  /// Disposes resources held by this provider.
  ///
  /// After disposal, all methods may throw [StateError].
  Future<void> dispose() async {}
}

/// Extension to support write operations on providers that support them.
extension WritableIconifyProvider on IconifyProvider {
  // This extension is intentionally empty.
  // Writable providers expose putIcon() directly on their concrete type.
}
