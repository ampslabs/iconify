import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  final home = const IconifyName('mdi', 'home');
  final homeData = const IconifyIconData(body: '<path/>');

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
      final firstData = const IconifyIconData(body: '<path d="first"/>');
      final secondData = const IconifyIconData(body: '<path d="second"/>');

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

    test('getCollection returns first match', () async {
      final info = const IconifyCollectionInfo(prefix: 'mdi', name: 'MDI', totalIcons: 1);
      final first = MemoryIconifyProvider();
      final second = MemoryIconifyProvider()..putCollection(info);

      final composite = CompositeIconifyProvider([first, second]);
      final result = await composite.getCollection('mdi');
      expect(result?.name, 'MDI');
    });

    test('hasCollection returns true if any provider has it', () async {
      final info = const IconifyCollectionInfo(prefix: 'mdi', name: 'MDI', totalIcons: 1);
      final first = MemoryIconifyProvider();
      final second = MemoryIconifyProvider()..putCollection(info);

      final composite = CompositeIconifyProvider([first, second]);
      expect(await composite.hasCollection('mdi'), isTrue);
    });

    test('dispose disposes all providers', () async {
      final first = RemoteIconifyProvider(); // Has dispose side effect (disposed flag)
      final composite = CompositeIconifyProvider([first]);
      await composite.dispose();
      expect(() => first.getIcon(home), throwsStateError);
    });
  });
}
