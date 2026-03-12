import 'package:flutter/widgets.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'impeller_detector.dart';

/// Helper to resolve the effective [RenderStrategy] for an icon.
RenderStrategy resolveRenderStrategy({
  required RenderStrategy strategy,
  required Color? color,
}) {
  if (strategy != RenderStrategy.auto) return strategy;

  // Default to svgDirect, but fallback to rasterized for color + Impeller
  if (color != null && ImpellerDetector.isImpellerActive) {
    return RenderStrategy.rasterized;
  }

  return RenderStrategy.svgDirect;
}
