import 'package:meta/meta.dart';
import '../guard/svg_sanitizer.dart';

/// The data for a single Iconify icon.
///
/// The [body] contains either:
/// 1. The SVG path content WITHOUT the outer `<svg>` tag.
/// 2. A single character string (e.g. from an icon font) if [fontFamily] is set.
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
    this.fontFamily,
    this.raw = const {},
  });

  factory IconifyIconData.fromJson(Map<String, dynamic> json,
      {SvgSanitizer? sanitizer}) {
    final body = json['body'] as String;
    return IconifyIconData(
      body: (json['fontFamily'] == null && sanitizer != null)
          ? sanitizer.sanitize(body)
          : body,
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
      fontFamily: json['fontFamily'] as String?,
      raw: Map<String, dynamic>.from(json),
    );
  }

  /// SVG body content or font character.
  final String body;

  /// Viewbox width or natural size. Defaults to 24.
  final double width;

  /// Viewbox height or natural size. Defaults to 24.
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

  /// Optional font family for font-based rendering.
  final String? fontFamily;

  /// The original raw JSON data for this icon.
  final Map<String, dynamic> raw;

  /// Whether this icon supports color theming via `currentColor`.
  bool get isMonochrome => fontFamily != null || body.contains('currentColor');

  /// Whether the viewbox is square.
  bool get isSquare => width == height;

  /// Creates a complete SVG string ready for rendering.
  String toSvgString({double? size, String? color}) {
    if (fontFamily != null) {
      throw StateError('Cannot generate SVG string for font-based icon.');
    }
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
    String? fontFamily,
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
        fontFamily: fontFamily ?? this.fontFamily,
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
        if (fontFamily != null) 'fontFamily': fontFamily,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconifyIconData &&
          runtimeType == other.runtimeType &&
          body == other.body &&
          width == other.width &&
          height == other.height &&
          fontFamily == other.fontFamily;

  @override
  int get hashCode => Object.hash(body, width, height, fontFamily);

  @override
  String toString() =>
      'IconifyIconData(${width.toStringAsFixed(0)}x${height.toStringAsFixed(0)}, monochrome: $isMonochrome${fontFamily != null ? ', font: $fontFamily' : ''})';
}
