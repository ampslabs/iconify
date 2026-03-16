import 'package:flutter/foundation.dart';
import 'package:iconify_sdk/src/provider/asset_bundle_living_cache_storage.dart';
import 'package:iconify_sdk/src/provider/sprite_iconify_provider.dart';
import 'package:iconify_sdk/src/registry/starter_registry.dart'
    show StarterRegistry;
import 'package:iconify_sdk/src/render/web_renderer_detector.dart';
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
///
/// Note: This is synchronous but some internal providers (like LivingCache)
/// load their data asynchronously on first use.
IconifyProvider buildProviderChain(IconifyConfig config) {
  final List<IconifyProvider> providers = [];

  // 1. User-provided custom providers (highest priority)
  providers.addAll(config.customProviders);

  // 2. Sprite Provider (Web HTML optimized)
  // This is highest priority for Web HTML because individual SVG rendering is slow.
  if (WebRendererDetector.isHtmlRenderer) {
    providers.add(SpriteIconifyProvider());
  }

  // 3. Living Cache (L2) - Optimization for production bundle size
  // and development write-back.
  final livingCache = _createLivingCacheProvider();
  providers.add(livingCache);

  // 3. In-memory cache (standard performance optimization)
  final memoryProvider = MemoryIconifyProvider();
  providers.add(memoryProvider);

  // 4. Mode-specific logic
  switch (config.mode) {
    case IconifyMode.auto:
      _addAutoModeProviders(providers, config, livingCache);
    case IconifyMode.offline:
      _addOfflineModeProviders(providers, livingCache);
    case IconifyMode.generated:
      _addGeneratedModeProviders(providers);
    case IconifyMode.remoteAllowed:
      _addRemoteAllowedModeProviders(providers, config, livingCache);
  }

  // Wrap the entire chain in a CachingIconifyProvider for cross-provider caching
  return CachingIconifyProvider(
    inner: CompositeIconifyProvider(providers),
    cache: LruIconifyCache(maxEntries: config.cacheMaxEntries),
  );
}

LivingCacheProvider _createLivingCacheProvider() {
  LivingCacheStorage storage;

  if (kDebugMode && !kIsWeb) {
    // In development, we use FileSystem storage to allow write-back.
    // We point it to the project's local assets directory.
    storage = FileSystemLivingCacheStorage(
      path: 'assets/iconify/used_icons.json',
    );
  } else {
    // In Release or Web, we use the read-only AssetBundle storage.
    // This file MUST be registered in the project's pubspec.yaml assets.
    storage = AssetBundleLivingCacheStorage();
  }

  return LivingCacheProvider(storage: storage);
}

void _addAutoModeProviders(List<IconifyProvider> providers,
    IconifyConfig config, LivingCacheProvider livingCache) {
  if (kDebugMode || kIsWeb) {
    // Development/Web: Include starter registry and remote fallback
    if (_starterProvider != null) {
      providers.add(_starterProvider!);
    }

    providers.add(RemoteIconifyProvider(
      apiBase: config.remoteApiBase,
      livingCache: livingCache,
      writeBackEnabled: kDebugMode,
    ));
  } else {
    // Release mode: Starter and Remote are ELIMINATED.
    // Icons must be in LivingCache or Generated.
  }
}

void _addOfflineModeProviders(
    List<IconifyProvider> providers, LivingCacheProvider livingCache) {
  if (kDebugMode || kIsWeb) {
    if (_starterProvider != null) {
      providers.add(_starterProvider!);
    }
  }
  // NO remote provider added
}

void _addGeneratedModeProviders(List<IconifyProvider> providers) {
  // Generated mode only uses generated icons
}

void _addRemoteAllowedModeProviders(List<IconifyProvider> providers,
    IconifyConfig config, LivingCacheProvider livingCache) {
  if (kDebugMode || kIsWeb) {
    if (_starterProvider != null) {
      providers.add(_starterProvider!);
    }
  }

  // Force allow remote fetching
  providers.add(RemoteIconifyProvider(
    apiBase: config.remoteApiBase,
    allowInRelease: true,
    livingCache: livingCache,
    writeBackEnabled: kDebugMode,
  ));
}
