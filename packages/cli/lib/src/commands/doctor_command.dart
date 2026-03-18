import 'dart:convert';
import 'dart:io';

import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'base_command.dart';

class DoctorCommand extends BaseCommand {
  DoctorCommand({required super.logger});

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check the health of your Iconify setup.';

  @override
  Future<int> run() async {
    logger.info('🔍 Running Iconify Doctor...');

    final config = await ensureConfig();
    if (config == null) {
      logger.err('\n💔 Doctor found critical issues.');
      return ExitCode.config.code;
    }

    var hasIssues = false;
    var hasWarnings = false;

    logger.success('  ✅ iconify.yaml found.');

    // 2. Check Data Directory
    final dataDir = Directory(config.dataDir);
    if (!dataDir.existsSync()) {
      logger.err(
          '  ❌ data_dir "${config.dataDir}" not found. Run "iconify sync" to fix.');
      hasIssues = true;
    } else {
      logger.success('  ✅ data_dir found.');

      // 3. Check for specific snapshots
      final prefixes = config.sets.map((s) => s.split(':').first).toSet();
      for (final prefix in prefixes) {
        final file = File('${config.dataDir}/$prefix.json');
        if (!file.existsSync()) {
          logger.warn(
              '  ⚠️ Missing snapshot for "$prefix". Run "iconify sync" to download.');
          hasWarnings = true;
        } else {
          // 4. Check License / Attribution
          try {
            final jsonStr = await file.readAsString();
            final collection =
                IconifyJsonParser.parseCollectionString(jsonStr);
            if (collection.info.requiresAttribution) {
              logger.warn('  ⚠️ Collection "$prefix" requires attribution.');
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
        final cacheJson =
            jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
        final cachedIcons =
            (cacheJson['icons'] as Map<String, dynamic>? ?? {}).keys.toSet();

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
              logger.warn(
                  '  ⚠️ Found ${staleIcons.length} stale icons in used_icons.json. Run "iconify prune" to clean up.');
              hasWarnings = true;
            } else {
              logger.success(
                  '  ✅ used_icons.json is healthy (${cachedIcons.length} icons).');
            }
          }
        }
      } catch (_) {}
    }

    if (hasIssues) {
      logger.err('\n💔 Doctor found critical issues.');
      return ExitCode.software.code;
    }

    if (hasWarnings) {
      logger.warn('\n✨ Doctor found some warnings, but things should work.');
      return ExitCode.success.code;
    }

    logger.success('\n✔ Everything looks great!');
    return ExitCode.success.code;
  }
}
