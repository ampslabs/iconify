import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

class TestAssetBundleProvider extends AssetBundleIconifyProvider {
  TestAssetBundleProvider({required super.assetPrefix, required this.assets});

  final Map<String, String> assets;

  @override
  Future<String> loadAssetString(String path) async {
    final content = assets[path];
    if (content == null) throw Exception('Asset not found');
    return content;
  }
}

void main() {
  group('AssetBundleIconifyProvider', () {
    const json = '''
    {
      "prefix": "test",
      "icons": {
        "home": { "body": "<path/>" }
      }
    }
    ''';

    late TestAssetBundleProvider provider;

    setUp(() {
      provider = TestAssetBundleProvider(
        assetPrefix: 'assets',
        assets: {'assets/test.json': json},
      );
    });

    test('getIcon loads from asset string', () async {
      final icon = await provider.getIcon(const IconifyName('test', 'home'));
      expect(icon, isNotNull);
    });

    test('getCollection loads from asset string', () async {
      final collection = await provider.getCollection('test');
      expect(collection?.prefix, 'test');
    });

    test('hasIcon returns true for existing asset', () async {
      expect(await provider.hasIcon(const IconifyName('test', 'home')), isTrue);
    });

    test('hasCollection returns true for existing asset', () async {
      expect(await provider.hasCollection('test'), isTrue);
    });

    test('returns null on failure', () async {
      expect(await provider.getCollection('missing'), isNull);
    });
  });
}
