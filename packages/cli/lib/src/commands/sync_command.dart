import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:mason_logger/mason_logger.dart';

class SyncCommand extends Command<int> {
  SyncCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force re-download even if files exist and SHA matches.',
      negatable: false,
    );
    argParser.addFlag(
      'verify',
      help: 'Verify SHA-256 matches iconify.lock before overwriting.',
      defaultsTo: true,
    );
    argParser.addOption(
      'collections',
      abbr: 'c',
      help: 'Comma-separated list of collections to sync.',
    );
    argParser.addOption(
      'commit',
      help: 'Sync from a specific GitHub commit SHA.',
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

    final lockFile = File('iconify.lock');
    Map<String, dynamic> lockData = {};
    if (lockFile.existsSync()) {
      try {
        lockData =
            jsonDecode(await lockFile.readAsString()) as Map<String, dynamic>;
      } catch (e) {
        _logger.warn('Failed to parse iconify.lock: $e');
      }
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

    final client = http.Client();
    String commitRef = argResults?['commit'] as String? ?? 'master';

    // If not specified, try to fetch the latest commit SHA from GitHub API
    if (commitRef == 'master') {
      final progress = _logger.progress('Fetching latest commit SHA...');
      try {
        final response = await client.get(
          Uri.parse(
              'https://api.github.com/repos/iconify/icon-sets/commits/master'),
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'iconify_sdk_cli/0.2.0',
          },
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          commitRef = json['sha'] as String;
          progress.complete('Latest commit: ${commitRef.substring(0, 7)}');
        } else {
          progress.complete(
              'GitHub API failed (HTTP ${response.statusCode}). Falling back to "master".');
        }
      } catch (e) {
        progress.complete('GitHub API error: $e. Falling back to "master".');
      }
    }

    _logger.info(
        '🔄 Syncing ${prefixes.length} collections (ref: ${commitRef.substring(0, 7)}) to ${config.dataDir}...');

    final dataDir = Directory(config.dataDir);
    if (!dataDir.existsSync()) {
      dataDir.createSync(recursive: true);
    }

    var successCount = 0;

    try {
      for (final prefix in prefixes) {
        final progress = _logger.progress('Downloading $prefix...');

        final targetFile = File('${config.dataDir}/$prefix.json');
        final currentLock = lockData[prefix] as Map<String, dynamic>?;

        final uri = Uri.parse(
            'https://raw.githubusercontent.com/iconify/icon-sets/$commitRef/json/$prefix.json');

        try {
          final response = await client.get(uri);
          if (response.statusCode == 200) {
            final bodyBytes = response.bodyBytes;
            final newSha = sha256.convert(bodyBytes).toString();

            if (targetFile.existsSync() &&
                currentLock != null &&
                currentLock['sha256'] == newSha &&
                argResults?['force'] != true) {
              progress.complete('Skipped $prefix (SHA matches)');
              successCount++;
              continue;
            }

            // Verify SHA if requested and mismatch found
            if (argResults?['verify'] == true &&
                currentLock != null &&
                currentLock['sha256'] != newSha &&
                argResults?['force'] != true) {
              progress
                  .fail('SHA mismatch for $prefix! Use --force to overwrite.');
              _logger.info('  Lock: ${currentLock['sha256']}');
              _logger.info('  New:  $newSha');
              continue;
            }

            // Basic validation
            final json = jsonDecode(utf8.decode(bodyBytes));
            if (json is Map && json.containsKey('icons')) {
              await targetFile.writeAsBytes(bodyBytes);

              lockData[prefix] = {
                'sha256': newSha,
                'syncedAt': DateTime.now().toUtc().toIso8601String(),
                'commitRef': commitRef,
              };

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
      // Write updated lock file
      const encoder = JsonEncoder.withIndent('  ');
      await lockFile.writeAsString(encoder.convert(lockData));
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
