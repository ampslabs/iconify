import 'dart:js_interop';

@JS('window.flutterCanvasKit')
external JSAny? get _flutterCanvasKit;

/// Web implementation of WebRendererDetector.
abstract final class WebRendererDetector {
  WebRendererDetector._();

  /// Returns true if the app is running on Web with the HTML renderer.
  static bool get isHtmlRenderer {
    // If flutterCanvasKit is null, it's likely the HTML renderer.
    return _flutterCanvasKit == null;
  }

  /// Returns true if the app is running on Web with the CanvasKit renderer.
  static bool get isCanvasKitRenderer {
    return _flutterCanvasKit != null;
  }
}
