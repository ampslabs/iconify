/// The Flutter package for Iconify icons.
///
/// This package provides the [IconifyIcon] widget, which allows you to render
/// any icon from over 200 open-source icon sets with a single widget.
///
/// Quick start:
/// ```dart
/// void main() {
///   runApp(
///     const IconifyApp(
///       child: MaterialApp(
///         home: Scaffold(
///           body: Center(
///             child: IconifyIcon('mdi:home'),
///           ),
///         ),
///       ),
///     ),
///   );
/// }
/// ```
library;

import 'src/widget/iconify_icon.dart';

// Core re-exports for convenience
export 'package:iconify_sdk_core/iconify_sdk_core.dart'
    show
        IconifyName,
        IconifyIconData,
        IconifyCollectionInfo,
        IconifyLicense,
        IconifyException,
        InvalidIconNameException,
        IconNotFoundException,
        CollectionNotFoundException,
        IconifyNetworkException,
        IconifyParseException,
        CircularAliasException,
        IconifyCacheException,
        RenderStrategy,
        IconifyProvider,
        MemoryIconifyProvider,
        RemoteIconifyProvider,
        LivingCacheProvider,
        LivingCacheStorage,
        FileSystemLivingCacheStorage;

// Configuration
export 'src/config/iconify_config.dart';
export 'src/config/iconify_mode.dart';
export 'src/config/iconify_scope.dart';

// Providers (Flutter specific)
export 'src/provider/asset_bundle_living_cache_storage.dart';
export 'src/provider/flutter_asset_bundle_iconify_provider.dart';

// Widgets
export 'src/widget/iconify_app.dart';
export 'src/widget/iconify_error_widget.dart';
export 'src/widget/iconify_icon.dart';
