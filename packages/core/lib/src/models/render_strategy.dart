/// Defines how icons should be rendered in the Flutter layer.
///
/// This enum lives in `core` so that providers and models can
/// communicate rendering requirements to the Flutter package.
enum RenderStrategy {
  /// Uses `SvgPicture.string` directly. Fastest and handles vectors natively.
  /// **Risk**: May render incorrectly on Impeller when `color` is applied.
  svgDirect,

  /// Renders the SVG to a `ui.Image` at the target device pixel ratio.
  /// Resolves Impeller rendering bugs by bypasssing the SVG color filter.
  rasterized,

  /// Automatically chooses the best strategy.
  /// Default: `svgDirect`, but falls back to `rasterized` if a color override
  /// is requested AND the device is using the Impeller renderer.
  auto,
}
