import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('DevModeGuard', () {
    tearDown(() => DevModeGuard.resetOverride());

    test('isRemoteAllowedInCurrentBuild returns true in debug mode (test env)',
        () {
      // Tests run in debug mode, so asserts execute — should return true
      expect(DevModeGuard.isRemoteAllowedInCurrentBuild(), isTrue);
    });

    test('allowRemoteInRelease overrides to true', () {
      DevModeGuard.allowRemoteInRelease();
      expect(DevModeGuard.isRemoteAllowedInCurrentBuild(), isTrue);
    });

    test('resetOverride restores default behavior', () {
      DevModeGuard.allowRemoteInRelease();
      DevModeGuard.resetOverride();
      // Back to normal — in test (debug) mode, still true
      expect(DevModeGuard.isRemoteAllowedInCurrentBuild(), isTrue);
    });
  });
}
