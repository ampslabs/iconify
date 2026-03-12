import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  final home = IconifyName('mdi', 'home');
  final homeData = IconifyIconData(body: '<path/>');

  group('CompositeIconifyProvider', () {
    test('returns result from first provider that has the icon', () async {
      final first = MemoryIconifyProvider();
      final second = MemoryIconifyProvider()..putIcon(home, homeData);

      final composite = CompositeIconifyProvider([first, second]);
      final result = await composite.getIcon(home);
      expect(result, equals(homeData));
    });

    test('returns null when all providers return null', () async {
      final composite = CompositeIconifyProvider([
        MemoryIconifyProvider(),
        MemoryIconifyProvider(),
      ]);
      expect(await composite.getIcon(home), isNull);
    });

    test('first provider wins over second', () async {
      final firstData = IconifyIconData(body: '<path d="first"/>');
      final secondData = IconifyIconData(body: '<path d="second"/>');

      final first = MemoryIconifyProvider()..putIcon(home, firstData);
      final second = MemoryIconifyProvider()..putIcon(home, secondData);

      final composite = CompositeIconifyProvider([first, second]);
      final result = await composite.getIcon(home);
      expect(result?.body, contains('first'));
    });

    test('hasIcon returns true if any provider has it', () async {
      final first = MemoryIconifyProvider();
      final second = MemoryIconifyProvider()..putIcon(home, homeData);

      final composite = CompositeIconifyProvider([first, second]);
      expect(await composite.hasIcon(home), isTrue);
    });
  });
}
