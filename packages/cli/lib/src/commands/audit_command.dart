import 'dart:convert';
import 'dart:io';

import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'base_command.dart';

class AuditCommand extends BaseCommand {
  AuditCommand({required super.logger});

  @override
  String get name => 'audit';

  @override
  String get description =>
      'Check for non-commercial or restricted icons in your bundle.';

  @override
  Future<int> run() async {
    final config = await ensureConfig();
    if (config == null) return ExitCode.config.code;

    final cachePath = p.join(config.dataDir, 'used_icons.json');
    final cacheFile = File(cachePath);

    if (!cacheFile.existsSync()) {
      logger.err('used_icons.json not found. Run "iconify generate" first.');
      return ExitCode.noInput.code;
    }

    final progress = logger.progress('Auditing icons...');
    final collections = <String, ParsedCollection>{};

    try {
      final cacheJson =
          jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
      final usedIcons =
          (cacheJson['icons'] as Map<String, dynamic>? ?? {}).keys.toList();

      if (usedIcons.isEmpty) {
        progress.complete('No icons found to audit.');
        return ExitCode.success.code;
      }

      final restricted = <String, List<String>>{};

      for (final fullName in usedIcons) {
        final prefix = fullName.split(':').first;

        if (!collections.containsKey(prefix)) {
          final snapshotFile = File('${config.dataDir}/$prefix.json');
          if (snapshotFile.existsSync()) {
            final jsonStr = await snapshotFile.readAsString();
            collections[prefix] =
                IconifyJsonParser.parseCollectionString(jsonStr);
          }
        }

        final info = collections[prefix]?.info;
        if (info != null) {
          final license = info.license?.spdx?.toLowerCase() ?? '';
          if (license.contains('nc') || license.contains('non-commercial')) {
            restricted.putIfAbsent(info.name, () => []).add(fullName);
          }
        }
      }

      if (restricted.isEmpty) {
        progress.complete('✅ All icons are commercially friendly.');
      } else {
        progress.fail('⚠️  Found icons with non-commercial restrictions:');
        restricted.forEach((collection, icons) {
          logger.info('\n   $collection:');
          for (final icon in icons) {
            logger.info('     - $icon');
          }
        });
      }
    } catch (e) {
      progress.fail('Audit failed: $e');
      return ExitCode.software.code;
    }

    return ExitCode.success.code;
  }
}
