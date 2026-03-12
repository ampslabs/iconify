import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import '../config/iconify_scope.dart';
import '../render/iconify_rasterizer.dart';
import '../render/render_resolver.dart';
import 'iconify_error_widget.dart';

/// A widget that renders an Iconify icon by its [prefix:name] identifier.
///
/// ```dart
/// IconifyIcon('mdi:home', size: 24, color: Colors.blue)
/// ```
class IconifyIcon extends StatefulWidget {
  /// Creates an icon from a [prefix:name] string.
  IconifyIcon(
    String identifier, {
    super.key,
    this.size,
    this.color,
    this.opacity,
    this.semanticLabel,
    this.renderStrategy = RenderStrategy.auto,
    this.errorBuilder,
    this.loadingBuilder,
  }) : name = IconifyName.parse(identifier);

  /// Creates an icon from a typed [IconifyName].
  const IconifyIcon.name(
    this.name, {
    super.key,
    this.size,
    this.color,
    this.opacity,
    this.semanticLabel,
    this.renderStrategy = RenderStrategy.auto,
    this.errorBuilder,
    this.loadingBuilder,
  });

  /// The unique identifier for the icon.
  final IconifyName name;

  /// The size of the icon in logical pixels.
  /// If null, defaults to the icon's natural size (usually 24).
  final double? size;

  /// The color to apply to the icon (monochrome icons only).
  final Color? color;

  /// The opacity to apply to the icon.
  final double? opacity;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// The rendering strategy to use.
  final RenderStrategy renderStrategy;

  /// Widget to show if icon loading fails.
  final Widget Function(BuildContext context, IconifyException error)?
      errorBuilder;

  /// Widget to show while the icon is loading.
  final Widget Function(BuildContext context)? loadingBuilder;

  @override
  State<IconifyIcon> createState() => _IconifyIconState();
}

class _IconifyIconState extends State<IconifyIcon> {
  Future<IconifyIconData?>? _iconFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveIcon();
  }

  @override
  void didUpdateWidget(IconifyIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.name != oldWidget.name) {
      _resolveIcon();
    }
  }

  void _resolveIcon() {
    final provider = IconifyScope.of(context);
    _iconFuture = provider.getIcon(widget.name);

    if (kDebugMode) {
      _iconFuture!.then((data) {
        if (data == null) {
          // Diagnostic logging for debugging.
          // ignore: avoid_print
          print('Iconify SDK: Icon not found: ${widget.name}');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IconifyIconData?>(
      future: _iconFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ??
              SizedBox(width: widget.size, height: widget.size);
        }

        if (snapshot.hasError) {
          final error = snapshot.error is IconifyException
              ? snapshot.error as IconifyException
              : IconifyParseException(message: snapshot.error.toString());
          return widget.errorBuilder?.call(context, error) ??
              IconifyErrorWidget(
                  name: widget.name, error: error, size: widget.size);
        }

        final data = snapshot.data;
        if (data == null) {
          final error = IconNotFoundException(
            name: widget.name,
            message: 'Icon not found in any provider.',
          );
          return widget.errorBuilder?.call(context, error) ??
              IconifyErrorWidget(
                  name: widget.name, error: error, size: widget.size);
        }

        return _buildIcon(context, data);
      },
    );
  }

  Widget _buildIcon(BuildContext context, IconifyIconData data) {
    final effectiveStrategy = resolveRenderStrategy(
      strategy: widget.renderStrategy,
      color: widget.color,
    );

    final double effectiveSize = widget.size ?? data.width;

    if (effectiveStrategy == RenderStrategy.rasterized) {
      final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
      final cacheKey =
          '${widget.name}:${widget.color?.toARGB32()}:$effectiveSize:$pixelRatio';

      return Image(
        image: RasterizedIconifyImageProvider(
          svgString: data.toSvgString(
            color: widget.color != null ? _colorToHex(widget.color!) : null,
          ),
          size: effectiveSize,
          pixelRatio: pixelRatio,
          cacheKey: cacheKey,
        ),
        width: effectiveSize,
        height: effectiveSize,
        opacity: widget.opacity != null
            ? AlwaysStoppedAnimation(widget.opacity!)
            : null,
        semanticLabel: widget.semanticLabel,
      );
    }

    // Default: svgDirect
    return SvgPicture.string(
      data.toSvgString(
        color: widget.color != null ? _colorToHex(widget.color!) : null,
      ),
      width: effectiveSize,
      height: effectiveSize,
      semanticsLabel: widget.semanticLabel,
    );
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
