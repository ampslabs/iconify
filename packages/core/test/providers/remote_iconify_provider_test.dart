import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

class MockLivingCacheStorage implements LivingCacheStorage {
  String? content;
  @override
  Future<String?> read() async => content;
  @override
  Future<void> write(String content) async => this.content = content;
}

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
        // Return 404 for GitHub to test the API fallback in this specific test
        if (request.url.host == 'raw.githubusercontent.com') {
          return http.Response('not found', 404);
        }
        return http.Response(jsonEncode(validIconJson), 200);
      });

      final provider = RemoteIconifyProvider(httpClient: client);
      final result = await provider.getIcon(const IconifyName('mdi', 'home'));

      expect(result, isNotNull);
      expect(result!.body, contains('M10 20'));
      await provider.dispose();
    });

    test('prefers GitHub Raw over API', () async {
      var githubCalled = false;
      var apiCalled = false;

      final client = MockClient((request) async {
        if (request.url.host == 'raw.githubusercontent.com') {
          githubCalled = true;
          return http.Response(jsonEncode(validIconJson), 200);
        }
        if (request.url.host == 'api.iconify.design') {
          apiCalled = true;
          return http.Response(jsonEncode(validIconJson), 200);
        }
        return http.Response('error', 500);
      });

      final provider = RemoteIconifyProvider(httpClient: client);
      await provider.getIcon(const IconifyName('mdi', 'home'));

      expect(githubCalled, isTrue);
      expect(apiCalled, isFalse);
      await provider.dispose();
    });

    test('writes back to LivingCache on successful fetch', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode(validIconJson), 200);
      });

      final storage = MockLivingCacheStorage();
      final livingCache = LivingCacheProvider(storage: storage);
      final provider = RemoteIconifyProvider(
        httpClient: client,
        livingCache: livingCache,
      );

      final name = const IconifyName('mdi', 'home');
      await provider.getIcon(name);

      // LivingCache debounces by default (500ms)
      // Manually flush to see results immediately
      await livingCache.flush();

      expect(storage.content, contains('mdi:home'));
      expect(storage.content, contains('"source": "remote"'));

      await provider.dispose();
    });

    test('respects writeBackEnabled flag', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode(validIconJson), 200);
      });

      final storage = MockLivingCacheStorage();
      final livingCache = LivingCacheProvider(storage: storage);
      final provider = RemoteIconifyProvider(
        httpClient: client,
        livingCache: livingCache,
        writeBackEnabled: false,
      );

      await provider.getIcon(const IconifyName('mdi', 'home'));
      await livingCache.flush();

      // Should be an empty icons map, not necessarily null because flush writes the schema
      expect(storage.content, contains('"icons": {}'));
      await provider.dispose();
    });

    test('handles API errors gracefully', () async {
      final client = MockClient((request) async {
        return http.Response('error', 500);
      });

      final provider = RemoteIconifyProvider(httpClient: client);
      final result = await provider.getIcon(const IconifyName('mdi', 'home'));

      expect(result, isNull);
      await provider.dispose();
    });

    test('automatically batches concurrent requests for the same prefix',
        () async {
      var callCount = 0;
      final client = MockClient((request) async {
        // Return 404 for GitHub to test the API fallback in this specific test
        if (request.url.host == 'raw.githubusercontent.com') {
          return http.Response('not found', 404);
        }
        callCount++;
        return http.Response(
          jsonEncode({
            'prefix': 'mdi',
            'icons': {
              'home': {'body': 'home'},
              'account': {'body': 'account'},
            }
          }),
          200,
        );
      });

      final provider = RemoteIconifyProvider(
        httpClient: client,
        batchWindow: const Duration(milliseconds: 10),
      );

      final results = await Future.wait([
        provider.getIcon(const IconifyName('mdi', 'home')),
        provider.getIcon(const IconifyName('mdi', 'account')),
      ]);

      expect(results[0]?.body, 'home');
      expect(results[1]?.body, 'account');
      expect(callCount, 1);
      await provider.dispose();
    });

    test('getCollection returns info', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'name': 'Material Design Icons',
            'total': 7000,
            'license': {'title': 'Apache 2.0'},
          }),
          200,
        );
      });

      final provider = RemoteIconifyProvider(httpClient: client);
      final info = await provider.getCollection('mdi');

      expect(info, isNotNull);
      expect(info!.name, 'Material Design Icons');
      await provider.dispose();
    });
  });
}
