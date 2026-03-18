import 'dart:io';

import 'package:iconify_sdk_cli/src/cli_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}
class MockProgress extends Mock implements Progress {}

void main() {
  group('Auto-Init', () {
    late Directory tempDir;
    late Logger logger;
    late IconifyCommandRunner runner;
    late String originalCwd;

    setUp(() async {
      originalCwd = Directory.current.path;
      tempDir = await Directory.systemTemp.createTemp('iconify_auto_init_test_');
      logger = MockLogger();
      
      // Default stubbing for logger
      when(() => logger.confirm(any(), defaultValue: any(named: 'defaultValue')))
          .thenReturn(true);
      when(() => logger.prompt(any(), defaultValue: any(named: 'defaultValue')))
          .thenReturn('mdi');
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

    test('proactively asks to init if iconify.yaml is missing', () async {
      final configFile = File('iconify.yaml');
      expect(configFile.existsSync(), isFalse);

      // Running doctor should trigger init prompt
      await runner.run(['doctor']);

      // Verify prompt was called
      verify(() => logger.confirm(
            any(that: contains('initialize Iconify')),
            defaultValue: true,
          )).called(1);

      expect(configFile.existsSync(), isTrue);
      expect(configFile.readAsStringSync(), contains('mdi:*'));
    });

    test('sync command triggers auto-init if config missing', () async {
      final configFile = File('iconify.yaml');
      expect(configFile.existsSync(), isFalse);

      // Running sync should trigger init prompt
      // We expect it to fail sync after init because we aren't mocking the network here,
      // but the init should happen.
      await runner.run(['sync']);

      verify(() => logger.confirm(
            any(that: contains('initialize Iconify')),
            defaultValue: true,
          )).called(1);

      expect(configFile.existsSync(), isTrue);
    });
  });
}
