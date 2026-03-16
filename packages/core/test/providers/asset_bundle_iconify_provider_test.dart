import 'dart:convert';
import 'dart:typed_data';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

class MockAssetBundleProvider extends AssetBundleIconifyProvider {
  MockAssetBundleProvider({required super.assetPrefix});

  final Map<String, String> assets = {};

  @override
  Future<Uint8List> loadAssetBytes(String path) async {
    if (assets.containsKey(path)) {
      return Uint8List.fromList(utf8.encode(assets[path]!));
    }
    throw Exception('Asset not found');
  }
}

void main() {
  group('AssetBundleIconifyProvider', () {
    late MockAssetBundleProvider provider;

    setUp(() {
      provider = MockAssetBundleProvider(assetPrefix: 'assets');
      provider.assets['assets/test.json'] = jsonEncode({
        'prefix': 'test',
        'icons': {
          'home': {'body': '<path d="home"/>'}
        }
      });
    });

    test('getIcon loads from asset string', () async {
      final icon = await provider.getIcon(const IconifyName('test', 'home'));
      expect(icon, isNotNull);
      expect(icon!.body, '<path d="home"/>');
    });

    test('getCollection loads from asset string', () async {
      final info = await provider.getCollection('test');
      expect(info, isNotNull);
      expect(info!.prefix, 'test');
    });

    test('hasIcon returns true for existing asset', () async {
      expect(await provider.hasIcon(const IconifyName('test', 'home')), isTrue);
    });

    test('hasCollection returns true for existing asset', () async {
      expect(await provider.hasCollection('test'), isTrue);
    });

    test('returns null on failure', () async {
      final icon = await provider.getIcon(const IconifyName('missing', 'icon'));
      expect(icon, isNull);
    });
  });
}
