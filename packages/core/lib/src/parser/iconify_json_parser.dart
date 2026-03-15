import 'dart:convert';
import '../errors/iconify_exception.dart';
import '../guard/svg_sanitizer.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../resolver/alias_resolver.dart';

/// Parses Iconify collection JSON into typed models.
///
/// The Iconify JSON format is documented at:
/// https://iconify.design/docs/types/iconify-json.html
///
/// Example input (abbreviated):
/// ```json
/// {
///   "prefix": "mdi",
///   "info": { "name": "Material Design Icons", "total": 7446, ... },
///   "icons": {
///     "home": { "body": "<path d='...'/>", "width": 24 }
///   },
///   "aliases": {
///     "home-outline": { "parent": "home" }
///   },
///   "width": 24,
///   "height": 24
/// }
/// ```
final class IconifyJsonParser {
  const IconifyJsonParser._();

  /// Parses a raw JSON string into a [ParsedCollection].
  ///
  /// Throws [IconifyParseException] on malformed input.
  static ParsedCollection parseCollectionString(String jsonString,
      {SvgSanitizer? sanitizer}) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw IconifyParseException(
        message: 'Invalid JSON: $e',
      );
    }
    return parseCollection(json, sanitizer: sanitizer);
  }

  /// Parses a decoded JSON map into a [ParsedCollection].
  ///
  /// Throws [IconifyParseException] on schema violations.
  static ParsedCollection parseCollection(Map<String, dynamic> json,
      {SvgSanitizer? sanitizer}) {
    try {
      final prefix = json['prefix'] as String?;
      if (prefix == null || prefix.isEmpty) {
        throw const IconifyParseException(
          message: 'Collection JSON is missing required "prefix" field.',
          field: 'prefix',
        );
      }

      final rawIcons = json['icons'] as Map<String, dynamic>?;
      if (rawIcons == null) {
        throw IconifyParseException(
          message: 'Collection "$prefix" is missing required "icons" field.',
          field: 'icons',
        );
      }

      final defaultWidth = (json['width'] as num?)?.toDouble() ?? 24.0;
      final defaultHeight = (json['height'] as num?)?.toDouble() ?? 24.0;

      // Parse icons
      final icons = <String, IconifyIconData>{};
      for (final entry in rawIcons.entries) {
        try {
          final iconJson =
              Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
          iconJson.putIfAbsent('width', () => defaultWidth);
          iconJson.putIfAbsent('height', () => defaultHeight);
          icons[entry.key] =
              IconifyIconData.fromJson(iconJson, sanitizer: sanitizer);
        } catch (e) {
          throw IconifyParseException(
            message:
                'Failed to parse icon "${entry.key}" in collection "$prefix": $e',
            field: 'icons.${entry.key}',
            rawValue: entry.value,
          );
        }
      }

      // Parse aliases
      final rawAliases = json['aliases'] as Map<String, dynamic>? ?? {};
      final aliases = <String, AliasEntry>{};
      for (final entry in rawAliases.entries) {
        try {
          aliases[entry.key] = AliasEntry.fromJson(
            Map<String, dynamic>.from(entry.value as Map<String, dynamic>),
          );
        } catch (e) {
          // Non-fatal: skip malformed alias entries with a warning
          // In production, these should be reported but not crash parsing
        }
      }

      final info = IconifyCollectionInfo.fromJson(prefix, json);

      return ParsedCollection(
        prefix: prefix,
        info: info,
        icons: icons,
        aliases: aliases,
        defaultWidth: defaultWidth,
        defaultHeight: defaultHeight,
      );
    } catch (e) {
      if (e is IconifyParseException) rethrow;
      throw IconifyParseException(
        message: 'Unexpected structure in collection JSON: $e',
      );
    }
  }

  /// Extracts a single icon from a pre-decoded collection JSON map.
  ///
  /// Handles alias resolution transparently.
  /// Returns null if the icon or alias target is not found.
  ///
  /// Throws [IconifyParseException] if the JSON structure is invalid.
  static IconifyIconData? extractIcon(
    Map<String, dynamic> collectionJson,
    String iconName, {
    SvgSanitizer? sanitizer,
  }) {
    try {
      final defaultWidth =
          (collectionJson['width'] as num?)?.toDouble() ?? 24.0;
      final defaultHeight =
          (collectionJson['height'] as num?)?.toDouble() ?? 24.0;
      final rawIcons = collectionJson['icons'] as Map<String, dynamic>? ?? {};
      final rawAliases =
          collectionJson['aliases'] as Map<String, dynamic>? ?? {};

      // Try direct icon first
      if (rawIcons.containsKey(iconName)) {
        final iconJson = Map<String, dynamic>.from(
          rawIcons[iconName] as Map<String, dynamic>,
        );
        iconJson.putIfAbsent('width', () => defaultWidth);
        iconJson.putIfAbsent('height', () => defaultHeight);
        return IconifyIconData.fromJson(iconJson, sanitizer: sanitizer);
      }

      // Try alias resolution
      final icons = <String, IconifyIconData>{};
      for (final entry in rawIcons.entries) {
        final iconJson =
            Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
        iconJson.putIfAbsent('width', () => defaultWidth);
        iconJson.putIfAbsent('height', () => defaultHeight);
        icons[entry.key] =
            IconifyIconData.fromJson(iconJson, sanitizer: sanitizer);
      }

      final aliases = <String, AliasEntry>{};
      for (final entry in rawAliases.entries) {
        try {
          aliases[entry.key] = AliasEntry.fromJson(
            Map<String, dynamic>.from(entry.value as Map<String, dynamic>),
          );
        } catch (_) {}
      }

      return const AliasResolver().resolve(
        iconName: iconName,
        icons: icons,
        aliases: aliases,
        defaultWidth: defaultWidth,
        defaultHeight: defaultHeight,
      );
    } catch (e) {
      if (e is IconifyException) rethrow;
      throw IconifyParseException(
        message: 'Failed to extract icon "$iconName": $e',
      );
    }
  }
}

/// The result of parsing a complete Iconify collection JSON.
final class ParsedCollection {
  const ParsedCollection({
    required this.prefix,
    required this.info,
    required this.icons,
    required this.aliases,
    required this.defaultWidth,
    required this.defaultHeight,
  });

  final String prefix;
  final IconifyCollectionInfo info;
  final Map<String, IconifyIconData> icons;
  final Map<String, AliasEntry> aliases;
  final double defaultWidth;
  final double defaultHeight;

  /// Returns icon data for [iconName], resolving aliases if needed.
  IconifyIconData? getIcon(String iconName) {
    return const AliasResolver().resolve(
      iconName: iconName,
      icons: icons,
      aliases: aliases,
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
    );
  }

  /// All icon names, including aliases.
  Set<String> get allNames => {...icons.keys, ...aliases.keys};

  /// Number of real icons (not counting aliases).
  int get iconCount => icons.length;

  /// Number of aliases.
  int get aliasCount => aliases.length;
}
