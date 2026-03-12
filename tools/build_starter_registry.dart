// This is a CLI build tool, so printing to console is expected.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// The primary data source for Iconify icon sets.
const githubRawBase =
    'https://raw.githubusercontent.com/iconify/icon-sets/master';

/// Target directory for the generated starter registry assets.
const targetDir = 'packages/sdk/assets/iconify/starter';

/// The curated list of starter collections and their inclusion rules.
const starterCollections = {
  'mdi': 150, // Top 150 Material Design Icons
  'lucide': 100, // Top 100 Lucide icons
  'tabler': 100, // Top 100 Tabler icons
  'heroicons': 150, // Top 150 Heroicons
};

/// A list of common icon names used to "simulated" the most popular icons
/// when an official usage ranking is not available.
const popularNames = [
  'home',
  'account',
  'settings',
  'search',
  'menu',
  'close',
  'check',
  'chevron-right',
  'chevron-left',
  'chevron-down',
  'chevron-up',
  'plus',
  'minus',
  'delete',
  'edit',
  'calendar',
  'clock',
  'camera',
  'image',
  'video',
  'music',
  'heart',
  'star',
  'flag',
  'bell',
  'mail',
  'send',
  'share',
  'download',
  'upload',
  'link',
  'lock',
  'unlock',
  'eye',
  'eye-off',
  'map-marker',
  'phone',
  'smartphone',
  'laptop',
  'desktop',
  'monitor',
  'wifi',
  'bluetooth',
  'battery',
  'shopping-cart',
  'credit-card',
  'bank',
  'wallet',
  'briefcase',
  'database',
  'cloud',
  'cloud-upload',
  'cloud-download',
  'folder',
  'file',
  'copy',
  'clipboard',
  'printer',
  'trash',
  'info',
  'alert',
  'help',
  'question',
  'error',
  'warning',
  'success',
  'arrow-right',
  'arrow-left',
  'arrow-up',
  'arrow-down',
  'refresh',
  'sync',
  'cog',
  'filter',
  'sort',
  'list',
  'grid',
  'table',
  'play',
  'pause',
  'stop',
  'skip-next',
  'skip-prev',
  'repeat',
  'shuffle',
  'volume-up',
  'volume-off',
  'mic',
  'headset',
  'cast',
  'tv',
  'radio',
  'sun',
  'moon',
  'cloud-sun',
  'cloud-moon',
  'wind',
  'water',
  'thermometer',
  'gauge',
  'speedometer',
  'tools',
  'hammer',
  'wrench',
  'pen',
  'brush',
  'palette',
  'color-helper',
  'eye-dropper',
  'format-text',
  'bold',
  'italic',
  'underline',
  'align-left',
  'align-center',
  'align-right',
  'align-justify',
  'zoom-in',
  'zoom-out',
  'maximize',
  'minimize',
  'fullscreen',
  'exit-to-app',
  'logout',
  'login',
  'fingerprint',
  'key',
  'security',
  'shield',
  'fire',
  'leaf',
  'tree',
  'flower',
  'coffee',
  'food',
  'pizza',
  'car',
  'bus',
  'train',
  'airplane',
  'bike',
  'walk',
  'run',
  'swim',
  'medkit',
  'heart-pulse',
  'hospital',
  'doctor',
  'shield-check',
  'verified',
];

Future<void> main() async {
  print('🚀 Building Iconify Starter Registry...');

  // 1. Ensure target directory exists
  final dir = Directory(targetDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final client = http.Client();

  try {
    // 2. Fetch global collections metadata
    print('📥 Fetching global collections metadata...');
    final collectionsResponse =
        await client.get(Uri.parse('$githubRawBase/collections.json'));
    if (collectionsResponse.statusCode != 200) {
      throw Exception(
          'Failed to fetch collections.json: ${collectionsResponse.statusCode}');
    }

    final Map<String, dynamic> allCollections =
        jsonDecode(collectionsResponse.body) as Map<String, dynamic>;

    // Save minimal manifest
    final manifestPath = p.join(targetDir, 'starter_manifest.json');
    File(manifestPath).writeAsStringSync(jsonEncode(allCollections));
    print('✅ Saved manifest with ${allCollections.length} collections.');

    // 3. Fetch and trim starter collections
    int totalSize = 0;

    for (final entry in starterCollections.entries) {
      final prefix = entry.key;
      final limit = entry.value;

      print('📥 Processing $prefix (limit: ${limit == -1 ? "all" : limit})...');

      final response =
          await client.get(Uri.parse('$githubRawBase/json/$prefix.json'));
      if (response.statusCode != 200) {
        print('  ❌ Failed to fetch $prefix.json');
        continue;
      }

      final Map<String, dynamic> fullData =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> icons =
          fullData['icons'] as Map<String, dynamic>;

      final Map<String, dynamic> trimmedIcons = {};
      final List<String> includedNames = [];

      if (limit == -1) {
        // Include all
        trimmedIcons.addAll(icons);
        includedNames.addAll(icons.keys);
      } else {
        // Filter by popular names first
        for (final name in popularNames) {
          if (icons.containsKey(name)) {
            trimmedIcons[name] = icons[name];
            includedNames.add(name);
          }
          if (includedNames.length >= limit) break;
        }

        // If we still have room, add from the beginning of the set
        if (includedNames.length < limit) {
          for (final name in icons.keys) {
            if (!trimmedIcons.containsKey(name)) {
              trimmedIcons[name] = icons[name];
              includedNames.add(name);
            }
            if (includedNames.length >= limit) break;
          }
        }
      }

      // Preserve aliases for included icons
      final Map<String, dynamic> trimmedAliases = {};
      final Map<String, dynamic>? aliases =
          fullData['aliases'] as Map<String, dynamic>?;
      if (aliases != null) {
        for (final entry in aliases.entries) {
          final aliasData = entry.value as Map<String, dynamic>;
          final parent = aliasData['parent'] as String;
          if (includedNames.contains(parent)) {
            trimmedAliases[entry.key] = aliasData;
          }
        }
      }

      final trimmedData = {
        'prefix': prefix,
        'icons': trimmedIcons,
        if (trimmedAliases.isNotEmpty) 'aliases': trimmedAliases,
        'width': fullData['width'],
        'height': fullData['height'],
      };

      final outputPath = p.join(targetDir, '$prefix.json');
      final encoded = jsonEncode(trimmedData);
      File(outputPath).writeAsStringSync(encoded);

      totalSize += encoded.length;
      print(
          '  ✅ Saved $prefix.json (${trimmedIcons.length} icons, ${trimmedAliases.length} aliases, ${(encoded.length / 1024).toStringAsFixed(1)} KB)');
    }

    print(
        '\n📊 Total registry size: ${(totalSize / 1024).toStringAsFixed(1)} KB');
    if (totalSize > 200 * 1024) {
      print('⚠️ WARNING: Registry size exceeds 200KB budget!');
    } else {
      print('✅ Budget check passed (< 200KB).');
    }
  } finally {
    client.close();
  }
}
