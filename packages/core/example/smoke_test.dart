// ignore_for_file: avoid_print // Smoke test needs to output results to the console.
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

Future<void> main() async {
  var passed = 0;
  var failed = 0;

  Future<void> check(String label, Future<void> Function() fn) async {
    try {
      await fn();
      print('  ✅ $label');
      passed++;
    } catch (e) {
      print('  ❌ $label: $e');
      failed++;
    }
  }

  print('\n=== iconify_sdk_core Phase 1 Smoke Test ===\n');

  print('[ Model parsing ]');

  await check('IconifyName parses mdi:home', () async {
    final name = IconifyName.parse('mdi:home');
    assert(name.prefix == 'mdi');
    assert(name.iconName == 'home');
    assert(name.toString() == 'mdi:home');
  });

  await check('IconifyName throws on mdi-home', () async {
    try {
      IconifyName.parse('mdi-home');
      throw Exception('should have thrown');
    } on InvalidIconNameException {
      // expected
    }
  });

  await check('IconifyName equality', () async {
    assert(
        const IconifyName('mdi', 'home') == const IconifyName('mdi', 'home'));
    assert(const IconifyName('mdi', 'home') !=
        const IconifyName('mdi', 'settings'));
  });

  await check('IconifyName as Map key', () async {
    final map = {const IconifyName('mdi', 'home'): 42};
    assert(map[const IconifyName('mdi', 'home')] == 42);
  });

  print('\n[ Memory Provider ]');

  await check('MemoryIconifyProvider put and get', () async {
    final provider = MemoryIconifyProvider();
    final data = const IconifyIconData(body: '<path/>');
    provider.putIcon(const IconifyName('mdi', 'home'), data);
    final result = await provider.getIcon(const IconifyName('mdi', 'home'));
    assert(result != null);
  });

  await check('MemoryIconifyProvider returns null for missing', () async {
    final provider = MemoryIconifyProvider();
    assert(await provider.getIcon(const IconifyName('mdi', 'ghost')) == null);
  });

  print('\n[ LRU Cache ]');

  await check('LRU cache put/get round-trip', () async {
    final cache = LruIconifyCache(maxEntries: 10);
    final data = const IconifyIconData(body: '<path/>');
    await cache.put(const IconifyName('mdi', 'home'), data);
    assert(await cache.get(const IconifyName('mdi', 'home')) != null);
  });

  await check('LRU eviction at capacity', () async {
    final cache = LruIconifyCache(maxEntries: 2);
    final data = const IconifyIconData(body: '<path/>');
    await cache.put(const IconifyName('mdi', 'a'), data);
    await cache.put(const IconifyName('mdi', 'b'), data);
    await cache.put(const IconifyName('mdi', 'c'), data); // evicts 'a'
    assert(await cache.contains(const IconifyName('mdi', 'a')) == false);
    assert(await cache.contains(const IconifyName('mdi', 'c')) == true);
  });

  print('\n[ Alias Resolver ]');

  await check('Resolves direct icon', () async {
    const resolver = AliasResolver();
    final icons = {'home': const IconifyIconData(body: '<path d="home"/>')};
    final result = resolver.resolve(
      iconName: 'home',
      icons: icons,
      aliases: {},
      defaultWidth: 24,
      defaultHeight: 24,
    );
    assert(result != null);
  });

  await check('Resolves 3-level alias chain', () async {
    const resolver = AliasResolver();
    final icons = {'base': const IconifyIconData(body: '<path/>')};
    final aliases = {
      'l1': const AliasEntry(parent: 'base'),
      'l2': const AliasEntry(parent: 'l1'),
      'l3': const AliasEntry(parent: 'l2'),
    };
    final result = resolver.resolve(
      iconName: 'l3',
      icons: icons,
      aliases: aliases,
      defaultWidth: 24,
      defaultHeight: 24,
    );
    assert(result != null);
  });

  await check('Throws on circular alias', () async {
    const resolver = AliasResolver();
    final aliases = {
      'a': const AliasEntry(parent: 'b'),
      'b': const AliasEntry(parent: 'a'),
    };
    try {
      resolver.resolve(
        iconName: 'a',
        icons: {},
        aliases: aliases,
        defaultWidth: 24,
        defaultHeight: 24,
      );
      throw Exception('should have thrown');
    } on CircularAliasException {
      // expected
    }
  });

  print('\n[ JSON Parser ]');

  await check('Parses minimal collection JSON', () async {
    const json = '''
    {
      "prefix": "test",
      "width": 24,
      "height": 24,
      "icons": {
        "home": { "body": "<path d='test'/>" }
      }
    }
    ''';
    final result = IconifyJsonParser.parseCollectionString(json);
    assert(result.prefix == 'test');
    assert(result.icons.containsKey('home'));
  });

  await check('Parser handles alias in JSON', () async {
    const json = '''
    {
      "prefix": "test",
      "width": 24,
      "height": 24,
      "icons": {
        "base": { "body": "<path/>" }
      },
      "aliases": {
        "alias1": { "parent": "base" }
      }
    }
    ''';
    final collection = IconifyJsonParser.parseCollectionString(json);
    assert(collection.getIcon('alias1') != null);
  });

  print('\n[ Caching Provider ]');

  await check('CachingIconifyProvider caches on second call', () async {
    final underlying = MemoryIconifyProvider();
    underlying.putIcon(
      const IconifyName('mdi', 'home'),
      const IconifyIconData(body: '<path/>'),
    );
    final provider = CachingIconifyProvider(inner: underlying);

    await provider.getIcon(const IconifyName('mdi', 'home')); // miss
    await provider.getIcon(const IconifyName('mdi', 'home')); // hit

    assert(provider.hits == 1);
    assert(provider.misses == 1);
  });

  print('\n[ DevModeGuard ]');

  await check('DevModeGuard allows remote in debug/test mode', () async {
    assert(DevModeGuard.isRemoteAllowedInCurrentBuild() == true);
  });

  await check('DevModeGuard override works', () async {
    DevModeGuard.allowRemoteInRelease();
    assert(DevModeGuard.isRemoteAllowedInCurrentBuild() == true);
    DevModeGuard.resetOverride();
  });

  print('\n[ SVG Generation ]');

  await check('toSvgString wraps body correctly', () async {
    final data = const IconifyIconData(
      body: '<path d="M0 0" fill="currentColor"/>',
      width: 24,
      height: 24,
    );
    final svg = data.toSvgString(size: 48, color: '#FF0000');
    assert(svg.contains('viewBox="0 0 24.0 24.0"'));
    assert(svg.contains('width="48.0"'));
    assert(svg.contains('#FF0000'));
    assert(!svg.contains('currentColor'));
  });

  await check('isMonochrome detects currentColor', () async {
    final mono = const IconifyIconData(body: '<path fill="currentColor"/>');
    final multi = const IconifyIconData(body: '<path fill="#FF0000"/>');
    assert(mono.isMonochrome == true);
    assert(multi.isMonochrome == false);
  });

  print('\n═══════════════════════════════════════');
  print('Results: $passed passed, $failed failed');
  if (failed > 0) {
    print('❌ Phase 1 smoke test FAILED');
    throw Exception('$failed tests failed');
  } else {
    print('✅ Phase 1 smoke test PASSED');
  }
  print('═══════════════════════════════════════\n');
}
