import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

abstract class BaseCommand extends Command<int> {
  BaseCommand({required this.logger});

  final Logger logger;

  /// Ensures iconify.yaml exists, otherwise prompts the user to initialize it.
  Future<IconifyBuildConfig?> ensureConfig() async {
    final configFile = File('iconify.yaml');
    if (!configFile.existsSync()) {
      logger.info('🚀 iconify.yaml not found.');
      final shouldInit = logger.confirm(
          'Would you like to initialize Iconify in this project?',
          defaultValue: true);
      if (!shouldInit) return null;

      await runInit();
    }

    try {
      return IconifyBuildConfig.fromYaml(await configFile.readAsString());
    } catch (e) {
      logger.err('Error parsing iconify.yaml: $e');
      return null;
    }
  }

  /// Runs the initialization logic.
  Future<void> runInit() async {
    logger.info('🚀 Initializing Iconify SDK...');

    final setsStr = logger.prompt(
      'Which icon sets would you like to start with? (comma separated)',
      defaultValue: 'mdi,lucide',
    );
    final sets = setsStr
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final dataDir = logger.prompt(
      'Where should local icon snapshots be stored?',
      defaultValue: 'assets/iconify',
    );

    final output = logger.prompt(
      'Where should the generated Dart code be written?',
      defaultValue: 'lib/icons.g.dart',
    );

    final yamlBuffer = StringBuffer();
    yamlBuffer.writeln('# Iconify SDK Configuration');
    yamlBuffer.writeln('# See docs at https://github.com/ampslabs/iconify');
    yamlBuffer.writeln();
    yamlBuffer.writeln('sets:');
    for (final s in sets) {
      yamlBuffer.writeln('  - $s:*');
    }
    yamlBuffer.writeln();
    yamlBuffer.writeln('data_dir: $dataDir');
    yamlBuffer.writeln('output: $output');
    yamlBuffer.writeln('mode: auto');
    yamlBuffer.writeln('license_policy: warn');
    yamlBuffer.writeln('fail_on_missing: false');

    await File('iconify.yaml').writeAsString(yamlBuffer.toString());

    final dir = Directory(dataDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final cachePath = p.join(dataDir, 'used_icons.json');
    final cacheFile = File(cachePath);
    if (!cacheFile.existsSync()) {
      await cacheFile.writeAsString(
        '{"schemaVersion": 1, "generated": "${DateTime.now().toUtc().toIso8601String()}", "icons": {}}',
      );
    }

    logger.success('✅ Created iconify.yaml');
  }

  /// Ensures specified [prefixes] are synced locally.
  Future<bool> ensureSynced(
      IconifyBuildConfig config, Set<String> prefixes) async {
    final missing = <String>[];
    for (final prefix in prefixes) {
      final file = File('${config.dataDir}/$prefix.json');
      if (!file.existsSync()) {
        missing.add(prefix);
      }
    }

    if (missing.isEmpty) return true;

    logger.info('📦 Missing snapshots for: ${missing.join(', ')}');
    final shouldSync =
        logger.confirm('Would you like to sync them now?', defaultValue: true);
    if (!shouldSync) return false;

    return runSync(config, prefixes: missing);
  }

  /// Runs the sync logic for specific [prefixes].
  Future<bool> runSync(IconifyBuildConfig config,
      {required List<String> prefixes}) async {
    final client = http.Client();
    final lockFile = File('iconify.lock');
    Map<String, dynamic> lockData = {};
    if (lockFile.existsSync()) {
      try {
        lockData =
            jsonDecode(await lockFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    }

    final progress =
        logger.progress('Syncing ${prefixes.length} collections...');
    var successCount = 0;

    try {
      for (final prefix in prefixes) {
        final uri = Uri.parse(
            'https://raw.githubusercontent.com/iconify/icon-sets/master/json/$prefix.json');

        try {
          final response = await client.get(uri);
          if (response.statusCode == 200) {
            final bodyBytes = response.bodyBytes;
            final targetFile = File('${config.dataDir}/$prefix.json');

            if (!targetFile.parent.existsSync()) {
              targetFile.parent.createSync(recursive: true);
            }

            await targetFile.writeAsBytes(bodyBytes);

            lockData[prefix] = {
              'sha256': sha256.convert(bodyBytes).toString(),
              'syncedAt': DateTime.now().toUtc().toIso8601String(),
              'commitRef': 'master',
            };
            successCount++;
          }
        } catch (_) {}
      }
    } finally {
      client.close();
      await lockFile
          .writeAsString(const JsonEncoder.withIndent('  ').convert(lockData));
    }

    if (successCount > 0) {
      progress.complete('Synced $successCount collections.');
    } else {
      progress.fail('Failed to sync collections.');
    }

    return successCount == prefixes.length;
  }
}
