import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:icon_font_generator/icon_font_generator.dart';
import 'package:iconify_sdk_builder/iconify_sdk_builder.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mason_logger/mason_logger.dart';

import 'base_command.dart';

class GenerateCommand extends BaseCommand {
  GenerateCommand({required super.logger}) {
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
    argParser.addOption(
      'format',
      abbr: 'f',
      help: 'Output format for icon data.',
      allowed: ['dart', 'binary', 'sprite', 'all'],
      defaultsTo: 'dart',
    );
    argParser.addFlag(
      'compress',
      abbr: 'c',
      help: 'Use GZIP compression for output files.',
      negatable: false,
    );
    argParser.addFlag(
      'font',
      help: 'Generate an icon font for monochrome icons.',
      negatable: false,
    );
  }

  @override
  String get name => 'generate';

  @override
  String get description => 'Manually generate icons.g.dart from source code.';

  @override
  Future<int> run() async {
    final config = await ensureConfig();
    if (config == null) return ExitCode.config.code;

    final progress = logger.progress('Scanning source code...');
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

    // 2. Ensure all needed collections are synced
    final neededPrefixes = usedIcons.map((e) => e.split(':').first).toSet();
    final syncSuccess = await ensureSynced(config, neededPrefixes);
    if (!syncSuccess) {
      progress.fail('Could not resolve all icon collections.');
      return ExitCode.unavailable.code;
    }

    // 3. Resolve data from local snapshots
    final iconDataMap = <String, IconifyIconData>{};
    final collections = <String, ParsedCollection>{};
    final attributionRequired = <String, IconifyCollectionInfo>{};

    // 2a. Pre-load all configured collections for binary generation
    for (final setConfig in config.sets) {
      final prefix = setConfig.split(':').first;
      if (!collections.containsKey(prefix)) {
        final dataFile = File('${config.dataDir}/$prefix.json');
        if (dataFile.existsSync()) {
          final jsonStr = await dataFile.readAsString();
          final collection = IconifyJsonParser.parseCollectionString(jsonStr);
          collections[prefix] = collection;

          if (collection.info.requiresAttribution) {
            attributionRequired[prefix] = collection.info;
          }
        }
      }
    }

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
          logger.warn('Snapshot missing for $prefix at ${dataFile.path}');
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
      logger.warn('⚠️  Some used icons require attribution:');
      for (final info in attributionRequired.values) {
        logger.info(
            '   - ${info.name} (${info.prefix}): ${info.license?.title ?? 'Custom'}');
      }

      if (argResults?['strict-licenses'] == true) {
        progress.fail(
            'Strict license check failed: Attribution-required icons detected.');
        return ExitCode.software.code;
      }
    }

    final format = argResults?['format'] as String;
    final compress = argResults?['compress'] as bool;
    final generateFont = argResults?['font'] as bool;
    final bool generateDart = format == 'dart' || format == 'all';
    final bool generateBinary = format == 'binary' || format == 'all';
    final bool generateSprite = format == 'sprite' || format == 'all';

    if (generateDart) {
      progress.update('Generating Dart code...');
      final outputContent = IconCodeGenerator.generate(
        usedIconNames: usedIcons,
        iconDataMap: iconDataMap,
      );

      if (argResults?['dry-run'] == true) {
        logger.info('\n--- DART PREVIEW ---');
        logger.info(outputContent.split('\n').take(10).join('\n'));
        logger.info('...');
      } else {
        final outputFile = File(config.output);
        if (!outputFile.parent.existsSync()) {
          outputFile.parent.createSync(recursive: true);
        }
        await outputFile.writeAsString(outputContent);
        logger.info('✅ Generated ${outputFile.path}');
      }

      // Also generate used_icons.json for LivingCacheProvider
      progress.update('Generating used_icons.json...');
      final json = {
        'schemaVersion': 1,
        'generated': DateTime.now().toUtc().toIso8601String(),
        'icons': iconDataMap.map((key, value) => MapEntry(key, value.toJson())),
      };
      final jsonStr = jsonEncode(json);
      final jsonFileName = compress ? 'used_icons.json.gz' : 'used_icons.json';
      final jsonFile = File('${config.dataDir}/$jsonFileName');

      if (argResults?['dry-run'] == true) {
        logger.info(
            'Dry run: Would write $jsonFileName (${jsonStr.length} bytes raw)');
      } else {
        if (!jsonFile.parent.existsSync()) {
          jsonFile.parent.createSync(recursive: true);
        }
        if (compress) {
          final bytes = Uint8List.fromList(utf8.encode(jsonStr));
          await jsonFile.writeAsBytes(gzip.encode(bytes));
        } else {
          await jsonFile.writeAsString(jsonStr);
        }
        logger.info('✅ Generated ${jsonFile.path}');
      }
    }

