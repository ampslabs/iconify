import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mason_logger/mason_logger.dart';

class LicensesCommand extends Command<int> {
  LicensesCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'format',
      abbr: 'f',
      help: 'Output format.',
      allowed: ['markdown', 'json'],
      defaultsTo: 'markdown',
    );
  }

  @override
  String get name => 'licenses';

  @override
  String get description => 'Generate a license report for used icon sets.';

  final Logger _logger;

  @override
  Future<int> run() async {
    final configFile = File('iconify.yaml');
    if (!configFile.existsSync()) {
      _logger.err('iconify.yaml not found.');
      return ExitCode.config.code;
    }

    final IconifyBuildConfig config;
    try {
      config = IconifyBuildConfig.fromYaml(await configFile.readAsString());
    } catch (e) {
      _logger.err('Error parsing iconify.yaml: $e');
      return ExitCode.config.code;
    }

    final dataDir = Directory(config.dataDir);
    if (!dataDir.existsSync()) {
      _logger.err('data_dir "${config.dataDir}" not found. Sync icons first.');
      return ExitCode.noInput.code;
    }

    final prefixes = config.sets.map((s) => s.split(':').first).toSet();
    final infos = <IconifyCollectionInfo>[];

    for (final prefix in prefixes) {
      final file = File('${config.dataDir}/$prefix.json');
      if (file.existsSync()) {
        try {
          final jsonStr = await file.readAsString();
          final collection = IconifyJsonParser.parseCollectionString(jsonStr);
          infos.add(collection.info);
        } catch (_) {}
      }
    }

    if (infos.isEmpty) {
      _logger.info('No icon sets found to report on.');
      return ExitCode.success.code;
    }

    if (argResults?['format'] == 'json') {
      _logger.info(jsonEncode(infos.map((i) => i.toJson()).toList()));
    } else {
      _logger.info(_generateMarkdown(infos));
    }

    return ExitCode.success.code;
  }

  String _generateMarkdown(List<IconifyCollectionInfo> infos) {
    final buffer = StringBuffer();
    buffer.writeln('# Iconify Licenses Report');
    buffer.writeln();
    buffer.writeln('This app uses icons from the following collections:');
    buffer.writeln();
    buffer.writeln('| Collection | License | Attribution Required? | Link |');
    buffer.writeln('|---|---|---|---|');

    for (final info in infos) {
      final license = info.license;
      final attribution =
          (license?.requiresAttribution ?? false) ? '⚠️ YES' : '✅ No';
      final spdx = license?.spdx ?? 'Custom';
      final url = license?.url ?? 'N/A';

      buffer.writeln(
          '| ${info.name} (`${info.prefix}`) | $spdx | $attribution | [License Link]($url) |');
    }

    return buffer.toString();
  }
}
