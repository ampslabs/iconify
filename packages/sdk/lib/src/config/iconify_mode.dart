/// Defines the operational mode for icon resolution.
enum IconifyMode {
  /// **Default**. Frictionless development with production safety.
  /// - Debug/Profile: memory → starter registry → remote fallback.
  /// - Release: memory → generated code → starter registry. (Remote BLOCKED).
  auto,

  /// Strict offline mode.
  /// - Never makes network calls, regardless of build mode.
  /// - Only memory, starter registry, and generated code are used.
  offline,

  /// Strict generated mode.
  /// - Only uses icons found in the generated `icons.g.dart` file.
  /// - Fails if an icon is requested but not in the generated subset.
  /// - Useful for strictly minimizing bundle size.
  generated,

  /// Explicitly allow remote fetching in all build modes.
  /// - Primarily for internal enterprise tools or non-store apps.
  /// - **Ethical Note**: Use responsibly to avoid overloading the free API.
  remoteAllowed,
}
