import 'package:flutter/foundation.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import '../config/provider_chain_builder.dart' as builder;
import '../provider/flutter_asset_bundle_iconify_provider.dart';
import '../widget/iconify_app.dart';

/// Manages the embedded starter icon registry.
///
/// This registry provides a small subset of popular icons from MDI, Lucide,
/// Tabler, and Heroicons, plus metadata for all 200+ collections.
class StarterRegistry {
  StarterRegistry._();

  static final StarterRegistry instance = StarterRegistry._();

  bool _initialized = false;
  late final FlutterAssetBundleIconifyProvider _provider;

  /// Initializes the starter registry and injects it into the provider chain.
  ///
  /// This is called automatically by [IconifyApp].
  void initialize() {
    if (_initialized) return;

    const prefix = 'packages/iconify_sdk/assets/iconify/starter';
    _provider = FlutterAssetBundleIconifyProvider(
      assetPrefix: prefix,
    );

    builder.setStarterProvider(_provider);
    _initialized = true;
    
    if (kDebugMode) {
      // Diagnostic logging for debugging.
      // ignore: avoid_print
      print('Iconify SDK: StarterRegistry initialized with prefix: $prefix');
    }
  }

  /// Returns the underlying provider for the starter icons.
  IconifyProvider get provider {
    if (!_initialized) initialize();
    return _provider;
  }
}
