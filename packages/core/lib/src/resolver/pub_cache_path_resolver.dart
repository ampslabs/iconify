import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves the absolute path to a package within the current project.
///
/// This is used in development to find assets that are not registered in the
/// project's pubspec.yaml, effectively making them "dev-only" assets.
class PubCachePathResolver {
  PubCachePathResolver._();

  static final Map<String, String?> _cachedPaths = {};

  /// Resolves the absolute path to the [packageName] within the project's
  /// pub cache or workspace.
  ///
  /// Returns null if the package config cannot be found or the package is not
  /// present in the config (e.g., on Flutter Web).
  static Future<String?> resolvePackagePath(String packageName) async {
    if (_cachedPaths.containsKey(packageName)) return _cachedPaths[packageName];

    try {
      // 1. Locate .dart_tool/package_config.json
      Directory? current = Directory.current;
      File? configFile;

      // Limit search depth to prevent infinite loops in weird environments
      int depth = 0;
      while (current != null && depth < 20) {
        final possibleFile =
            File(p.join(current.path, '.dart_tool', 'package_config.json'));
        if (possibleFile.existsSync()) {
          configFile = possibleFile;
          break;
        }
        final parent = current.parent;
        if (parent.path == current.path) break;
        current = parent;
        depth++;
      }

      if (configFile == null) return null;

      // 2. Parse the config
      final content = await configFile.readAsString();
      final config = json.decode(content) as Map<String, dynamic>;
      final packages =
          (config['packages'] as List<dynamic>).cast<Map<String, dynamic>>();

      final packageInfo = packages.firstWhere(
        (pkg) => pkg['name'] == packageName,
        orElse: () => <String, dynamic>{},
      );

      if (packageInfo.isEmpty) {
        _cachedPaths[packageName] = null;
        return null;
      }

      final rootUri = packageInfo['rootUri'] as String;

      // 3. Convert URI to absolute path
      String? resolvedPath;
      if (rootUri.startsWith('file://')) {
        resolvedPath = Uri.parse(rootUri).toFilePath();
      } else {
        // Paths in package_config.json are relative to .dart_tool/ directory
        final configDir = configFile.parent.path;
        final absolutePath = p.normalize(p.join(configDir, rootUri));
        if (absolutePath.startsWith('file://')) {
          resolvedPath = Uri.parse(absolutePath).toFilePath();
        } else {
          resolvedPath = absolutePath;
        }
      }

      _cachedPaths[packageName] = resolvedPath;
      return resolvedPath;
    } catch (e) {
      return null;
    }
  }
}
