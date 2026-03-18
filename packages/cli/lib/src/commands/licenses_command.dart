import 'dart:convert';
import 'dart:io';

import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'base_command.dart';

class LicensesCommand extends BaseCommand {
  LicensesCommand({required super.logger}) {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Path to generate the license report.',
      defaultsTo: 'ICON_ATTRIBUTION.md',
    );
  }

  @override
  String get name => 'licenses';

  @override
  String get description => 'Generate a license report for used icon sets.';

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

    final progress = logger.progress('Gathering license data...');
    final collections = <String, ParsedCollection>{};
    final attributionRequired = <String, IconifyCollectionInfo>{};

    try {
      final cacheJson =
          jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
      final usedIcons =
          (cacheJson['icons'] as Map<String, dynamic>? ?? {}).keys.toList();

      for (final fullName in usedIcons) {
        final prefix = fullName.split(':').first;
        if (!collections.containsKey(prefix)) {
          final snapshotFile = File('${config.dataDir}/$prefix.json');
          if (snapshotFile.existsSync()) {
            final jsonStr = await snapshotFile.readAsString();
            final collection = IconifyJsonParser.parseCollectionString(jsonStr);
            collections[prefix] = collection;

            if (collection.info.requiresAttribution) {
              attributionRequired[prefix] = collection.info;
            }
          }
        }
      }

      if (attributionRequired.isEmpty) {
        progress.complete('No icons require special attribution.');
        return ExitCode.success.code;
      }

      final buffer = StringBuffer();
      buffer.writeln('# Icon Attribution');
      buffer.writeln();
      buffer.writeln(
          'The following icon collections used in this project require attribution:');
      buffer.writeln();

      for (final info in attributionRequired.values) {
        buffer.writeln('## ${info.name}');
        buffer.writeln('- **Prefix**: `${info.prefix}`');
        if (info.author != null) {
          buffer.writeln('- **Author**: ${info.author}');
        }
        buffer.writeln(
            '- **License**: ${info.license?.title ?? 'Custom'} (${info.license?.spdx ?? 'N/A'})');
        if (info.license?.url != null) {
          buffer.writeln('- **License URL**: ${info.license?.url}');
        }
        buffer.writeln();
      }

      final outputPath = argResults?['output'] as String;
      await File(outputPath).writeAsString(buffer.toString());

      progress.complete('✅ Generated $outputPath');
    } catch (e) {
      progress.fail('Failed to generate licenses: $e');
      return ExitCode.software.code;
    }

    return ExitCode.success.code;
  }
}
