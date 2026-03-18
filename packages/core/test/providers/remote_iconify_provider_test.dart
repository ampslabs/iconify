import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLivingCacheStorage implements LivingCacheStorage {
  String? content;

  @override
  bool get isReadOnly => false;

  @override
  Future<Uint8List?> readBytes() async {
    return content != null ? Uint8List.fromList(utf8.encode(content!)) : null;
  }

  @override
  Future<void> writeBytes(Uint8List bytes) async {
    content = utf8.decode(bytes);
  }
}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('RemoteIconifyProvider', () {
    late MockHttpClient client;
    late MockLivingCacheStorage storage;
    late LivingCacheProvider livingCache;
    late RemoteIconifyProvider provider;

    setUpAll(() {
      registerFallbackValue(Uri());
    });

    setUp(() {
      client = MockHttpClient();
      storage = MockLivingCacheStorage();
      livingCache = LivingCacheProvider(
        storage: storage,
        debounceDuration: Duration.zero,
      );
      provider = RemoteIconifyProvider(
        httpClient: client,
        livingCache: livingCache,
      );
    });

    test('returns icon data on 200 response', () async {
      const name = IconifyName('mdi', 'home');
      when(() => client.get(any())).thenAnswer((_) async => http.Response(
            jsonEncode({
              'prefix': 'mdi',
              'icons': {
                'home': {'body': '<path d="home"/>'}
              }
            }),
            200,
          ));

      final icon = await provider.getIcon(name);

      expect(icon, isNotNull);
      expect(icon!.body, '<path d="home"/>');
    });

    test('prefers GitHub Raw over API', () async {
      const name = IconifyName('mdi', 'home');

      // 1. Success from GitHub
      when(() => client.get(any(
              that: predicate<Uri>(
                  (u) => u.host == 'raw.githubusercontent.com'))))
          .thenAnswer((_) async => http.Response(
                jsonEncode({
                  'prefix': 'mdi',
                  'icons': {
                    'home': {'body': '<path d="github"/>'}
                  }
                }),
                200,
              ));

      final icon = await provider.getIcon(name);
      expect(icon!.body, '<path d="github"/>');

      verify(() => client.get(any(
          that: predicate<Uri>(
              (u) => u.host == 'raw.githubusercontent.com')))).called(1);
      verifyNever(() => client.get(
          any(that: predicate<Uri>((u) => u.host == 'api.iconify.design'))));
    });

    test('writes back to LivingCache on successful fetch', () async {
      const name = IconifyName('mdi', 'home');
      when(() => client.get(any())).thenAnswer((_) async => http.Response(
            jsonEncode({
              'prefix': 'mdi',
              'icons': {
                'home': {'body': '<path d="home"/>'}
              }
            }),
            200,
          ));

      await provider.getIcon(name);
      await livingCache.flush();

      expect(storage.content, contains('mdi:home'));
    });

    test('respects writeBackEnabled flag', () async {
      final noWriteProvider = RemoteIconifyProvider(
        httpClient: client,
        livingCache: livingCache,
        writeBackEnabled: false,
      );

      const name = IconifyName('mdi', 'home');
      when(() => client.get(any())).thenAnswer((_) async => http.Response(
            jsonEncode({
              'prefix': 'mdi',
              'icons': {
                'home': {'body': '<path d="home"/>'}
              }
            }),
            200,
          ));

      await noWriteProvider.getIcon(name);
      await livingCache.flush();

      // Should not contain the icon
      expect(storage.content, isNot(contains('mdi:home')));
    });

    test('handles API errors gracefully', () async {
      const name = IconifyName('mdi', 'home');

      // GitHub fails
      when(() => client.get(any(
              that: predicate<Uri>(
                  (u) => u.host == 'raw.githubusercontent.com'))))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      // API fails
      when(() => client.get(
              any(that: predicate<Uri>((u) => u.host == 'api.iconify.design'))))
          .thenAnswer((_) async => http.Response('Server Error', 500));

      final icon = await provider.getIcon(name);
      expect(icon, isNull);
    });

    test('automatically batches concurrent requests for the same prefix',
        () async {
      const home = IconifyName('mdi', 'home');
      const account = IconifyName('mdi', 'account');

      when(() => client.get(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response(
          jsonEncode({
            'prefix': 'mdi',
            'icons': {
              'home': {'body': 'home'},
              'account': {'body': 'account'}
            }
          }),
          200,
        );
      });

      final results = await Future.wait([
        provider.getIcon(home),
        provider.getIcon(account),
      ]);

      expect(results[0]!.body, 'home');
      expect(results[1]!.body, 'account');

      // Should only have made one network call for the 'mdi' collection
      verify(() => client.get(any())).called(1);
    });
  });
}
