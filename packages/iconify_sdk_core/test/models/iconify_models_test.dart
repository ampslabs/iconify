import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyIconData', () {
    const body = '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>';
    const monoBody = '<path d="M10 20" fill="currentColor"/>';

    test('toJson and fromJson round-trip', () {
      final original = IconifyIconData(
        body: body,
        width: 32,
        height: 32,
        rotate: 1,
        hFlip: true,
      );
      final json = original.toJson();
      final decoded = IconifyIconData.fromJson(json);

      expect(decoded.body, original.body);
      expect(decoded.width, original.width);
      expect(decoded.height, original.height);
      expect(decoded.rotate, original.rotate);
      expect(decoded.hFlip, original.hFlip);
    });

    test('isMonochrome detects currentColor', () {
      expect(IconifyIconData(body: monoBody).isMonochrome, isTrue);
      expect(IconifyIconData(body: body).isMonochrome, isFalse);
    });

    test('toSvgString generates valid SVG', () {
      final data = IconifyIconData(body: body, width: 24, height: 24);
      final svg = data.toSvgString(size: 48);
      expect(svg, contains('viewBox="0 0 24.0 24.0"'));
      expect(svg, contains('width="48.0"'));
      expect(svg, contains('height="48.0"'));
      expect(svg, contains(body));
    });

    test('toSvgString applies color to monochrome icons', () {
      final data = IconifyIconData(body: monoBody);
      final svg = data.toSvgString(color: '#FF0000');
      expect(svg, contains('#FF0000'));
      expect(svg, isNot(contains('currentColor')));
    });

    test('copyWith works', () {
      final data = IconifyIconData(body: body);
      final copy = data.copyWith(width: 48);
      expect(copy.body, data.body);
      expect(copy.width, 48);
    });
  });

  group('IconifyCollectionInfo', () {
    test('fromJson handles different author formats', () {
      final stringAuthor =
          IconifyCollectionInfo.fromJson('test', {'author': 'John Doe'});
      expect(stringAuthor.author, 'John Doe');

      final mapAuthor = IconifyCollectionInfo.fromJson(
          'test', {'author': {'name': 'Jane Doe'}});
      expect(mapAuthor.author, 'Jane Doe');
    });

    test('toJson and fromJson round-trip', () {
      final original = IconifyCollectionInfo(
        prefix: 'mdi',
        name: 'Material Design Icons',
        totalIcons: 7446,
        author: 'Austin Andrews',
        license: const IconifyLicense(title: 'Apache 2.0', spdx: 'Apache-2.0'),
      );
      final json = original.toJson();
      // fromJson expects the inner part or the whole map?
      // Step 7 says: factory IconifyCollectionInfo.fromJson(String prefix, Map<String, dynamic> json)
      // and it looks for json['info'] or json.
      final decoded = IconifyCollectionInfo.fromJson('mdi', json);

      expect(decoded.prefix, original.prefix);
      expect(decoded.name, original.name);
      expect(decoded.author, original.author);
      expect(decoded.license?.title, original.license?.title);
    });
  });

  group('IconifySearchResult', () {
    test('stores search data', () {
      final name = IconifyName('mdi', 'home');
      final result = IconifySearchResult(name: name, score: 0.95, matchedOn: 'exact');
      expect(result.name, name);
      expect(result.score, 0.95);
      expect(result.matchedOn, 'exact');
    });
  });
}
