import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockProvider extends Mock implements IconifyProvider {}

void main() {
  final home = const IconifyName('mdi', 'home');
  final homeData = const IconifyIconData(body: '<path/>');

  setUpAll(() {
    registerFallbackValue(home);
    registerFallbackValue('mdi');
  });

  group('CachingIconifyProvider', () {
    late MockProvider inner;
    late CachingIconifyProvider provider;

    setUp(() {
      inner = MockProvider();
      provider = CachingIconifyProvider(inner: inner);
    });

    test('delegates to inner on cache miss', () async {
      when(() => inner.getIcon(home)).thenAnswer((_) async => homeData);

      final result = await provider.getIcon(home);
      expect(result, equals(homeData));
      verify(() => inner.getIcon(home)).called(1);
    });

    test('returns cached value on second call without calling inner again',
        () async {
      when(() => inner.getIcon(home)).thenAnswer((_) async => homeData);

      await provider.getIcon(home);
      await provider.getIcon(home);

      verify(() => inner.getIcon(home)).called(1); // Only called once
    });

    test('tracks hit and miss counts', () async {
      when(() => inner.getIcon(home)).thenAnswer((_) async => homeData);

      await provider.getIcon(home); // miss
      await provider.getIcon(home); // hit
      await provider.getIcon(home); // hit

      expect(provider.hits, 2);
      expect(provider.misses, 1);
    });

    test('does not cache null results', () async {
      when(() => inner.getIcon(home)).thenAnswer((_) async => null);

      await provider.getIcon(home);
      await provider.getIcon(home);

      verify(() => inner.getIcon(home)).called(2);
    });

    test('resetStats zeros counters', () async {
      when(() => inner.getIcon(home)).thenAnswer((_) async => homeData);
      await provider.getIcon(home);
      provider.resetStats();
      expect(provider.hits, 0);
      expect(provider.misses, 0);
    });
  });
}
