import 'package:meta/meta.dart';
import 'iconify_license.dart';

/// Metadata for an Iconify icon collection (icon set).
@immutable
final class IconifyCollectionInfo {
  const IconifyCollectionInfo({
    required this.prefix,
    required this.name,
    required this.totalIcons,
    this.author,
    this.license,
    this.samples = const [],
    this.categories = const [],
    this.tags = const [],
    this.version,
    this.raw = const {},
  });

  factory IconifyCollectionInfo.fromJson(
      String prefix, Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>? ?? json;
    final licenseJson = info['license'] as Map<String, dynamic>?;

    return IconifyCollectionInfo(
      prefix: prefix,
      name: info['name'] as String? ?? prefix,
      totalIcons: info['total'] as int? ?? 0,
      author: _extractAuthor(info['author']),
      license:
          licenseJson != null ? IconifyLicense.fromJson(licenseJson) : null,
      samples: (info['samples'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      categories: (info['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      version: info['version'] as String?,
      raw: Map<String, dynamic>.from(info),
    );
  }

  /// The collection prefix, e.g., `mdi`, `lucide`.
  final String prefix;

  /// Human-readable name, e.g., "Material Design Icons".
  final String name;

  /// Total number of icons in this collection.
  final int totalIcons;

  /// Author name or URL.
  final String? author;

  /// License information. Check before use in commercial apps.
  final IconifyLicense? license;

  /// Sample icon names from this collection (for preview).
  final List<String> samples;

  /// Category names used to group icons in this collection.
  final List<String> categories;

  /// Search tags for this collection.
  final List<String> tags;

  /// Version string if the collection is versioned.
  final String? version;

  /// Original raw JSON data for this collection's info block.
  final Map<String, dynamic> raw;

  /// Whether attribution is required when using icons from this collection.
  bool get requiresAttribution => license?.requiresAttribution ?? false;

  /// Whether this collection is known safe for commercial use without attribution.
  bool get isKnownCommercialFriendly =>
      license?.isKnownCommercialFriendly ?? false;

  Map<String, dynamic> toJson() => {
        'prefix': prefix,
        'name': name,
        'totalIcons': totalIcons,
        if (author != null) 'author': author,
        if (license != null) 'license': license!.toJson(),
        if (samples.isNotEmpty) 'samples': samples,
        if (categories.isNotEmpty) 'categories': categories,
        if (version != null) 'version': version,
      };

  static String? _extractAuthor(dynamic author) {
    if (author == null) return null;
    if (author is String) return author;
    if (author is Map<String, dynamic>) {
      return author['name'] as String? ?? author['url'] as String?;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconifyCollectionInfo && prefix == other.prefix;

  @override
  int get hashCode => prefix.hashCode;

  @override
  String toString() =>
      'IconifyCollectionInfo($prefix: $name, $totalIcons icons)';
}
