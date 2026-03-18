import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mason_logger/mason_logger.dart';

import 'base_command.dart';

class VerifyCommand extends BaseCommand {
  VerifyCommand({required super.logger});

  @override
  String get name => 'verify';

  @override
  String get description =>
      'Verify local icon collections against upstream SHA-256 in iconify.lock.';

  @override
  Future<int> run() async {
    final config = await ensureConfig();
    if (config == null) return ExitCode.config.code;

    final lockFile = File('iconify.lock');
    if (!lockFile.existsSync()) {
      logger.err('iconify.lock not found. Run "iconify sync" first.');
      return ExitCode.noInput.code;
    }

    final progress = logger.progress('Verifying local snapshots...');
    var issues = 0;

    try {
      final lockData =
          jsonDecode(await lockFile.readAsString()) as Map<String, dynamic>;

      for (final entry in lockData.entries) {
        final prefix = entry.key;
        final info = entry.value as Map<String, dynamic>;
        final expectedSha = info['sha256'] as String?;

        final file = File('${config.dataDir}/$prefix.json');
        if (!file.existsSync()) {
          logger.warn('  ❌ Missing snapshot for $prefix');
          issues++;
          continue;
        }

        if (expectedSha != null) {
          final bytes = await file.readAsBytes();
          final actualSha = sha256.convert(bytes).toString();

          if (actualSha != expectedSha) {
            logger.warn('  ❌ SHA mismatch for $prefix!');
            logger.info('     Expected: $expectedSha');
            logger.info('     Actual:   $actualSha');
            issues++;
          }
        }
      }

      if (issues == 0) {
        progress.complete('✅ All snapshots verified successfully.');
      } else {
        progress.fail('Found $issues integrity issues.');
        return ExitCode.software.code;
      }
    } catch (e) {
      progress.fail('Verification failed: $e');
      return ExitCode.software.code;
    }

    return ExitCode.success.code;
  }
}
