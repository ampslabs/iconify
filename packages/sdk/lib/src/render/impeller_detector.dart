import 'package:flutter/foundation.dart';

/// Detects whether the Impeller rendering backend is active.
///
/// This is used to trigger rasterization fallbacks for SVG features
/// (like color filters) that are currently buggy in Impeller.
abstract final class ImpellerDetector {
  ImpellerDetector._();

  static bool? _isImpellerEnabledCache;

  /// Returns true if Impeller is active on the current device.
  static bool get isImpellerActive {
    if (_isImpellerEnabledCache != null) return _isImpellerEnabledCache!;

    // 1. Check if we are on iOS (Impeller is default since 3.10)
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _isImpellerEnabledCache = true;
    } else {
      _isImpellerEnabledCache = false;
    }

    return _isImpellerEnabledCache!;
  }

  /// Manually override detection result (primarily for testing).
  @visibleForTesting
  static void setOverride(bool value) {
    _isImpellerEnabledCache = value;
  }

  /// Resets the override (primarily for testing).
  @visibleForTesting
  static void reset() {
    _isImpellerEnabledCache = null;
  }
}
