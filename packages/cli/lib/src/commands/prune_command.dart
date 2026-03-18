import 'dart:convert';
import 'dart:io';

import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'base_command.dart';

class PruneCommand extends BaseCommand {
  PruneCommand({required super.logger}) {
    argParser.addFlag(
      'dry-run',
      abbr: 'd',
      help: 'Show what would be removed without modifying the file.',
      negatable: false,
    );
  }

  @override
  String get name => 'prune';

  @override
  String get description =>
      'Removes icons from used_icons.json that no longer appear in source code.';

  @override
  Future<int> run() async {
    final config = await ensureConfig();
    if (config == null) return ExitCode.config.code;

    final cachePath = p.join(config.dataDir, 'used_icons.json');
    final cacheFile = File(cachePath);

    if (!cacheFile.existsSync()) {
      logger.err('used_icons.json not found.');
      return ExitCode.noInput.code;
    }

    final progress = logger.progress('Scanning source code for used icons...');
    final usedIcons = <String>{};
    final libDir = Directory('lib');

    if (!libDir.existsSync()) {
      progress.fail('lib/ directory not found.');
      return ExitCode.noInput.code;
    }

    final entities = libDir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (entity.path.endsWith(config.output)) continue;
        final content = await entity.readAsString();
        final scanner = IconNameScanner()..scan(content);
        usedIcons.addAll(scanner.iconNames);
      }
    }

    progress.update('Reading used_icons.json...');
    final cacheJson =
        jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
    final iconsJson =
        Map<String, dynamic>.from(cacheJson['icons'] as Map? ?? {});

    final staleIcons = iconsJson.keys.where((k) => !usedIcons.contains(k)).toList();

    if (staleIcons.isEmpty) {
      progress.complete('No stale icons found.');
      return ExitCode.success.code;
    }

    progress.complete('Found ${staleIcons.length} stale icons.');

    for (final icon in staleIcons) {
      logger.info('  - $icon');
    }

    if (argResults?['dry-run'] == true) {
      logger.info('\nDry run: ${staleIcons.length} icons would be removed.');
      return ExitCode.success.code;
    }

    final confirm = logger.confirm('Remove these icons?', defaultValue: true);
    if (!confirm) return ExitCode.success.code;

    for (final icon in staleIcons) {
      iconsJson.remove(icon);
    }

    cacheJson['icons'] = iconsJson;
    cacheJson['generated'] = DateTime.now().toUtc().toIso8601String();

    await cacheFile
        .writeAsString(const JsonEncoder.withIndent('  ').convert(cacheJson));
    logger.success('✅ Cleaned up used_icons.json.');

    return ExitCode.success.code;
  }
}
