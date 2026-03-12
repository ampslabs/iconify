import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  final homeData = const IconifyIconData(
    body: '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>',
  );
  final settingsData = const IconifyIconData(body: '<path d="M19.14 12.94"/>');

  group('LruIconifyCache', () {
    late LruIconifyCache cache;

    setUp(() => cache = LruIconifyCache(maxEntries: 3));

    test('put and get round-trip', () async {
      await cache.put(const IconifyName('mdi', 'home'), homeData);
      final result = await cache.get(const IconifyName('mdi', 'home'));
      expect(result, equals(homeData));
    });

    test('returns null for missing key', () async {
      expect(await cache.get(const IconifyName('mdi', 'missing')), isNull);
    });

    test('contains returns true for present key', () async {
      await cache.put(const IconifyName('mdi', 'home'), homeData);
      expect(await cache.contains(const IconifyName('mdi', 'home')), isTrue);
    });

    test('contains returns false for absent key', () async {
      expect(await cache.contains(const IconifyName('mdi', 'none')), isFalse);
    });

    test('remove deletes entry', () async {
      await cache.put(const IconifyName('mdi', 'home'), homeData);
      await cache.remove(const IconifyName('mdi', 'home'));
      expect(await cache.get(const IconifyName('mdi', 'home')), isNull);
    });

    test('clear removes all entries', () async {
      await cache.put(const IconifyName('mdi', 'home'), homeData);
      await cache.put(const IconifyName('mdi', 'settings'), settingsData);
      await cache.clear();
      expect(await cache.size(), 0);
    });

    test('size reflects current count', () async {
      expect(await cache.size(), 0);
      await cache.put(const IconifyName('mdi', 'home'), homeData);
      expect(await cache.size(), 1);
    });

    test('evicts LRU entry when at capacity', () async {
      final a = const IconifyName('mdi', 'a');
      final b = const IconifyName('mdi', 'b');
      final c = const IconifyName('mdi', 'c');
      final d = const IconifyName('mdi', 'd');
      final data = const IconifyIconData(body: '<path/>');

      await cache.put(a, data); // [a]
      await cache.put(b, data); // [a, b]
      await cache.put(c, data); // [a, b, c] — at capacity

      // Access 'a' to make it recently used
      await cache.get(a); // [b, c, a]

      await cache.put(d, data); // evicts 'b', inserts 'd' → [c, a, d]

      expect(await cache.contains(b), isFalse,
          reason: 'b should have been evicted');
      expect(await cache.contains(a), isTrue);
      expect(await cache.contains(c), isTrue);
      expect(await cache.contains(d), isTrue);
    });

    test('LRU evicts oldest when no access', () async {
      final data = const IconifyIconData(body: '<path/>');
      final names = List.generate(4, (i) => IconifyName('mdi', 'icon$i'));
      for (var i = 0; i < 3; i++) {
        await cache.put(names[i], data);
      }
      // At capacity. Insert 4th — should evict names[0] (first inserted)
      await cache.put(names[3], data);

      expect(await cache.contains(names[0]), isFalse);
      expect(await cache.contains(names[1]), isTrue);
      expect(await cache.contains(names[2]), isTrue);
      expect(await cache.contains(names[3]), isTrue);
    });

    test('stats reports fill ratio', () async {
      await cache.put(const IconifyName('mdi', 'a'), homeData);
      expect(cache.stats.currentSize, 1);
      expect(cache.stats.maxSize, 3);
      expect(cache.stats.fillRatio, closeTo(1 / 3, 0.01));
    });

    test('stats toString is informative', () async {
      await cache.put(const IconifyName('mdi', 'a'), homeData);
      expect(cache.stats.toString(), contains('1/3'));
      expect(cache.stats.toString(), contains('33.3% full'));
    });
  });
}
