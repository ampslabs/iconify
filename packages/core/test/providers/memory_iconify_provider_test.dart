import '../../lib/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  final home = const IconifyName('mdi', 'home');
  final settings = const IconifyName('mdi', 'settings');
  final homeData = const IconifyIconData(
      body: '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>');
  final settingsData = const IconifyIconData(body: '<path d="M19.14 12.94"/>');

  group('MemoryIconifyProvider', () {
    late MemoryIconifyProvider provider;
    setUp(() => provider = MemoryIconifyProvider());

    test('getIcon returns null for empty provider', () async {
      expect(await provider.getIcon(home), isNull);
    });

    test('putIcon and getIcon round-trip', () async {
      provider.putIcon(home, homeData);
      expect(await provider.getIcon(home), equals(homeData));
    });

    test('getIcon returns null after removeIcon', () async {
      provider.putIcon(home, homeData);
      provider.removeIcon(home);
      expect(await provider.getIcon(home), isNull);
    });

    test('hasIcon returns true after put', () async {
      provider.putIcon(home, homeData);
      expect(await provider.hasIcon(home), isTrue);
    });

    test('hasIcon returns false for absent', () async {
      expect(await provider.hasIcon(home), isFalse);
    });

    test('clear removes all icons', () async {
      provider.putIcon(home, homeData);
      provider.putIcon(settings, settingsData);
      provider.clear();
      expect(await provider.hasIcon(home), isFalse);
      expect(await provider.hasIcon(settings), isFalse);
    });

    test('iconCount reflects current state', () {
      expect(provider.iconCount, 0);
      provider.putIcon(home, homeData);
      expect(provider.iconCount, 1);
    });

    test('putCollection and getCollection round-trip', () async {
      final info = const IconifyCollectionInfo(
        prefix: 'mdi',
        name: 'Material Design Icons',
        totalIcons: 7446,
      );
      provider.putCollection(info);
      final result = await provider.getCollection('mdi');
      expect(result?.prefix, 'mdi');
    });
  });
}
