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
    argParser.addFlag(
      'strict-licenses',
      help: 'Exit with error if any attribution-required icons are detected.',
      negatable: false,
    );
    argParser.addOption(
      'attribution-output',
      abbr: 'a',
      help: 'Path to generate ICON_ATTRIBUTION.md.',
      defaultsTo: 'ICON_ATTRIBUTION.md',
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
    final attributionRequired = <String, IconifyCollectionInfo>{};

    for (final fullName in usedIcons) {
      final parts = fullName.split(':');
      if (parts.length < 2) continue;

      final prefix = parts[0];
      final iconName = parts[1];

      if (!collections.containsKey(prefix)) {
        final dataFile = File('${config.dataDir}/$prefix.json');
        if (dataFile.existsSync()) {
          final jsonStr = await dataFile.readAsString();
          final collection = IconifyJsonParser.parseCollectionString(jsonStr);
          collections[prefix] = collection;

          if (collection.info.requiresAttribution) {
            attributionRequired[prefix] = collection.info;
          }
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

    // 3. License Enforcement
    if (attributionRequired.isNotEmpty) {
      _logger.warn('⚠️  Some used icons require attribution:');
      for (final info in attributionRequired.values) {
        _logger.info('   - ${info.name} (${info.prefix}): ${info.license?.title ?? 'Custom'}');
      }

      if (argResults?['strict-licenses'] == true) {
        progress.fail('Strict license check failed: Attribution-required icons detected.');
        return ExitCode.software.code;
      }
    }

    progress.update('Generating code...');

    // 4. Generate Dart code
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

    // 5. Write to disk
    final outputFile = File(config.output);
    if (!outputFile.parent.existsSync()) {
      outputFile.parent.createSync(recursive: true);
    }
    await outputFile.writeAsString(outputContent);

    // 6. Generate Attribution File
    if (attributionRequired.isNotEmpty) {
      final attributionPath = argResults?['attribution-output'] as String;
      final attributionFile = File(attributionPath);
      final buffer = StringBuffer();
      buffer.writeln('# Icon Attribution');
      buffer.writeln();
      buffer.writeln('The following icon collections used in this project require attribution:');
      buffer.writeln();
      for (final info in attributionRequired.values) {
        buffer.writeln('## ${info.name}');
        buffer.writeln('- **Prefix**: `${info.prefix}`');
        if (info.author != null) buffer.writeln('- **Author**: ${info.author}');
        buffer.writeln('- **License**: ${info.license?.title ?? 'Custom'} (${info.license?.spdx ?? 'N/A'})');
        if (info.license?.url != null) buffer.writeln('- **License URL**: ${info.license?.url}');
        buffer.writeln();
      }
      await attributionFile.writeAsString(buffer.toString());
      _logger.info('✅ Generated $attributionPath');
    }

    progress.complete(
        'Successfully generated ${iconDataMap.length} icons into ${config.output}');
    return ExitCode.success.code;
  }
}
