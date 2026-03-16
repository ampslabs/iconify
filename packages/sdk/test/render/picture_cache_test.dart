import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconify_sdk/iconify_sdk.dart';
import 'package:iconify_sdk/src/render/picture_cache.dart';

void main() {
  group('IconifyPictureCache', () {
    late IconifyPictureCache cache;

    setUp(() {
      cache = IconifyPictureCache(maxEntries: 2);
    });

    Future<PictureInfo> loadSvg(String pathData) {
      final svg = '<svg viewBox="0 0 24 24"><path d="$pathData"/></svg>';
      return vg.loadPicture(SvgStringLoader(svg), null);
    }

    testWidgets('stores and retrieves pictures', (tester) async {
      final info = await loadSvg('M0 0h24v24z');
      cache.put('key1', info);

      expect(cache.length, 1);
      final retrieved = cache.get('key1');
      expect(retrieved, same(info));
      expect(cache.hits, 1);
    });

    testWidgets('evicts oldest entry (LRU)', (tester) async {
      final info1 = await loadSvg('M0 0h1');
      final info2 = await loadSvg('M0 0h2');
      final info3 = await loadSvg('M0 0h3');

      cache.put('key1', info1);
      cache.put('key2', info2);
      expect(cache.length, 2);

      // Access key1 to make key2 the oldest
      cache.get('key1');

      cache.put('key3', info3);
      expect(cache.length, 2);
      expect(cache.get('key1'), isNotNull);
      expect(cache.get('key2'), isNull); // Evicted
      expect(cache.get('key3'), isNotNull);
    });

    testWidgets('clears and disposes all pictures', (tester) async {
      final info = await loadSvg('M0 0h1');
      cache.put('key1', info);
      cache.clear();

      expect(cache.length, 0);
      expect(cache.hits, 0);
      expect(cache.get('key1'), isNull);
    });
  });

  group('IconifyDiagnostics', () {
    setUp(() {
      IconifyDiagnostics.reset();
    });

    testWidgets('tracks hits and misses', (tester) async {
      final svg = '<svg viewBox="0 0 24 24"><path d="M0 0h1"/></svg>';
      final info = await vg.loadPicture(SvgStringLoader(svg), null);

      IconifyPictureCache.instance.put('test', info);

      IconifyPictureCache.instance.get('test'); // Hit
      IconifyPictureCache.instance.get('missing'); // Miss

      final stats = IconifyDiagnostics.pictureCacheStats;
      expect(stats.hits, 1);
      expect(stats.misses, 1);
      expect(stats.hitRate, 0.5);
    });
  });
}
