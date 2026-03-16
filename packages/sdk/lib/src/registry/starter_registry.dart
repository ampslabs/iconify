import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart'
    show
        BinaryIconifyProvider,
        FileSystemIconifyProvider,
        IconifyProvider,
        PubCachePathResolver;
import 'package:path/path.dart' as p;

import '../config/provider_chain_builder.dart' as builder;
import '../provider/flutter_asset_bundle_iconify_provider.dart';
import '../widget/iconify_app.dart' show IconifyApp;

/// Manages the embedded starter icon registry.
///
/// This registry provides a small subset of popular icons from MDI, Lucide,
/// Tabler, and Heroicons, plus metadata for all 200+ collections.
class StarterRegistry {
  StarterRegistry._();

  static final StarterRegistry instance = StarterRegistry._();

  bool _initialized = false;
  IconifyProvider? _provider;

  /// Initializes the starter registry and injects it into the provider chain.
  ///
  /// This is called automatically by [IconifyApp].
  Future<void> initialize({List<String> preloadPrefixes = const []}) async {
    if (_initialized) return;

    if (kDebugMode && !kIsWeb) {
      // In development (non-web), we resolve the physical path to the package
      // to avoid bundling the starter icons as Flutter assets.
      try {
        final packagePath =
            await PubCachePathResolver.resolvePackagePath('iconify_sdk')
                .timeout(const Duration(seconds: 2));
        if (packagePath != null) {
          final starterPath =
              p.join(packagePath, 'assets', 'iconify', 'starter');

          // Check for binary format first (with compression support)
          final binExists = Directory(starterPath).listSync().any((e) =>
              e.path.endsWith('.iconbin') || e.path.endsWith('.iconbin.gz'));

          if (binExists) {
            _provider = BinaryIconifyProvider(
              root: starterPath,
              preloadPrefixes: preloadPrefixes,
            );
          } else {
            _provider = FileSystemIconifyProvider(
              root: starterPath,
              preloadPrefixes: preloadPrefixes,
            );
          }
        }
      } catch (e) {
        // Fallback to asset bundle if resolver fails
      }
    }

    if (_provider == null) {
      // Fallback for Release mode or Web: Use the bundled assets.
      const prefix = 'packages/iconify_sdk/assets/iconify/starter';
      // AssetBundleIconifyProvider also needs to support compression
      _provider = FlutterAssetBundleIconifyProvider(
        assetPrefix: prefix,
      );
    }

    builder.setStarterProvider(_provider!);
    _initialized = true;
  }

  /// Returns the underlying provider for the starter icons.
  IconifyProvider get provider {
    if (!_initialized) {
      if (_provider == null) {
        const prefix = 'packages/iconify_sdk/assets/iconify/starter';
        _provider = FlutterAssetBundleIconifyProvider(
          assetPrefix: prefix,
        );
      }
    }
    return _provider!;
  }
}
