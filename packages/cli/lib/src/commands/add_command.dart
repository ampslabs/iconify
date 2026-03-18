import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import 'base_command.dart';

class AddCommand extends BaseCommand {
  AddCommand({required super.logger}) {
    argParser.addOption(
      'collection',
      abbr: 'c',
      help:
          'Add all icons from a specific collection (requires local snapshot).',
    );
  }

  @override
  String get name => 'add';

  @override
  String get description => 'Explicitly add icons to used_icons.json.';

  @override
  String get invocation => 'iconify add <prefix:name> [<prefix:name>...]';

  @override
  Future<int> run() async {
    final config = await ensureConfig();
    if (config == null) return ExitCode.config.code;

    final cachePath = p.join(config.dataDir, 'used_icons.json');
    final cacheFile = File(cachePath);

    if (!cacheFile.parent.existsSync()) {
      cacheFile.parent.createSync(recursive: true);
    }

    Map<String, dynamic> cacheJson;
    if (cacheFile.existsSync()) {
      try {
        final content = await cacheFile.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is Map) {
          cacheJson = Map<String, dynamic>.from(decoded);
        } else {
          cacheJson = _createEmptyCache();
        }
      } catch (e) {
        logger.err('Failed to parse used_icons.json: $e');
        return ExitCode.software.code;
      }
    } else {
      cacheJson = _createEmptyCache();
    }

    final iconsJson =
        Map<String, dynamic>.from(cacheJson['icons'] as Map? ?? {});
    final collections = <String, ParsedCollection>{};

    final iconsToAdd = <String>[];

    final collectionOption = argResults?['collection'] as String?;
    if (collectionOption != null) {
      final snapshotFile = File('${config.dataDir}/$collectionOption.json');
      if (!snapshotFile.existsSync()) {
        logger.err(
            'Snapshot for "$collectionOption" not found. Run "iconify sync" first.');
        return ExitCode.noInput.code;
      }

      try {
        final jsonStr = await snapshotFile.readAsString();
        final collection = IconifyJsonParser.parseCollectionString(jsonStr);
        for (final iconName in collection.allNames) {
          iconsToAdd.add('$collectionOption:$iconName');
          collections[collectionOption] = collection;
        }
      } catch (e) {
        logger.err('Failed to parse snapshot for "$collectionOption": $e');
        return ExitCode.software.code;
      }
    }

    iconsToAdd.addAll(argResults?.rest ?? []);

    if (iconsToAdd.isEmpty) {
      logger.err('No icons specified. Usage: iconify add <prefix:name>');
      return ExitCode.usage.code;
    }

    final progress = logger.progress('Adding ${iconsToAdd.length} icons...');
    var addedCount = 0;

    final httpClient = http.Client();

    try {
      for (final fullName in iconsToAdd) {
        if (iconsJson.containsKey(fullName)) continue;

        final parts = fullName.split(':');
        if (parts.length < 2) {
          logger.warn('  ⚠️ Invalid icon name: $fullName');
          continue;
        }

        final prefix = parts[0];
        final iconName = parts[1];

        if (!collections.containsKey(prefix)) {
          final snapshotFile = File('${config.dataDir}/$prefix.json');
          if (snapshotFile.existsSync()) {
            try {
              final jsonStr = await snapshotFile.readAsString();
              collections[prefix] =
                  IconifyJsonParser.parseCollectionString(jsonStr);
            } catch (_) {}
          }
        }

        IconifyIconData? data = collections[prefix]?.getIcon(iconName);

        if (data == null) {
          try {
            final uri = Uri.parse(
                'https://raw.githubusercontent.com/iconify/icon-sets/master/json/$prefix.json');
            final response =
                await httpClient.get(uri).timeout(const Duration(seconds: 5));
            if (response.statusCode == 200) {
              final collection =
                  IconifyJsonParser.parseCollectionString(response.body);
              collections[prefix] = collection;
              data = collection.getIcon(iconName);
            }
          } catch (_) {}
        }

        if (data != null) {
          final json = data.toJson();
          json['source'] = 'added';
          iconsJson[fullName] = json;
          addedCount++;
        } else {
          logger.warn('  ⚠️ Could not find data for "$fullName"');
        }
      }
    } finally {
      httpClient.close();
    }

    if (addedCount > 0) {
      cacheJson['generated'] = DateTime.now().toUtc().toIso8601String();
      cacheJson['icons'] = iconsJson;
      await cacheFile
          .writeAsString(const JsonEncoder.withIndent('  ').convert(cacheJson));
      progress
          .complete('Successfully added $addedCount icons to used_icons.json');
    } else {
      progress.complete('No new icons were added.');
    }

    return ExitCode.success.code;
  }

  Map<String, dynamic> _createEmptyCache() {
    return {
      'schemaVersion': 1,
      'generated': DateTime.now().toUtc().toIso8601String(),
      'icons': <String, dynamic>{},
    };
  }
}
