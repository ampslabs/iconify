import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
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

      await expectLater(
        provider.getIcon(const IconifyName('mdi', 'home')),
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

    test('getCollection returns info on 200', () async {
      final responseJson = {
        'info': {
          'name': 'Material Design Icons',
          'total': 7446,
        }
      };
      final client =
          MockClient((_) async => http.Response(jsonEncode(responseJson), 200));
      final provider = RemoteIconifyProvider(httpClient: client);

      final result = await provider.getCollection('mdi');
      expect(result?.name, 'Material Design Icons');
      await provider.dispose();
    });

    test('hasIcon returns true on success', () async {
      final client = MockClient(
          (_) async => http.Response(jsonEncode(validIconJson), 200));
      final provider = RemoteIconifyProvider(httpClient: client);

      expect(await provider.hasIcon(const IconifyName('mdi', 'home')), isTrue);
      await provider.dispose();
    });

    test('hasCollection returns true on success', () async {
      final responseJson = {
        'info': {'name': 'MDI'}
      };
      final client =
          MockClient((_) async => http.Response(jsonEncode(responseJson), 200));
      final provider = RemoteIconifyProvider(httpClient: client);

      expect(await provider.hasCollection('mdi'), isTrue);
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

    group('batching', () {
      test('batches multiple concurrent requests into one HTTP call', () async {
        var callCount = 0;
        final client = MockClient((request) async {
          callCount++;
          // Verify URL contains both icons
          expect(request.url.queryParameters['icons'], contains('home'));
          expect(request.url.queryParameters['icons'], contains('settings'));

          return http.Response(
              jsonEncode({
                'prefix': 'mdi',
                'icons': {
                  'home': {'body': '<path d="home"/>'},
                  'settings': {'body': '<path d="settings"/>'},
                },
                'width': 24,
                'height': 24,
              }),
              200);
        });

        final provider = RemoteIconifyProvider(
          httpClient: client,
          batchWindow: const Duration(milliseconds: 10),
        );

        // Trigger two concurrent requests
        final future1 = provider.getIcon(const IconifyName('mdi', 'home'));
        final future2 = provider.getIcon(const IconifyName('mdi', 'settings'));

        final results = await Future.wait([future1, future2]);

        expect(results[0]?.body, contains('home'));
        expect(results[1]?.body, contains('settings'));
        expect(callCount, 1, reason: 'Should have only made one HTTP call');

        await provider.dispose();
      });

      test('handles partial batch success (some icons missing)', () async {
        final client = MockClient((request) async {
          return http.Response(
              jsonEncode({
                'prefix': 'mdi',
                'icons': {
                  'home': {'body': '<path d="home"/>'},
                  // 'settings' is missing from response
                },
              }),
              200);
        });

        final provider = RemoteIconifyProvider(
          httpClient: client,
          batchWindow: const Duration(milliseconds: 10),
        );

        final future1 = provider.getIcon(const IconifyName('mdi', 'home'));
        final future2 = provider.getIcon(const IconifyName('mdi', 'settings'));

        final results = await Future.wait([future1, future2]);

        expect(results[0], isNotNull);
        expect(results[1], isNull,
            reason: 'Missing icon in batch should return null');

        await provider.dispose();
      });

      test('fails all requests in batch if HTTP call fails', () async {
        final client = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final provider = RemoteIconifyProvider(
          httpClient: client,
          batchWindow: const Duration(milliseconds: 10),
        );

        final future1 = provider.getIcon(const IconifyName('mdi', 'home'));
        final future2 = provider.getIcon(const IconifyName('mdi', 'settings'));

        await expectLater(future1, throwsA(isA<IconifyNetworkException>()));
        await expectLater(future2, throwsA(isA<IconifyNetworkException>()));

        await provider.dispose();
      });
    });
  });
}
