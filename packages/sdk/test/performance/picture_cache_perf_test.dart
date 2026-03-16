import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconify_sdk/src/render/picture_cache.dart';

void main() {
  group('IconifyPictureCache Performance', () {
    testWidgets('benchmark hit time', (tester) async {
      final cache = IconifyPictureCache(maxEntries: 1000);
      final svg = '<svg viewBox="0 0 24 24"><path d="M0 0h24v24z"/></svg>';
      final info = await vg.loadPicture(SvgStringLoader(svg), null);

      cache.put('test', info);

      final sw = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        cache.get('test');
      }
      sw.stop();

      // Benchmarks are expected to print to console.
      // ignore: avoid_print
      print('PictureCache Hit (10k iterations): ${sw.elapsedMilliseconds}ms');
    });

    testWidgets('benchmark eviction overhead', (tester) async {
      // Small cache to force constant eviction
      final cache = IconifyPictureCache(maxEntries: 10);

      final infos = <PictureInfo>[];
      for (var i = 0; i < 100; i++) {
        final svg = '<svg viewBox="0 0 24 24"><path d="M$i 0h1v1z"/></svg>';
        infos.add(await vg.loadPicture(SvgStringLoader(svg), null));
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        cache.put('key_$i', infos[i]);
      }
      sw.stop();

      // Benchmarks are expected to print to console.
      // ignore: avoid_print
      print(
          'PictureCache Put with Eviction (100 iterations): ${sw.elapsedMilliseconds}ms');
    });
  });
}
