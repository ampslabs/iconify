import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:iconify_sdk_builder/builder.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyBuilder', () {
    test('generates icons.g.dart from source usages', () async {
      await testBuilder(
        iconifyBuilder(BuilderOptions.empty),
        {
          'a|iconify.yaml': '''
sets:
  - mdi:*
data_dir: assets/iconify
output: lib/icons.g.dart
''',
          'a|assets/iconify/mdi.json': '''
{
  "prefix": "mdi",
  "icons": {
    "home": { "body": "<path d='home'/>" }
  },
  "width": 24,
  "height": 24
}
''',
          'a|lib/main.dart': '''
import 'package:iconify_sdk/iconify_sdk.dart';
final icon = IconifyIcon('mdi:home');
''',
        },
        outputs: {
          'a|lib/icons.g.dart': decodedMatches(contains('class IconsMdi')),
        },
      );
    });

    test('skips when no icons detected', () async {
      await testBuilder(
        iconifyBuilder(BuilderOptions.empty),
        {
          'a|lib/main.dart': 'void main() {}',
        },
        outputs: {},
      );
    });
  });
}
