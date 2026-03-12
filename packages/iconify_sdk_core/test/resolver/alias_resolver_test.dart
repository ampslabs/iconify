import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  final baseIcon =
      IconifyIconData(body: '<path d="M0 0"/>', width: 24, height: 24);

  final icons = {'base': baseIcon, 'other': IconifyIconData(body: '<rect/>')};

  group('AliasResolver', () {
    const resolver = AliasResolver();

    test('returns direct icon when no alias needed', () {
      final result = resolver.resolve(
        iconName: 'base',
        icons: icons,
        aliases: {},
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result, isNotNull);
      expect(result!.body, baseIcon.body);
    });

    test('returns null for unknown icon and no alias', () {
      final result = resolver.resolve(
        iconName: 'nonexistent',
        icons: icons,
        aliases: {},
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result, isNull);
    });

    test('resolves depth-1 alias', () {
      final aliases = {'base-alias': AliasEntry(parent: 'base')};
      final result = resolver.resolve(
        iconName: 'base-alias',
        icons: icons,
        aliases: aliases,
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result?.body, baseIcon.body);
    });

    test('resolves depth-2 alias chain', () {
      final aliases = {
        'level1': AliasEntry(parent: 'base'),
        'level2': AliasEntry(parent: 'level1'),
      };
      final result = resolver.resolve(
        iconName: 'level2',
        icons: icons,
        aliases: aliases,
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result?.body, baseIcon.body);
    });

    test('applies width/height overrides from alias', () {
      final aliases = {
        'big-base': AliasEntry(parent: 'base', width: 48, height: 48),
      };
      final result = resolver.resolve(
        iconName: 'big-base',
        icons: icons,
        aliases: aliases,
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result?.width, 48);
      expect(result?.height, 48);
    });

    test('nearest override wins in chain', () {
      final aliases = {
        'level1': AliasEntry(parent: 'base', width: 48),
        'level2': AliasEntry(parent: 'level1', width: 32),
      };
      final result = resolver.resolve(
        iconName: 'level2',
        icons: icons,
        aliases: aliases,
        defaultWidth: 24,
        defaultHeight: 24,
      );
      expect(result?.width, 32);
    });

    test('throws CircularAliasException on cycle', () {
      final aliases = {
        'a': AliasEntry(parent: 'b'),
        'b': AliasEntry(parent: 'a'),
      };
      expect(
        () => resolver.resolve(
          iconName: 'a',
          icons: {},
          aliases: aliases,
          defaultWidth: 24,
          defaultHeight: 24,
        ),
        throwsA(isA<CircularAliasException>()),
      );
    });

    test('CircularAliasException includes the full chain', () {
      final aliases = {
        'a': AliasEntry(parent: 'b'),
        'b': AliasEntry(parent: 'a'),
      };
      try {
        resolver.resolve(
          iconName: 'a',
          icons: {},
          aliases: aliases,
          defaultWidth: 24,
          defaultHeight: 24,
        );
        fail('should have thrown');
      } on CircularAliasException catch (e) {
        expect(e.chain, containsAll(['a', 'b']));
      }
    });

    test('throws CircularAliasException after max depth', () {
      const depth = 12;
      final aliases = <String, AliasEntry>{};
      for (var i = 0; i < depth; i++) {
        aliases['icon$i'] = AliasEntry(parent: 'icon${i + 1}');
      }
      const shortResolver = AliasResolver(maxChainDepth: 5);
      expect(
        () => shortResolver.resolve(
          iconName: 'icon0',
          icons: {},
          aliases: aliases,
          defaultWidth: 24,
          defaultHeight: 24,
        ),
        throwsA(isA<CircularAliasException>()),
      );
    });
  });
}
