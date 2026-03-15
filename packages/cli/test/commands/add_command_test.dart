import 'dart:convert';
import 'dart:io';

import 'package:iconify_sdk_cli/src/cli_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}
class MockProgress extends Mock implements Progress {}

void main() {
  group('AddCommand', () {
    late Directory tempDir;
    late Logger logger;
    late IconifyCommandRunner runner;
    late Progress progress;
    late String originalCwd;

    setUp(() async {
      originalCwd = Directory.current.path;
      tempDir = await Directory.systemTemp.createTemp('iconify_add_test_');
      
      // Setup files using absolute paths to avoid Directory.current issues
      await File(p.join(tempDir.path, 'iconify.yaml')).writeAsString('''
sets:
  - mdi:*
data_dir: assets/iconify
output: lib/icons.g.dart
''');

      await Directory(p.join(tempDir.path, 'assets', 'iconify')).create(recursive: true);
      await Directory(p.join(tempDir.path, 'lib')).create(recursive: true);

      logger = MockLogger();
      progress = MockProgress();
      when(() => logger.progress(any())).thenReturn(progress);
      
      runner = IconifyCommandRunner(logger: logger);
      
      // We still need to set it for the command itself since it uses relative paths
      Directory.current = tempDir;
    });

    tearDown(() async {
      Directory.current = originalCwd;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('adds icons from local snapshot', () async {
      await File(p.join(tempDir.path, 'assets', 'iconify', 'mdi.json')).writeAsString(jsonEncode({
        'prefix': 'mdi',
        'icons': {
          'home': {'body': '<path d="home"/>'},
          'account': {'body': '<path d="account"/>'},
        }
      }));

      final result = await runner.run(['add', 'mdi:home']);

      expect(result, equals(ExitCode.success.code));
      
      final cacheFile = File(p.join(tempDir.path, 'assets', 'iconify', 'used_icons.json'));
      expect(cacheFile.existsSync(), isTrue);
      
      final cacheJson = jsonDecode(await cacheFile.readAsString()) as Map<String, dynamic>;
      final icons = cacheJson['icons'] as Map<String, dynamic>;
      
      expect(icons.containsKey('mdi:home'), isTrue);
      expect((icons['mdi:home'] as Map)['body'], equals('<path d="home"/>'));
    });

    test('adds whole collection via flag', () async {
      await File(p.join(tempDir.path, 'assets', 'iconify', 'mdi.json')).writeAsString(jsonEncode({
        'prefix': 'mdi',
        'icons': {
          'home': {'body': '<path d="home"/>'},
          'account': {'body': '<path d="account"/>'},
        }
      }));

      final result = await runner.run(['add', '--collection', 'mdi']);

      expect(result, equals(ExitCode.success.code));
      
      final cacheJson = jsonDecode(await File(p.join(tempDir.path, 'assets', 'iconify', 'used_icons.json')).readAsString()) as Map<String, dynamic>;
      final icons = cacheJson['icons'] as Map<String, dynamic>;
      
      expect(icons.length, equals(2));
    });

    test('fails if icon not found and no network', () async {
      final result = await runner.run(['add', 'nonexistent:icon']);
      expect(result, equals(ExitCode.success.code));
      
      final cacheFile = File(p.join(tempDir.path, 'assets', 'iconify', 'used_icons.json'));
      expect(cacheFile.existsSync(), isFalse);
    });
  });
}
