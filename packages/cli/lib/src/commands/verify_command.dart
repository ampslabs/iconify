import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:mason_logger/mason_logger.dart';

class VerifyCommand extends Command<int> {
  VerifyCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'collections',
      abbr: 'c',
      help: 'Comma-separated list of collections to verify.',
    );
  }

  @override
  String get name => 'verify';

  @override
  String get description =>
      'Verify local icon collections against upstream SHA-256 in iconify.lock.';

  final Logger _logger;

  @override
  Future<int> run() async {
    final lockFile = File('iconify.lock');
    if (!lockFile.existsSync()) {
      _logger.err('iconify.lock not found. Run "iconify sync" first.');
      return ExitCode.config.code;
    }

    final Map<String, dynamic> lockData;
    try {
      lockData =
          jsonDecode(await lockFile.readAsString()) as Map<String, dynamic>;
    } catch (e) {
      _logger.err('Error parsing iconify.lock: $e');
      return ExitCode.config.code;
    }

    final configFile = File('iconify.yaml');
    if (!configFile.existsSync()) {
      _logger.err('iconify.yaml not found. Run "iconify init" first.');
      return ExitCode.config.code;
    }

    try {
      IconifyBuildConfig.fromYaml(await configFile.readAsString());
    } catch (e) {
      _logger.err('Error parsing iconify.yaml: $e');
      return ExitCode.config.code;
    }

    final Set<String> prefixes = {};
    final collectionsOverride = argResults?['collections'] as String?;
    if (collectionsOverride != null) {
      prefixes.addAll(collectionsOverride.split(',').map((s) => s.trim()));
    } else {
      prefixes.addAll(lockData.keys);
    }

    if (prefixes.isEmpty) {
      _logger.warn('No collections to verify.');
      return ExitCode.success.code;
    }

    final client = http.Client();
    String latestCommit = 'master';

    final progressSha = _logger.progress('Fetching latest commit SHA...');
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
        latestCommit = json['sha'] as String;
        progressSha.complete('Latest commit: ${latestCommit.substring(0, 7)}');
      } else {
        progressSha.complete(
            'GitHub API failed (HTTP ${response.statusCode}). Falling back to "master".');
      }
    } catch (e) {
      progressSha.complete('GitHub API error: $e. Falling back to "master".');
    }

    _logger.info(
        '🔍 Verifying ${prefixes.length} collections against upstream (ref: ${latestCommit.substring(0, 7)})...');

    var mismatchCount = 0;
    var errorCount = 0;

    try {
      for (final prefix in prefixes) {
        final progress = _logger.progress('Verifying $prefix...');

        final currentLock = lockData[prefix] as Map<String, dynamic>?;
        if (currentLock == null) {
          progress.fail(
              'No lock data found for $prefix. Run "iconify sync" first.');
          errorCount++;
          continue;
        }

        final uri = Uri.parse(
            'https://raw.githubusercontent.com/iconify/icon-sets/$latestCommit/json/$prefix.json');

        try {
          final response = await client.get(uri);
          if (response.statusCode == 200) {
            final bodyBytes = response.bodyBytes;
            final upstreamSha = sha256.convert(bodyBytes).toString();

            if (currentLock['sha256'] == upstreamSha) {
              progress.complete('✅ $prefix: unchanged');
            } else {
              progress.fail('⚠️ $prefix: upstream changed since last sync');
              _logger.info('  Lock: ${currentLock['sha256']}');
              _logger.info('  New:  $upstreamSha');
              _logger.info('  Run "iconify sync" to update.');
              mismatchCount++;
            }
          } else {
            progress.fail(
                'Failed to fetch upstream for $prefix: HTTP ${response.statusCode}');
            errorCount++;
          }
        } catch (e) {
          progress.fail('Error verifying $prefix: $e');
          errorCount++;
        }
      }
    } finally {
      client.close();
    }

    if (mismatchCount == 0 && errorCount == 0) {
      _logger.success('✅ All verified collections are up to date.');
      return ExitCode.success.code;
    } else if (mismatchCount > 0) {
      _logger.warn('⚠️ $mismatchCount collections have changed upstream.');
      return ExitCode.software.code;
    } else {
      _logger.err('❌ Failed to verify $errorCount collections.');
      return ExitCode.software.code;
    }
  }
}
