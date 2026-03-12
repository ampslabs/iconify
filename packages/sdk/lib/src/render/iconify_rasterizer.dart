import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Handles rasterization of SVG data to [ui.Image].
///
/// This is used as a fallback path for Impeller when color overrides
/// are requested, as direct SVG color filters are currently buggy.
final class IconifyRasterizer {
  IconifyRasterizer._();

  static final _cache = <String, ui.Image>{};

  /// Renders an SVG string to a [ui.Image].
  ///
  /// The resulting image is sized at [size] * [pixelRatio] to ensure
  /// it remains sharp on high-DPI displays.
  static Future<ui.Image> rasterize({
    required String svgString,
    required double size,
    required double pixelRatio,
    String? cacheKey,
  }) async {
    if (cacheKey != null && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final PictureInfo pictureInfo = await vg.loadPicture(
      SvgStringLoader(svgString),
      null,
    );

    final double dimension = size * pixelRatio;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    // Scale the canvas to match the target pixel density
    final double scale = dimension / pictureInfo.size.width;
    canvas.scale(scale);

    canvas.drawPicture(pictureInfo.picture);
    final ui.Image image = await recorder.endRecording().toImage(
          dimension.ceil(),
          dimension.ceil(),
        );

    if (cacheKey != null) {
      _cache[cacheKey] = image;
    }

    pictureInfo.picture.dispose();
    return image;
  }

  /// Clears the rasterization cache.
  static void clearCache() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }
}

/// A custom [ImageProvider] that serves rasterized Iconify icons.
class RasterizedIconifyImageProvider
    extends ImageProvider<RasterizedIconifyImageKey> {
  const RasterizedIconifyImageProvider({
    required this.svgString,
    required this.size,
    required this.pixelRatio,
    required this.cacheKey,
  });

  final String svgString;
  final double size;
  final double pixelRatio;
  final String cacheKey;

  @override
  Future<RasterizedIconifyImageKey> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<RasterizedIconifyImageKey>(
      RasterizedIconifyImageKey(cacheKey, pixelRatio),
    );
  }

  @override
  ImageStreamCompleter loadImage(
    RasterizedIconifyImageKey key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      _loadAsync(key),
    );
  }

  Future<ImageInfo> _loadAsync(RasterizedIconifyImageKey key) async {
    final ui.Image image = await IconifyRasterizer.rasterize(
      svgString: svgString,
      size: size,
      pixelRatio: pixelRatio,
      cacheKey: cacheKey,
    );
    return ImageInfo(image: image, scale: pixelRatio);
  }
}

@immutable
class RasterizedIconifyImageKey {
  const RasterizedIconifyImageKey(this.cacheKey, this.pixelRatio);
  final String cacheKey;
  final double pixelRatio;

  @override
  bool operator ==(Object other) =>
      other is RasterizedIconifyImageKey &&
      cacheKey == other.cacheKey &&
      pixelRatio == other.pixelRatio;

  @override
  int get hashCode => Object.hash(cacheKey, pixelRatio);
}
