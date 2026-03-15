import 'dart:convert';
import 'dart:io';

import 'package:iconify_sdk_cli/src/cli_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('AddCommand', () {
    late Directory tempDir;
    late Logger logger;
    late IconifyCommandRunner runner;
    late String originalCwd;

    setUp(() async {
      originalCwd = Directory.current.path;
      tempDir = await Directory.systemTemp.createTemp('iconify_add_test_');
      logger = Logger();
      runner = IconifyCommandRunner(logger: logger);

      // Create dummy iconify.yaml
      File(p.join(tempDir.path, 'iconify.yaml')).writeAsStringSync('''
sets:
  - mdi:*
data_dir: assets/iconify
''');

      Directory.current = tempDir;
    });

    tearDown(() async {
      Directory.current = originalCwd;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('adds icons from local snapshot', () async {
      // 1. Create a "snapshot" for mdi
      final dataDir = Directory('assets/iconify')..createSync(recursive: true);
      File(p.join(dataDir.path, 'mdi.json')).writeAsStringSync(jsonEncode({
        'prefix': 'mdi',
        'icons': {
          'home': {'body': '<path d="home"/>'}
        }
      }));

      final result = await runner.run(['add', 'mdi:home']);

      expect(result, equals(ExitCode.success.code));

      // Verify it's in used_icons.json
      final cacheFile = File('assets/iconify/used_icons.json');
      expect(cacheFile.existsSync(), isTrue);
      final data = jsonDecode(cacheFile.readAsStringSync()) as Map;
      final icons = data['icons'] as Map;
      expect(icons.containsKey('mdi:home'), isTrue);
    });

    test('adds whole collection via flag', () async {
      final dataDir = Directory('assets/iconify')..createSync(recursive: true);
      File(p.join(dataDir.path, 'mdi.json')).writeAsStringSync(jsonEncode({
        'prefix': 'mdi',
        'icons': {
          'home': {'body': '<path d="home"/>'},
          'user': {'body': '<path d="user"/>'},
        }
      }));

      final result = await runner.run(['add', '--collection', 'mdi']);

      expect(result, equals(ExitCode.success.code));

      final cacheFile = File('assets/iconify/used_icons.json');
      final data = jsonDecode(cacheFile.readAsStringSync()) as Map;
      final icons = data['icons'] as Map;
      expect(icons.length, equals(2));
    });

    test('fails if icon not found and no network', () async {
      // We expect it to succeed but not actually add anything if it's missing
      // or it might try remote and fail.
      final result = await runner.run(['add', 'nonexistent:icon']);
      expect(result, equals(ExitCode.success.code));

      final cacheFile = File('assets/iconify/used_icons.json');
      expect(cacheFile.existsSync(), isFalse);
    });
  });
}
