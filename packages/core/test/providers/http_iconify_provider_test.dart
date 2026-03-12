import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../../lib/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteIconifyProvider', () {
    const validIconJson = {
      'prefix': 'mdi',
      'icons': {
        'home': {
          'body': '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>',
        }
      },
      'width': 24,
      'height': 24,
    };

    test('returns icon data on 200 response', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode(validIconJson), 200);
      });

      final provider = RemoteIconifyProvider(httpClient: client);
      final result = await provider.getIcon(const IconifyName('mdi', 'home'));

      expect(result, isNotNull);
      expect(result!.body, contains('M10 20'));
      await provider.dispose();
    });

    test('returns null on 404 response', () async {
      final client = MockClient((_) async => http.Response('not found', 404));
      final provider = RemoteIconifyProvider(httpClient: client);

      expect(await provider.getIcon(const IconifyName('mdi', 'nonexistent')),
          isNull);
      await provider.dispose();
    });

    test('throws IconifyNetworkException on 500 response', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      final provider = RemoteIconifyProvider(httpClient: client);

      expect(
        () => provider.getIcon(const IconifyName('mdi', 'home')),
        throwsA(isA<IconifyNetworkException>()),
      );
      await provider.dispose();
    });

    test('returns null for icon not in response', () async {
      final responseJson = {
        'prefix': 'mdi',
        'icons': {
          'settings': {'body': '<path/>'}
        },
        'width': 24,
        'height': 24,
      };
      final client =
          MockClient((_) async => http.Response(jsonEncode(responseJson), 200));
      final provider = RemoteIconifyProvider(httpClient: client);

      // Request 'home' but response only has 'settings'
      expect(await provider.getIcon(const IconifyName('mdi', 'home')), isNull);
      await provider.dispose();
    });

    test('throws StateError after dispose', () async {
      final provider = RemoteIconifyProvider(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await provider.dispose();

      expect(
        () => provider.getIcon(const IconifyName('mdi', 'home')),
        throwsA(isA<StateError>()),
      );
    });
  });
}