    if (generateBinary) {
      progress.update('Generating Binary files...');
      for (final entry in collections.entries) {
        final prefix = entry.key;
        final collection = entry.value;
        final encoded = BinaryIconFormat.encode(collection);

        final fileName = compress ? '$prefix.iconbin.gz' : '$prefix.iconbin';
        final binaryFile = File('${config.dataDir}/$fileName');

        if (argResults?['dry-run'] == true) {
          logger.info(
              'Dry run: Would write $fileName (${encoded.length} bytes raw)');
        } else {
          if (!binaryFile.parent.existsSync()) {
            binaryFile.parent.createSync(recursive: true);
          }
          if (compress) {
            await binaryFile.writeAsBytes(gzip.encode(encoded));
          } else {
            await binaryFile.writeAsBytes(encoded);
          }
          logger.info('✅ Generated ${binaryFile.path}');
        }
      }
    }

    if (generateSprite) {
      progress.update('Generating SVG Sprite Sheet...');
      final buffer = StringBuffer();
      buffer.writeln(
          '<svg xmlns="http://www.w3.org/2000/svg" width="0" height="0" style="display:none;">');

      final sortedKeys = iconDataMap.keys.toList()..sort();
      for (final fullName in sortedKeys) {
        final data = iconDataMap[fullName]!;
        final id = fullName.replaceAll(':', '-');
        buffer.writeln(
            '  <symbol id="$id" viewBox="0 0 ${data.width} ${data.height}">');
        buffer.writeln('    ${data.body}');
        buffer.writeln('  </symbol>');
      }
      buffer.writeln('</svg>');

      final spriteContent = buffer.toString();
      final spriteFileName =
          compress ? 'icons.sprite.svg.gz' : 'icons.sprite.svg';
      final spriteFile = File('${config.dataDir}/$spriteFileName');

      if (argResults?['dry-run'] == true) {
        logger.info(
            'Dry run: Would write $spriteFileName (${spriteContent.length} bytes raw)');
      } else {
        if (compress) {
          final bytes = Uint8List.fromList(utf8.encode(spriteContent));
          await spriteFile.writeAsBytes(gzip.encode(bytes));
        } else {
          await spriteFile.writeAsString(spriteContent);
        }
        logger.info('✅ Generated ${spriteFile.path}');

        // Generate manifest for SpriteIconifyProvider
        final manifest = {
          'icons': iconDataMap.map((key, value) => MapEntry(key, {
                'width': value.width,
                'height': value.height,
              })),
        };
        final manifestStr = jsonEncode(manifest);
        final manifestFileName =
            compress ? 'icons.sprite.json.gz' : 'icons.sprite.json';
        final manifestFile = File('${config.dataDir}/$manifestFileName');

        if (compress) {
          final bytes = Uint8List.fromList(utf8.encode(manifestStr));
          await manifestFile.writeAsBytes(gzip.encode(bytes));
        } else {
          await manifestFile.writeAsString(manifestStr);
        }
        logger.info('✅ Generated ${manifestFile.path}');
      }
    }

    if (generateFont) {
      progress.update('Generating Icon Font...');
      final monoIcons = <String, String>{};
      final fontMapping = <String, int>{};

      for (final fullName in iconDataMap.keys) {
        final data = iconDataMap[fullName]!;
        if (data.isMonochrome) {
          monoIcons[fullName] = data.toSvgString();
        }
      }

      if (monoIcons.isEmpty) {
        logger.warn('No monochrome icons found. Skipping font generation.');
      } else {
        try {
          final result = svgToOtf(
            svgMap: monoIcons,
            fontName: 'IconifyIcons',
          );

          final fontFileBytes =
              OTFWriter().write(result.font).buffer.asUint8List();
          final fontFileName =
              compress ? 'icons.font.otf.gz' : 'icons.font.otf';
          final fontFile = File('${config.dataDir}/$fontFileName');

          if (compress) {
            await fontFile.writeAsBytes(gzip.encode(fontFileBytes));
          } else {
            await fontFile.writeAsBytes(fontFileBytes);
          }

          // Create mapping
          for (var i = 0; i < result.glyphList.length; i++) {
            final glyph = result.glyphList[i];
            if (glyph.metadata.name != null &&
                glyph.metadata.charCode != null) {
              fontMapping[glyph.metadata.name!] = glyph.metadata.charCode!;
            }
          }

          final mapping = {
            'fontFamily': 'IconifyIcons',
            'icons': fontMapping,
          };
          final mappingStr = jsonEncode(mapping);
          final mappingFileName =
              compress ? 'icons.font.json.gz' : 'icons.font.json';
          final mappingFile = File('${config.dataDir}/$mappingFileName');

          if (compress) {
            await mappingFile
                .writeAsBytes(gzip.encode(utf8.encode(mappingStr)));
          } else {
            await mappingFile.writeAsString(mappingStr);
          }

          logger.info('✅ Generated ${fontFile.path}');
          logger.info('✅ Generated ${mappingFile.path}');
        } catch (e) {
          logger.err('Failed to generate icon font: $e');
        }
      }
    }

    // 6. Generate Attribution File
    if (attributionRequired.isNotEmpty) {
      final attributionPath = argResults?['attribution-output'] as String;
      final attributionFile = File(attributionPath);
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
      if (argResults?['dry-run'] != true) {
        await attributionFile.writeAsString(buffer.toString());
        logger.info('✅ Generated $attributionPath');
      }
    }

    progress.complete('Successfully generated icon data ($format)');
    return ExitCode.success.code;
  }
}
