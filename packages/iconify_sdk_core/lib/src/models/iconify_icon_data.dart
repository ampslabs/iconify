import 'package:meta/meta.dart';

/// The data for a single Iconify icon.
///
/// The [body] contains the SVG path content WITHOUT the outer `<svg>` tag.
/// To render this icon, wrap the body in:
/// ```xml
/// <svg xmlns="http://www.w3.org/2000/svg"
///      viewBox="0 0 {width} {height}"
///      width="{size}" height="{size}">
///   {body}
/// </svg>
/// ```
///
/// If the [body] contains `currentColor`, the icon is monotone and supports
/// color theming. If it does not, it is a multicolor icon and color overrides
/// should not be applied without explicit user consent.
@immutable
final class IconifyIconData {
  const IconifyIconData({
    required this.body,
    this.width = 24,
    this.height = 24,
    this.aliases = const [],
    this.hidden = false,
    this.rotate = 0,
    this.hFlip = false,
    this.vFlip = false,
    this.raw = const {},
  });

  factory IconifyIconData.fromJson(Map<String, dynamic> json) {
    return IconifyIconData(
      body: json['body'] as String,
      width: (json['width'] as num?)?.toDouble() ?? 24.0,
      height: (json['height'] as num?)?.toDouble() ?? 24.0,
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hidden: json['hidden'] as bool? ?? false,
      rotate: json['rotate'] as int? ?? 0,
      hFlip: json['hFlip'] as bool? ?? false,
      vFlip: json['vFlip'] as bool? ?? false,
      raw: Map<String, dynamic>.from(json),
    );
  }

  /// SVG body content (everything inside the `<svg>` tag).
  final String body;

  /// Viewbox width. Defaults to 24 (the Iconify standard).
  final double width;

  /// Viewbox height. Defaults to 24 (the Iconify standard).
  final double height;

  /// Alias names for this icon within the same collection.
  final List<String> aliases;

  /// Whether this icon is hidden/deprecated in the upstream collection.
  final bool hidden;

  /// Rotation: 0, 1 (90°), 2 (180°), 3 (270°).
  final int rotate;

  /// Whether the icon should be flipped horizontally.
  final bool hFlip;

  /// Whether the icon should be flipped vertically.
  final bool vFlip;

  /// The original raw JSON data for this icon, preserved for debugging
  /// and advanced use cases. All values are JSON-safe types.
  final Map<String, dynamic> raw;

  /// Whether this icon supports color theming via `currentColor`.
  ///
  /// Monotone icons use `currentColor` for fill/stroke and can be
  /// recolored freely. Multicolor icons should not be recolored.
  bool get isMonochrome => body.contains('currentColor');

  /// Whether the viewbox is square.
  bool get isSquare => width == height;

  /// Creates a complete SVG string ready for rendering.
  ///
  /// [size] sets both width and height attributes. If null, uses
  /// the icon's natural [width] and [height].
  /// [color] replaces `currentColor` in the body (monotone icons only).
  String toSvgString({double? size, String? color}) {
    final w = size ?? width;
    final h = size ?? height;
    var svgBody = body;
    if (color != null && isMonochrome) {
      svgBody = svgBody.replaceAll('currentColor', color);
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 $width $height" '
        'width="$w" height="$h">'
        '$svgBody'
        '</svg>';
  }

  IconifyIconData copyWith({
    String? body,
    double? width,
    double? height,
    List<String>? aliases,
    bool? hidden,
    int? rotate,
    bool? hFlip,
    bool? vFlip,
    Map<String, dynamic>? raw,
  }) =>
      IconifyIconData(
        body: body ?? this.body,
        width: width ?? this.width,
        height: height ?? this.height,
        aliases: aliases ?? this.aliases,
        hidden: hidden ?? this.hidden,
        rotate: rotate ?? this.rotate,
        hFlip: hFlip ?? this.hFlip,
        vFlip: vFlip ?? this.vFlip,
        raw: raw ?? this.raw,
      );

  Map<String, dynamic> toJson() => {
        'body': body,
        'width': width,
        'height': height,
        if (aliases.isNotEmpty) 'aliases': aliases,
        if (hidden) 'hidden': hidden,
        if (rotate != 0) 'rotate': rotate,
        if (hFlip) 'hFlip': hFlip,
        if (vFlip) 'vFlip': vFlip,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconifyIconData &&
          runtimeType == other.runtimeType &&
          body == other.body &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(body, width, height);

  @override
  String toString() =>
      'IconifyIconData(${width.toStringAsFixed(0)}x${height.toStringAsFixed(0)}, monotone: $isMonochrome)';
}
