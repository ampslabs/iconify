import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

/// A widget that renders an SVG from [IconifyIconData] using [SvgPicture.string].
///
/// This leverages flutter_svg's internal caching while providing consistent
/// color and size handling for Iconify icons.
class CachedSvgIconifyWidget extends StatelessWidget {
  const CachedSvgIconifyWidget({
    required this.name,
    required this.data,
    super.key,
    this.size,
    this.color,
    this.opacity,
    this.semanticLabel,
  });

  final IconifyName name;
  final IconifyIconData data;
  final double? size;
  final Color? color;
  final double? opacity;
  final String? semanticLabel;

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().clamp(0, 255);
    final g = (color.g * 255).round().clamp(0, 255);
    final b = (color.b * 255).round().clamp(0, 255);
    final a = color.a;

    if (a == 1.0) {
      return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
    } else {
      return 'rgba($r, $g, $b, ${a.toStringAsFixed(3)})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double effectiveSize = size ?? data.width;

    return SvgPicture.string(
      data.toSvgString(
        color: color != null ? _colorToHex(color!) : null,
        size: effectiveSize,
      ),
      width: effectiveSize,
      height: effectiveSize,
      semanticsLabel: semanticLabel,
      // SvgPicture has its own internal cache, but we wrap it to ensure
      // the string generation is consistent.
    );
  }
}
