/// Stub implementation of WebRendererDetector.
abstract final class WebRendererDetector {
  WebRendererDetector._();

  /// Always false on non-web platforms.
  static bool get isHtmlRenderer => false;

  /// Always false on non-web platforms.
  static bool get isCanvasKitRenderer => false;
}
