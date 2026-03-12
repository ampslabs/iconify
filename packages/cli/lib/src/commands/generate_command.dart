import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mason_logger/mason_logger.dart';

class GenerateCommand extends Command<int> {
  GenerateCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'dry-run',
      help: 'Show what would be generated without writing to disk.',
      negatable: false,
    );
  }

  @override
  String get name => 'generate';

  @override
  String get description => 'Manually generate icons.g.dart from source code.';

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
        if (entity.path.endsWith('icons.g.dart')) continue;
        final content = await entity.readAsString();
        final scanner = IconNameScanner()..scan(content);
        usedIcons.addAll(scanner.iconNames);
      }
    }

    if (usedIcons.isEmpty) {
      progress.complete('No Iconify icons detected.');
      return ExitCode.success.code;
    }

    progress.update('Resolving data for ${usedIcons.length} icons...');

    // 2. Resolve data from local snapshots
    final iconDataMap = <String, IconifyIconData>{};
    final collections = <String, ParsedCollection>{};

    for (final fullName in usedIcons) {
      final parts = fullName.split(':');
      if (parts.length < 2) continue;

      final prefix = parts[0];
      final iconName = parts[1];

      if (!collections.containsKey(prefix)) {
        final dataFile = File('${config.dataDir}/$prefix.json');
        if (dataFile.existsSync()) {
          final jsonStr = await dataFile.readAsString();
          collections[prefix] =
              IconifyJsonParser.parseCollectionString(jsonStr);
        } else {
          _logger.warn('Snapshot missing for $prefix at ${dataFile.path}');
          continue;
        }
      }

      final iconData = collections[prefix]?.getIcon(iconName);
      if (iconData != null) {
        iconDataMap[fullName] = iconData;
      }
    }

    progress.update('Generating code...');

    // 3. Generate Dart code
    final outputContent = IconCodeGenerator.generate(
      usedIconNames: usedIcons,
      iconDataMap: iconDataMap,
    );

    if (argResults?['dry-run'] == true) {
      progress.complete(
          'Dry run: Code generation would produce ${iconDataMap.length} icons.');
      _logger.info('\n--- PREVIEW ---');
      _logger.info(outputContent.split('\n').take(20).join('\n'));
      _logger.info('...');
      return ExitCode.success.code;
    }

    // 4. Write to disk
    final outputFile = File(config.output);
    if (!outputFile.parent.existsSync()) {
      outputFile.parent.createSync(recursive: true);
    }
    await outputFile.writeAsString(outputContent);

    progress.complete(
        'Successfully generated ${iconDataMap.length} icons into ${config.output}');
    return ExitCode.success.code;
  }
}
