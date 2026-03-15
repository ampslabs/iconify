import 'dart:io';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('SvgSanitizer', () {
    const sanitizer = SvgSanitizer(mode: SanitizerMode.lenient);
    const strictSanitizer = SvgSanitizer(mode: SanitizerMode.strict);

    String readCorpus(String name) {
      return File('test/security/malicious_svgs/$name').readAsStringSync();
    }

    test('strips <script> tags', () {
      final input = readCorpus('xss_script_tag.svg');
      final output = sanitizer.sanitize(input);
      expect(output, isNot(contains('<script>')));
      expect(output, contains('<path'));
    });

    test('strict mode throws on <script> tags', () {
      final input = readCorpus('xss_script_tag.svg');
      expect(() => strictSanitizer.sanitize(input),
          throwsA(isA<SvgSanitizationException>()));
    });

    test('strips event handlers (on*)', () {
      final input = readCorpus('xss_event_handler.svg');
      final output = sanitizer.sanitize(input);
      expect(output, isNot(contains('onclick')));
      expect(output, contains('<rect'));
    });

    test('strips javascript: hrefs', () {
      final input = readCorpus('xss_href_javascript.svg');
      final output = sanitizer.sanitize(input);
      expect(output, isNot(contains('javascript:')));
      expect(output, contains('<circle'));
    });

    test('strips <foreignObject> tags', () {
      final input = readCorpus('xss_foreignobject.svg');
      final output = sanitizer.sanitize(input);
      expect(output, isNot(contains('<foreignObject>')));
      expect(output, isNot(contains('<script>')));
    });

    test('strips CSS expression() in style', () {
      final input = readCorpus('xss_css_expression.svg');
      final output = sanitizer.sanitize(input);
      expect(output, isNot(contains('expression(')));
      expect(output, contains('<path'));
    });

    test('strips data: URIs', () {
      final input = readCorpus('xss_data_uri.svg');
      final output = sanitizer.sanitize(input);
      expect(output, isNot(contains('data:')));
      expect(output, contains('<image'));
    });

    test('strips external <use> hrefs', () {
      final input = readCorpus('xss_use_external.svg');
      final output = sanitizer.sanitize(input);
      expect(output, isNot(contains('evil.com')));
      expect(output, contains('<use'));
    });

    test('strips XML entities and DOCTYPE', () {
      final input = readCorpus('xss_xml_entity.svg');
      final output = sanitizer.sanitize(input);
      expect(output, isNot(contains('<!DOCTYPE')));
      expect(output, isNot(contains('&xxe;')));
    });

    test('preserves benign currentColor', () {
      final input = readCorpus('benign_currentcolor.svg');
      final output = sanitizer.sanitize(input);
      // XmlDocument.parse might normalize attributes, so we don't expect exact string match
      // but the content should be equivalent and safe.
      expect(output, contains('currentColor'));
      expect(output, contains('<path'));
    });

    test('preserves benign gradients', () {
      final input = readCorpus('benign_gradient.svg');
      final output = sanitizer.sanitize(input);
      expect(output, contains('linearGradient'));
      expect(output, contains('id="grad1"'));
      expect(output, contains('fill="url(#grad1)"'));
    });

    test('preserves benign clipPaths', () {
      final input = readCorpus('benign_clippath.svg');
      final output = sanitizer.sanitize(input);
      expect(output, contains('clipPath'));
      expect(output, contains('id="clip"'));
      expect(output, contains('clip-path="url(#clip)"'));
    });
  });
}
