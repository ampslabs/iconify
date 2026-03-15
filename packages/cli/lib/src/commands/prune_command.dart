import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

class PruneCommand extends Command<int> {
  PruneCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'dry-run',
      help: 'Show what would be removed without modifying the file.',
      negatable: false,
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Skip confirmation and prune immediately.',
      negatable: false,
    );
  }

  @override
  String get name => 'prune';

  @override
  String get description =>
      'Removes icons from used_icons.json that no longer appear in source code.';

  final Logger _logger;

  @override
  Future<int> run() async {
    final configFile = File('iconify.yaml');
    if (!configFile.existsSync()) {
      _logger.err('iconify.yaml not found. Run "iconify init" first.');
      return ExitCode.config.code;
    }

    final IconifyBuildConfig config;
    try {
      config = IconifyBuildConfig.fromYaml(await configFile.readAsString());
    } catch (e) {
      _logger.err('Error parsing iconify.yaml: $e');
      return ExitCode.config.code;
    }

    final cachePath = p.join(config.dataDir, 'used_icons.json');
    final cacheFile = File(cachePath);

    if (!cacheFile.existsSync()) {
      _logger
          .info('used_icons.json not found at $cachePath. Nothing to prune.');
      return ExitCode.success.code;
    }

    final progress = _logger.progress('Scanning source code...');
    final usedIcons = <String>{};

    // 1. Scan lib/ directory
    final libDir = Directory('lib');
    if (!libDir.existsSync()) {
      progress.fail('Could not find lib/ directory.');
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

    final Map<String, dynamic> cacheJson;
    try {
      cacheJson =
          jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
    } catch (e) {
      progress.fail('Failed to parse used_icons.json: $e');
      return ExitCode.software.code;
    }

    final iconsJson = cacheJson['icons'] as Map<String, dynamic>? ?? {};
    final cachedIconNames = iconsJson.keys.toSet();

    // 2. Compute difference
    final staleIcons = cachedIconNames.difference(usedIcons);

    if (staleIcons.isEmpty) {
      progress.complete('No stale icons found. used_icons.json is up to date.');
      return ExitCode.success.code;
    }

    progress.complete('Found ${staleIcons.length} stale icons.');

    // 3. Report
    for (final icon in staleIcons) {
      _logger.info('  ${lightRed.wrap('-')} $icon');
    }

    if (argResults?['dry-run'] == true) {
      _logger.info('\nDry run: would remove ${staleIcons.length} icons.');
      return ExitCode.success.code;
    }

    // 4. Confirm and prune
    var shouldPrune = argResults?['force'] == true;
    if (!shouldPrune) {
      shouldPrune = _logger.confirm(
        'Remove these ${staleIcons.length} icons from used_icons.json?',
        defaultValue: true,
      );
    }

    if (shouldPrune) {
      final oldSize = cacheFile.lengthSync();

      // Remove stale icons
      for (final icon in staleIcons) {
        iconsJson.remove(icon);
      }

      // Update metadata
      cacheJson['generated'] = DateTime.now().toUtc().toIso8601String();

      final encoder = const JsonEncoder.withIndent('  ');
      await cacheFile.writeAsString(encoder.convert(cacheJson));

      final newSize = cacheFile.lengthSync();
      _logger.success(
        'Pruned ${staleIcons.length} icons. '
        'Size reduced from ${_formatSize(oldSize)} to ${_formatSize(newSize)}.',
      );
    } else {
      _logger.info('Pruning cancelled.');
    }

    return ExitCode.success.code;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
