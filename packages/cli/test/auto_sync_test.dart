import 'dart:io';

import 'package:iconify_sdk_cli/src/cli_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}
class MockProgress extends Mock implements Progress {}

void main() {
  group('Auto-Sync', () {
    late Directory tempDir;
    late Logger logger;
    late IconifyCommandRunner runner;
    late String originalCwd;

    setUp(() async {
      originalCwd = Directory.current.path;
      tempDir = await Directory.systemTemp.createTemp('iconify_auto_sync_test_');
      logger = MockLogger();
      
      when(() => logger.confirm(any(), defaultValue: any(named: 'defaultValue')))
          .thenReturn(true);
      when(() => logger.progress(any())).thenReturn(MockProgress());
      
      runner = IconifyCommandRunner(logger: logger);
      Directory.current = tempDir;
    });

    tearDown(() async {
      Directory.current = originalCwd;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generate command triggers auto-sync if snapshots missing', () async {
      // 1. Setup config and a dart file using an icon
      final configFile = File('iconify.yaml');
      await configFile.writeAsString('''
sets:
  - heroicons:*
data_dir: assets/iconify
output: lib/icons.g.dart
''');

      final libDir = Directory('lib')..createSync();
      await File('lib/main.dart').writeAsString("const widget = IconifyIcon('heroicons:bolt');");

      final snapshotFile = File('assets/iconify/heroicons.json');
      expect(snapshotFile.existsSync(), isFalse);

      // 2. Run generate
      // It will try to sync heroicons from network (which we haven't mocked yet,
      // but we want to verify the prompt happens)
      await runner.run(['generate']);

      // 3. Verify sync prompt was called for the missing collection
      verify(() => logger.info(any(that: contains('Missing snapshots for: heroicons')))).called(1);
      verify(() => logger.confirm(any(that: contains('sync them now')), defaultValue: true)).called(1);
    });
  });
}
