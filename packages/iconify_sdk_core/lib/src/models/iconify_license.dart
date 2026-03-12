import 'package:meta/meta.dart';

/// License information for an icon collection.
///
/// IMPORTANT: Always check [requiresAttribution] before shipping icons
/// from a collection in a commercial app. Collections with
/// [requiresAttribution] = true require you to display attribution
/// to the icon author in your app or documentation.
@immutable
final class IconifyLicense {
  const IconifyLicense({
    this.title,
    this.spdx,
    this.url,
    this.requiresAttribution = false,
  });

  factory IconifyLicense.fromJson(Map<String, dynamic> json) => IconifyLicense(
        title: json['title'] as String?,
        spdx: json['spdx'] as String?,
        url: json['url'] as String?,
        requiresAttribution: json['requiresAttribution'] as bool? ?? false,
      );

  /// Human-readable license name, e.g., "MIT License", "Apache License 2.0".
  final String? title;

  /// SPDX identifier, e.g., "MIT", "Apache-2.0", "CC-BY-4.0".
  ///
  /// May be null if the license is not a standard SPDX-registered license.
  final String? spdx;

  /// URL pointing to the full license text.
  final String? url;

  /// Whether this license requires attribution in derivative works.
  ///
  /// If true, your app must display the icon author's attribution.
  /// Consult the full license at [url] for exact attribution requirements.
  final bool requiresAttribution;

  /// Known safe licenses that do not require attribution for commercial use.
  static const Set<String> _noAttributionRequired = {
    'MIT',
    'ISC',
    'Apache-2.0',
    '0BSD',
    'Unlicense',
    'CC0-1.0',
  };

  /// Whether this license is known to be safe for commercial use
  /// without attribution requirements.
  ///
  /// Returns `false` when [spdx] is null or not in the known-safe list.
  /// When `false`, read the license at [url] before use.
  bool get isKnownCommercialFriendly =>
      spdx != null && _noAttributionRequired.contains(spdx);

  /// Creates a copy with the given fields replaced.
  IconifyLicense copyWith({
    String? title,
    String? spdx,
    String? url,
    bool? requiresAttribution,
  }) =>
      IconifyLicense(
        title: title ?? this.title,
        spdx: spdx ?? this.spdx,
        url: url ?? this.url,
        requiresAttribution: requiresAttribution ?? this.requiresAttribution,
      );

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (spdx != null) 'spdx': spdx,
        if (url != null) 'url': url,
        'requiresAttribution': requiresAttribution,
      };

  @override
  bool operator ==(Object other) =>
      other is IconifyLicense &&
      title == other.title &&
      spdx == other.spdx &&
      url == other.url &&
      requiresAttribution == other.requiresAttribution;

  @override
  int get hashCode => Object.hash(title, spdx, url, requiresAttribution);

  @override
  String toString() =>
      'IconifyLicense(spdx: $spdx, requiresAttribution: $requiresAttribution)';
}
