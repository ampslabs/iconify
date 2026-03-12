import 'dart:async';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import '../config/iconify_build_config.dart';
import '../generator/icon_code_generator.dart';
import '../scanner/icon_name_scanner.dart';

/// The core builder that orchestrates the icon bundling process.
class IconifyBuilder implements Builder {
  const IconifyBuilder();

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': ['icons.g.dart'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    // 1. Load config
    final configId = AssetId(buildStep.inputId.package, 'iconify.yaml');
    IconifyBuildConfig config = const IconifyBuildConfig();

    if (await buildStep.canRead(configId)) {
      final yaml = await buildStep.readAsString(configId);
      try {
        config = IconifyBuildConfig.fromYaml(yaml);
      } catch (e) {
        log.warning('Failed to parse iconify.yaml: $e. Using defaults.');
      }
    }

    final usedIcons = <String>{};

    // 2. Scan all Dart files in lib/ for Iconify usages
    final dartFiles = buildStep.findAssets(Glob('lib/**.dart'));
    await for (final id in dartFiles) {
      // Don't scan the generated file itself
      if (id.path.endsWith('icons.g.dart')) continue;

      final content = await buildStep.readAsString(id);
      final scanner = IconNameScanner()..scan(content);
      usedIcons.addAll(scanner.iconNames);
    }

    if (usedIcons.isEmpty) {
      log.info('No Iconify icons detected in source code.');
      return;
    }

    log.info('Detected ${usedIcons.length} icons. Resolving data...');

    // 3. Resolve icon data from local snapshots
    final iconDataMap = <String, IconifyIconData>{};
    final collections = <String, ParsedCollection>{};

    for (final fullName in usedIcons) {
      final parts = fullName.split(':');
      if (parts.length < 2) continue;

      final prefix = parts[0];
      final iconName = parts[1];

      // Load collection if not already cached
      if (!collections.containsKey(prefix)) {
        final dataId = AssetId(
            buildStep.inputId.package, '${config.dataDir}/$prefix.json');
        if (await buildStep.canRead(dataId)) {
          final jsonStr = await buildStep.readAsString(dataId);
          collections[prefix] =
              IconifyJsonParser.parseCollectionString(jsonStr);
        } else {
          log.warning(
              'Snapshot missing for collection: $prefix (at ${dataId.path})');
          continue;
        }
      }

      final iconData = collections[prefix]?.getIcon(iconName);
      if (iconData != null) {
        iconDataMap[fullName] = iconData;
      } else {
        log.warning('Icon not found in local snapshot: $fullName');
      }
    }

    // 4. Generate code
    final output = IconCodeGenerator.generate(
      usedIconNames: usedIcons,
      iconDataMap: iconDataMap,
    );

    // 5. Write output
    // The build system expects us to write to an AssetId based on our buildExtensions
    final outputId = AssetId(buildStep.inputId.package, config.output);
    await buildStep.writeAsString(outputId, output);

    log.info(
        'Successfully bundled ${iconDataMap.length} icons into ${outputId.path}');
  }
}
