import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyException Hierarchy', () {
    test('InvalidIconNameException matches requirements', () {
      const exception = InvalidIconNameException(
        input: 'bad_name',
        message: 'Invalid name format',
      );

      expect(exception, isA<IconifyException>());
      expect(exception.input, equals('bad_name'));
      expect(exception.message, equals('Invalid name format'));
      expect(exception.toString(), contains('InvalidIconNameException'));
      expect(exception.toString(), contains('Invalid name format'));
    });

    test('IconNotFoundException matches requirements', () {
      final name = IconifyName.parse('lucide:home');
      final exception = IconNotFoundException(
        name: name,
        message: 'Icon not found',
        suggestion: 'lucide:house',
      );

      expect(exception, isA<IconifyException>());
      expect(exception.name, equals(name));
      expect(exception.message, equals('Icon not found'));
      expect(exception.suggestion, equals('lucide:house'));
      expect(exception.toString(), contains('IconNotFoundException'));
      expect(exception.toString(), contains('Icon not found'));
    });

    test('CollectionNotFoundException matches requirements', () {
      const exception = CollectionNotFoundException(
        prefix: 'mdi',
        message: 'Collection not found',
        wasRemoteAttempted: true,
      );

      expect(exception, isA<IconifyException>());
      expect(exception.prefix, equals('mdi'));
      expect(exception.message, equals('Collection not found'));
      expect(exception.wasRemoteAttempted, isTrue);
      expect(exception.toString(), contains('CollectionNotFoundException'));
      expect(exception.toString(), contains('Collection not found'));
    });

    test('IconifyNetworkException matches requirements', () {
      final uri = Uri.parse('https://api.iconify.design/mdi.json');
      final exception = IconifyNetworkException(
        message: 'Network error',
        statusCode: 404,
        uri: uri,
      );

      expect(exception, isA<IconifyException>());
      expect(exception.message, equals('Network error'));
      expect(exception.statusCode, equals(404));
      expect(exception.uri, equals(uri));
      expect(exception.toString(), contains('IconifyNetworkException'));
      expect(exception.toString(), contains('Network error'));
    });

    test('IconifyLicenseException matches requirements', () {
      const exception = IconifyLicenseException(
        prefix: 'mdi',
        message: 'License missing',
      );

      expect(exception, isA<IconifyException>());
      expect(exception.prefix, equals('mdi'));
      expect(exception.message, equals('License missing'));
      expect(exception.toString(), contains('IconifyLicenseException'));
      expect(exception.toString(), contains('License missing'));
    });

    test('IconifyParseException matches requirements', () {
      const exception = IconifyParseException(
        message: 'Parse failed',
        field: 'icons',
        rawValue: {'invalid': 'data'},
      );

      expect(exception, isA<IconifyException>());
      expect(exception.message, equals('Parse failed'));
      expect(exception.field, equals('icons'));
      expect(exception.rawValue, equals({'invalid': 'data'}));
      expect(exception.toString(), contains('IconifyParseException'));
      expect(exception.toString(), contains('Parse failed'));
    });

    test('CircularAliasException matches requirements', () {
      const chain = ['a', 'b', 'a'];
      const exception = CircularAliasException(
        chain: chain,
        message: 'Circular alias detected',
      );

      expect(exception, isA<IconifyException>());
      expect(exception.chain, equals(chain));
      expect(exception.message, equals('Circular alias detected'));
      expect(exception.toString(), contains('CircularAliasException'));
      expect(exception.toString(), contains('Circular alias detected'));
    });

    test('IconifyCacheException matches requirements', () {
      final cause = StateError('FileSystem error');
      final exception = IconifyCacheException(
        message: 'Cache error',
        cause: cause,
      );

      expect(exception, isA<IconifyException>());
      expect(exception.message, equals('Cache error'));
      expect(exception.cause, equals(cause));
      expect(exception.toString(), contains('IconifyCacheException'));
      expect(exception.toString(), contains('Cache error'));
    });

    test('Pattern matching works for all subtypes', () {
      final exceptions = <IconifyException>[
        const InvalidIconNameException(input: '', message: ''),
        IconNotFoundException(name: IconifyName.parse('a:b'), message: ''),
        const CollectionNotFoundException(prefix: '', message: ''),
        const IconifyNetworkException(message: ''),
        const IconifyLicenseException(prefix: '', message: ''),
        const IconifyParseException(message: ''),
        const CircularAliasException(chain: [], message: ''),
        const SvgSanitizationException(message: ''),
        const IconifyCacheException(message: ''),
      ];

      for (final e in exceptions) {
        final result = switch (e) {
          InvalidIconNameException() => 'invalid_name',
          IconNotFoundException() => 'icon_not_found',
          CollectionNotFoundException() => 'collection_not_found',
          IconifyNetworkException() => 'network',
          IconifyLicenseException() => 'license',
          IconifyParseException() => 'parse',
          CircularAliasException() => 'circular',
          SvgSanitizationException() => 'sanitization',
          IconifyCacheException() => 'cache',
        };
        expect(result, isNotEmpty);
      }
    });
  });
}
