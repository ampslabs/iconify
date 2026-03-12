import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:meta/meta.dart';
import 'iconify_mode.dart';

/// Global configuration for the Iconify SDK.
@immutable
final class IconifyConfig {
  const IconifyConfig({
    this.mode = IconifyMode.auto,
    this.customProviders = const [],
    this.cacheMaxEntries = 500,
    this.remoteApiBase,
  });

  /// The operational mode for icon resolution.
  final IconifyMode mode;

  /// Custom [IconifyProvider]s to prepend to the default provider chain.
  final List<IconifyProvider> customProviders;

  /// Maximum number of icons to keep in the in-memory cache.
  final int cacheMaxEntries;

  /// Optional base URL for the Remote API.
  /// Defaults to `https://api.iconify.design`.
  final String? remoteApiBase;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconifyConfig &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          cacheMaxEntries == other.cacheMaxEntries &&
          remoteApiBase == other.remoteApiBase;

  @override
  int get hashCode => Object.hash(mode, cacheMaxEntries, remoteApiBase);
}
