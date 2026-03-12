import '../errors/iconify_exception.dart';
import '../models/iconify_icon_data.dart';

/// Resolves icon aliases within a collection.
///
/// Iconify collections may define aliases that point to other icons.
/// An alias can itself be an alias (chained). This resolver handles
/// chains of arbitrary depth while detecting and rejecting circular references.
///
/// ```dart
/// final resolver = AliasResolver();
/// final icon = resolver.resolve(
///   iconName: 'home-variant-outline',
///   icons: collectionIcons,
///   aliases: collectionAliases,
///   defaultWidth: 24,
///   defaultHeight: 24,
/// );
/// ```
final class AliasResolver {
  const AliasResolver({
    this.maxChainDepth = 10,
  });

  /// Maximum alias chain depth before throwing [CircularAliasException].
  final int maxChainDepth;

  /// Resolves [iconName] to its final [IconifyIconData].
  ///
  /// First looks in [icons] for a direct match.
  /// If not found, looks in [aliases] and follows the chain.
  /// Returns null if not found in either.
  ///
  /// Throws [CircularAliasException] if a cycle is detected.
  IconifyIconData? resolve({
    required String iconName,
    required Map<String, IconifyIconData> icons,
    required Map<String, AliasEntry> aliases,
    required double defaultWidth,
    required double defaultHeight,
  }) {
    // Direct icon match — no alias resolution needed
    if (icons.containsKey(iconName)) {
      return icons[iconName];
    }

    // Start alias resolution
    final chain = <String>[iconName];
    var currentName = iconName;
    final Map<String, dynamic> overrides = {};

    while (true) {
      if (chain.length > maxChainDepth) {
        throw CircularAliasException(
          chain: List.from(chain),
          message: 'Alias chain exceeded maximum depth of $maxChainDepth. '
              'Chain: ${chain.join(' -> ')}. '
              'This indicates a circular alias or abnormally deep chain.',
        );
      }

      final alias = aliases[currentName];
      if (alias == null) {
        // Neither icon nor alias — not found
        return null;
      }

      // Collect overrides from this alias level (do not overwrite higher-level overrides)
      if (alias.width != null)
        overrides.putIfAbsent('width', () => alias.width);
      if (alias.height != null)
        overrides.putIfAbsent('height', () => alias.height);
      if (alias.rotate != null)
        overrides.putIfAbsent('rotate', () => alias.rotate);
      if (alias.hFlip != null)
        overrides.putIfAbsent('hFlip', () => alias.hFlip);
      if (alias.vFlip != null)
        overrides.putIfAbsent('vFlip', () => alias.vFlip);

      final parentName = alias.parent;

      // Circular reference check
      if (chain.contains(parentName)) {
        chain.add(parentName); // Include in chain for error message
        throw CircularAliasException(
          chain: List.from(chain),
          message: 'Circular alias detected. Chain: ${chain.join(' -> ')}.',
        );
      }

      chain.add(parentName);
      currentName = parentName;

      // Check if the parent is a direct icon
      if (icons.containsKey(currentName)) {
        final base = icons[currentName]!;
        // Apply collected overrides
        return base.copyWith(
          width: (overrides['width'] as num?)?.toDouble(),
          height: (overrides['height'] as num?)?.toDouble(),
          rotate: overrides['rotate'] as int?,
          hFlip: overrides['hFlip'] as bool?,
          vFlip: overrides['vFlip'] as bool?,
        );
      }

      // Parent is also an alias — continue the loop
    }
  }
}

/// Represents a single alias entry in a collection's alias map.
final class AliasEntry {
  const AliasEntry({
    required this.parent,
    this.width,
    this.height,
    this.rotate,
    this.hFlip,
    this.vFlip,
  });

  factory AliasEntry.fromJson(Map<String, dynamic> json) => AliasEntry(
        parent: json['parent'] as String,
        width: (json['width'] as num?)?.toDouble(),
        height: (json['height'] as num?)?.toDouble(),
        rotate: json['rotate'] as int?,
        hFlip: json['hFlip'] as bool?,
        vFlip: json['vFlip'] as bool?,
      );

  /// The name of the parent icon or alias (within the same collection).
  final String parent;

  final double? width;
  final double? height;
  final int? rotate;
  final bool? hFlip;
  final bool? vFlip;
}
