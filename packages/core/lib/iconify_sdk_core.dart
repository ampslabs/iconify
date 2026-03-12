/// Pure Dart engine for Iconify icons.
///
/// Provides models, providers, cache, alias resolution, and JSON parsing.
/// No Flutter dependency required.
///
/// Quick start:
/// ```dart
/// import 'package:iconify_sdk_core/iconify_sdk_core.dart';
///
/// final name = IconifyName.parse('mdi:home');
/// final provider = RemoteIconifyProvider();
/// final icon = await provider.getIcon(name);
/// print(icon?.toSvgString());
/// ```
library;

// Cache
export 'src/cache/iconify_cache.dart';
export 'src/cache/lru_iconify_cache.dart';

// Errors
export 'src/errors/iconify_exception.dart';

// Guard
export 'src/guard/dev_mode_guard.dart';

// Models
export 'src/models/iconify_collection_info.dart';
export 'src/models/iconify_icon_data.dart';
export 'src/models/iconify_license.dart';
export 'src/models/iconify_name.dart';
export 'src/models/iconify_search_result.dart';

// Parser
export 'src/parser/iconify_json_parser.dart';

// Providers
export 'src/providers/asset_bundle_iconify_provider.dart';
export 'src/providers/caching_iconify_provider.dart';
export 'src/providers/composite_iconify_provider.dart';
export 'src/providers/file_system_iconify_provider.dart';
export 'src/providers/iconify_provider.dart';
export 'src/providers/memory_iconify_provider.dart';
export 'src/providers/remote_iconify_provider.dart';

// Resolver
export 'src/resolver/alias_resolver.dart';
