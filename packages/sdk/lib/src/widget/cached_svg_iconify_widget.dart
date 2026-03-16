import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import '../render/picture_cache.dart';

/// A widget that renders an SVG from [IconifyIconData] using [IconifyPictureCache].
///
/// This decouples the icon data from the [Picture] lifecycle, ensuring that
/// expensive SVG parsing only happens once per (name, color, size) combination.
class CachedSvgIconifyWidget extends StatefulWidget {
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

  @override
  State<CachedSvgIconifyWidget> createState() => _CachedSvgIconifyWidgetState();
}

class _CachedSvgIconifyWidgetState extends State<CachedSvgIconifyWidget> {
  PictureInfo? _pictureInfo;
  late PictureCacheKey _cacheKey;

  @override
  void initState() {
    super.initState();
    _resolvePicture();
  }

  @override
  void didUpdateWidget(CachedSvgIconifyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.name != oldWidget.name ||
        widget.size != oldWidget.size ||
        widget.color != oldWidget.color ||
        widget.data != oldWidget.data) {
      _resolvePicture();
    }
  }

  void _resolvePicture() {
    final double effectiveSize = widget.size ?? widget.data.width;
    _cacheKey = PictureCacheKey(
      name: widget.name,
      size: effectiveSize,
      color: widget.color?.toARGB32(),
    );

    final cached = IconifyPictureCache.instance.get(_cacheKey.toString());
    if (cached != null) {
      setState(() {
        _pictureInfo = cached;
      });
      return;
    }

    // Not in cache, load and parse
    final svgString = widget.data.toSvgString(
      color: widget.color != null ? _colorToHex(widget.color!) : null,
      size: effectiveSize,
    );

    vg.loadPicture(SvgStringLoader(svgString), null).then((info) {
      if (mounted) {
        IconifyPictureCache.instance.put(_cacheKey.toString(), info);
        setState(() {
          _pictureInfo = info;
        });
      } else {
        // We don't dispose here if not mounted because it might have been
        // put into cache by another widget in the meantime?
        // Actually IconifyPictureCache handles disposal on eviction.
      }
    });
  }

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
    final double effectiveSize = widget.size ?? widget.data.width;

    if (_pictureInfo == null) {
      return SizedBox(width: effectiveSize, height: effectiveSize);
    }

    Widget child = SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox.fromSize(
          size: _pictureInfo!.size,
          child: _PictureWidget(info: _pictureInfo!),
        ),
      ),
    );

    if (widget.opacity != null) {
      child = Opacity(opacity: widget.opacity!, child: child);
    }

    if (widget.semanticLabel != null) {
      child = Semantics(
        label: widget.semanticLabel,
        child: child,
      );
    }

    return child;
  }
}

class _PictureWidget extends StatelessWidget {
  const _PictureWidget({required this.info});

  final PictureInfo info;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PicturePainter(info.picture),
    );
  }
}

class _PicturePainter extends CustomPainter {
  const _PicturePainter(this.picture);

  final Picture picture;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(covariant _PicturePainter oldDelegate) {
    return oldDelegate.picture != picture;
  }
}
