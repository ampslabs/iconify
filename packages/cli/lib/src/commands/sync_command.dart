import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:mason_logger/mason_logger.dart';

class SyncCommand extends Command<int> {
  SyncCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force re-download even if files exist.',
      negatable: false,
    );
    argParser.addOption(
      'collections',
      abbr: 'c',
      help: 'Comma-separated list of collections to sync.',
    );
  }

  @override
  String get name => 'sync';

  @override
  String get description => 'Sync icon collections from GitHub raw source.';

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

    final Set<String> prefixes = {};

    // Determine which collections to sync
    final collectionsOverride = argResults?['collections'] as String?;
    if (collectionsOverride != null) {
      prefixes.addAll(collectionsOverride.split(',').map((s) => s.trim()));
    } else {
      for (final set in config.sets) {
        final prefix = set.split(':').first;
        prefixes.add(prefix);
      }
    }

    if (prefixes.isEmpty) {
      _logger.warn(
          'No collections configured to sync. Add them to iconify.yaml under "sets:".');
      return ExitCode.success.code;
    }

    _logger.info(
        '🔄 Syncing ${prefixes.length} collections to ${config.dataDir}...');

    final dataDir = Directory(config.dataDir);
    if (!dataDir.existsSync()) {
      dataDir.createSync(recursive: true);
    }

    final client = http.Client();
    var successCount = 0;

    try {
      for (final prefix in prefixes) {
        final progress = _logger.progress('Downloading $prefix...');

        final targetFile = File('${config.dataDir}/$prefix.json');
        if (targetFile.existsSync() && argResults?['force'] != true) {
          progress.complete('Skipped $prefix (already exists)');
          successCount++;
          continue;
        }

        final uri = Uri.parse(
            'https://raw.githubusercontent.com/iconify/icon-sets/master/json/$prefix.json');

        try {
          final response = await client.get(uri);
          if (response.statusCode == 200) {
            // Basic validation
            final json = jsonDecode(response.body);
            if (json is Map && json.containsKey('icons')) {
              await targetFile.writeAsString(response.body);
              progress.complete('Synced $prefix');
              successCount++;
            } else {
              progress.fail('Invalid JSON format for $prefix');
            }
          } else {
            progress.fail(
                'Failed to download $prefix: HTTP ${response.statusCode}');
          }
        } catch (e) {
          progress.fail('Error syncing $prefix: $e');
        }
      }
    } finally {
      client.close();
    }

    if (successCount == prefixes.length) {
      _logger.success('✅ All collections synchronized successfully.');
    } else {
      _logger.warn(
          '⚠️ Synchronized $successCount / ${prefixes.length} collections.');
    }

    return ExitCode.success.code;
  }
}
