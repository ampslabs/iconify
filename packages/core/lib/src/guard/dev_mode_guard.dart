/// Controls access to remote network operations based on build mode.
///
/// The Iconify public API is a community-funded service. This guard
/// prevents production apps from defaulting to remote API calls,
/// which would be both unreliable and an ethical burden on the service.
///
/// In debug and profile builds, remote calls are allowed by default.
/// In release builds, remote calls are BLOCKED by default.
///
/// To override this in release builds (e.g., for internal enterprise tools):
/// call [DevModeGuard.allowRemoteInRelease] during app initialization.
abstract final class DevModeGuard {
  DevModeGuard._();

  static bool _releaseOverride = false;

  /// Allows remote provider calls even in release builds.
  ///
  /// Call this during app initialization if your app requires remote
  /// icon loading in production. This is opt-in by design.
  ///
  /// **Note**: Consider self-hosting the Iconify API for production:
  /// https://github.com/iconify/api
  static void allowRemoteInRelease() {
    _releaseOverride = true;
  }

  /// Resets the release override (primarily for testing).
  static void resetOverride() {
    _releaseOverride = false;
  }

  /// Returns true if remote provider calls are allowed in the current build.
  ///
  /// - Debug build: always true
  /// - Profile build: always true
  /// - Release build: true only if [allowRemoteInRelease] was called
  static bool isRemoteAllowedInCurrentBuild() {
    if (_releaseOverride) return true;

    var isDebugOrProfile = false;
    // We use assert to detect if we are in a debug/profile build.
    // ignore: prefer_asserts_with_message, document_ignores
    assert(() {
      isDebugOrProfile = true;
      return true;
    }());
    return isDebugOrProfile;
  }
}
