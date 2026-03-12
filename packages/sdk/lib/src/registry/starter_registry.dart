import 'package:iconify_sdk/iconify_sdk.dart' show IconifyApp;
import 'package:iconify_sdk/src/widget/iconify_app.dart' show IconifyApp;
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import '../config/provider_chain_builder.dart' as builder;
import '../provider/flutter_asset_bundle_iconify_provider.dart';

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

    _provider = FlutterAssetBundleIconifyProvider(
      // The prefix matches the directory registered in pubspec.yaml
      assetPrefix: 'packages/iconify_sdk/assets/iconify/starter',
    );

    builder.setStarterProvider(_provider);
    _initialized = true;
  }

  /// Returns the underlying provider for the starter icons.
  IconifyProvider get provider {
    if (!_initialized) initialize();
    return _provider;
  }
}
