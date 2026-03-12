import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] that tries a list of providers in order.
///
/// Returns the first non-null result from any provider.
/// If all providers return null, returns null.
///
/// Errors from individual providers are NOT silenced — if a provider
/// throws, the composite throws too. Use `CachingIconifyProvider` or
/// your own wrapper to handle per-provider errors gracefully.
///
/// Resolution order: providers are tried in the order they are provided.
/// The first provider to return a non-null result wins.
///
/// ```dart
/// final provider = CompositeIconifyProvider([
///   generatedProvider,    // fastest — checked first
///   assetBundleProvider,  // local assets — checked second
///   cachingHttpProvider,  // remote with cache — checked last
/// ]);
/// ```
final class CompositeIconifyProvider implements IconifyProvider {
  CompositeIconifyProvider(this.providers) : assert(providers.isNotEmpty);

  final List<IconifyProvider> providers;

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    for (final provider in providers) {
      final result = await provider.getIcon(name);
      if (result != null) return result;
    }
    return null;
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    for (final provider in providers) {
      final result = await provider.getCollection(prefix);
      if (result != null) return result;
    }
    return null;
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    for (final provider in providers) {
      if (await provider.hasIcon(name)) return true;
    }
    return false;
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    for (final provider in providers) {
      if (await provider.hasCollection(prefix)) return true;
    }
    return false;
  }

  @override
  Future<void> dispose() async {
    for (final provider in providers) {
      await provider.dispose();
    }
  }
}
