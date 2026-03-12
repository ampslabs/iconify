import 'package:iconify_sdk/src/registry/starter_registry.dart'
    show StarterRegistry;
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'iconify_config.dart';
import 'iconify_mode.dart';

/// Internal registry placeholder for the starter icons.
/// Concrete implementation in lib/src/registry/starter_registry.dart.
IconifyProvider? _starterProvider;

/// Sets the starter provider. Called by [StarterRegistry].
void setStarterProvider(IconifyProvider provider) {
  _starterProvider = provider;
}

/// Builds the default [IconifyProvider] chain based on configuration.
IconifyProvider buildProviderChain(IconifyConfig config) {
  final List<IconifyProvider> providers = [];

  // 1. User-provided custom providers (highest priority)
  providers.addAll(config.customProviders);

  // 2. In-memory cache (standard performance optimization)
  final memoryProvider = MemoryIconifyProvider();
  providers.add(memoryProvider);

  // 3. Mode-specific logic
  switch (config.mode) {
    case IconifyMode.auto:
      _addAutoModeProviders(providers, config);
    case IconifyMode.offline:
      _addOfflineModeProviders(providers);
    case IconifyMode.generated:
      _addGeneratedModeProviders(providers);
    case IconifyMode.remoteAllowed:
      _addRemoteAllowedModeProviders(providers, config);
  }

  // Wrap the entire chain in a CachingIconifyProvider for cross-provider caching
  return CachingIconifyProvider(
    inner: CompositeIconifyProvider(providers),
    cache: LruIconifyCache(maxEntries: config.cacheMaxEntries),
  );
}

void _addAutoModeProviders(
    List<IconifyProvider> providers, IconifyConfig config) {
  // Always include starter registry
  if (_starterProvider != null) {
    providers.add(_starterProvider!);
  }

  // Remote fallback (blocked in release by DevModeGuard unless opted-in)
  providers.add(RemoteIconifyProvider(
    apiBase: config.remoteApiBase,
  ));
}

void _addOfflineModeProviders(List<IconifyProvider> providers) {
  if (_starterProvider != null) {
    providers.add(_starterProvider!);
  }
  // NO remote provider added
}

void _addGeneratedModeProviders(List<IconifyProvider> providers) {
  // Only use what's explicitly provided in customProviders (where generated code will go)
  // or maybe we need a specific registry for generated icons.
  // For now, we assume generated icons are put into MemoryIconifyProvider
  // or passed via customProviders.
}

void _addRemoteAllowedModeProviders(
    List<IconifyProvider> providers, IconifyConfig config) {
  if (_starterProvider != null) {
    providers.add(_starterProvider!);
  }

  // Force allow remote fetching
  providers.add(RemoteIconifyProvider(
    apiBase: config.remoteApiBase,
    allowInRelease: true,
  ));
}
