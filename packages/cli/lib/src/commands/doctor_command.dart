import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

class DoctorCommand extends Command<int> {
  DoctorCommand({required Logger logger}) : _logger = logger;

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check the health of your Iconify setup.';

  final Logger _logger;

  @override
  Future<int> run() async {
    _logger.info('🔍 Running Iconify Doctor...');
    var hasIssues = false;
    var hasWarnings = false;

    // 1. Check Config
    final configFile = File('iconify.yaml');
    if (!configFile.existsSync()) {
      _logger.err('  ❌ iconify.yaml not found. Run "iconify init" to fix.');
      hasIssues = true;
    } else {
      _logger.success('  ✅ iconify.yaml found.');

      try {
        final config =
            IconifyBuildConfig.fromYaml(await configFile.readAsString());

        // 2. Check Data Directory
        final dataDir = Directory(config.dataDir);
        if (!dataDir.existsSync()) {
          _logger.err(
              '  ❌ data_dir "${config.dataDir}" not found. Run "iconify sync" to fix.');
          hasIssues = true;
        } else {
          _logger.success('  ✅ data_dir found.');

          // 3. Check for specific snapshots
          final prefixes = config.sets.map((s) => s.split(':').first).toSet();
          for (final prefix in prefixes) {
            final file = File('${config.dataDir}/$prefix.json');
            if (!file.existsSync()) {
              _logger.warn(
                  '  ⚠️ Missing snapshot for "$prefix". Run "iconify sync" to download.');
              hasWarnings = true;
            } else {
              // 4. Check License / Attribution
              try {
                final jsonStr = await file.readAsString();
                final collection =
                    IconifyJsonParser.parseCollectionString(jsonStr);
                if (collection.info.requiresAttribution) {
                  _logger
                      .warn('  ⚠️ Collection "$prefix" requires attribution.');
                  hasWarnings = true;
                }
              } catch (_) {}
            }
          }
        }

        // 5. Check Living Cache (used_icons.json)
        final cachePath = p.join(config.dataDir, 'used_icons.json');
        final cacheFile = File(cachePath);
        if (cacheFile.existsSync()) {
          try {
            final cacheJson = jsonDecode(await cacheFile.readAsString())
                as Map<String, dynamic>;
            final cachedIcons =
                (cacheJson['icons'] as Map<String, dynamic>? ?? {})
                    .keys
                    .toSet();

            if (cachedIcons.isNotEmpty) {
              // Quick scan for stale icons
              final usedIcons = <String>{};
              final libDir = Directory('lib');
              if (libDir.existsSync()) {
                final entities = libDir.listSync(recursive: true);
                for (final entity in entities) {
                  if (entity is File && entity.path.endsWith('.dart')) {
                    if (entity.path.endsWith(config.output)) continue;
                    final content = await entity.readAsString();
                    final scanner = IconNameScanner()..scan(content);
                    usedIcons.addAll(scanner.iconNames);
                  }
                }

                final staleIcons = cachedIcons.difference(usedIcons);
                if (staleIcons.isNotEmpty) {
                  _logger.warn(
                      '  ⚠️ Found ${staleIcons.length} stale icons in used_icons.json. Run "iconify prune" to clean up.');
                  hasWarnings = true;
                } else {
                  _logger.success(
                      '  ✅ used_icons.json is healthy (${cachedIcons.length} icons).');
                }
              }
            }
          } catch (_) {}
        }
      } catch (e) {
        _logger.err('  ❌ Failed to parse iconify.yaml: $e');
        hasIssues = true;
      }
    }

    if (hasIssues) {
      _logger.err('\n💔 Doctor found critical issues.');
      return ExitCode.software.code;
    }

    if (hasWarnings) {
      _logger.warn('\n✨ Doctor found some warnings, but things should work.');
      return ExitCode.success.code;
    }

    _logger.success('\n✔ Everything looks great!');
    return ExitCode.success.code;
  }
}
