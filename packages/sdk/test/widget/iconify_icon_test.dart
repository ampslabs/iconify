import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconify_sdk/iconify_sdk.dart';
import 'package:iconify_sdk/src/config/provider_chain_builder.dart';
import 'package:iconify_sdk/src/registry/starter_registry.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

void main() {
  group('IconifyIcon', () {
    late MemoryIconifyProvider provider;
    const home = IconifyName('mdi', 'home');
    const homeData = IconifyIconData(
      body:
          '<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" fill="currentColor"/>',
    );

    setUp(() {
      provider = MemoryIconifyProvider();
      provider.putIcon(home, homeData);
    });

    Widget wrap(Widget child) {
      return MaterialApp(
        home: IconifyScope(
          provider: provider,
          child: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets('renders SvgPicture when icon is found', (tester) async {
      await tester.pumpWidget(wrap(IconifyIcon('mdi:home')));
      await tester.pump(); // Allow Future to resolve

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('applies color override', (tester) async {
      const targetColor = Colors.red;
      await tester
          .pumpWidget(wrap(IconifyIcon('mdi:home', color: targetColor)));
      await tester.pump();

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('shows IconifyErrorWidget when icon not found', (tester) async {
      await tester.pumpWidget(wrap(IconifyIcon('mdi:missing')));
      await tester.pump();

      expect(find.byType(IconifyErrorWidget), findsOneWidget);
    });

    testWidgets('uses custom errorBuilder', (tester) async {
      await tester.pumpWidget(wrap(
        IconifyIcon(
          'mdi:missing',
          errorBuilder: (context, error) => const Text('Custom Error'),
        ),
      ));
      await tester.pump();

      expect(find.text('Custom Error'), findsOneWidget);
    });

    testWidgets('uses custom loadingBuilder', (tester) async {
      await tester.pumpWidget(wrap(
        IconifyIcon(
          'mdi:home',
          loadingBuilder: (context) => const Text('Loading...'),
        ),
      ));

      expect(find.text('Loading...'), findsOneWidget);

      await tester.pump();
      expect(find.text('Loading...'), findsNothing);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('IconifyApp initializes with default provider chain',
        (tester) async {
      // Manually initialize the registry to ensure it's ready for the test
      // because PubCachePathResolver might behave differently in test environments.
      await tester.runAsync(() async {
        await StarterRegistry.instance.initialize();
      });

      await tester.pumpWidget(IconifyApp(
        child: MaterialApp(
          home: Scaffold(
            body: IconifyIcon('mdi:home'),
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(IconifyIcon), findsOneWidget);
    });

    testWidgets('blocks remote fetching in release mode by default',
        (tester) async {
      DevModeGuard.resetOverride();
      const config = IconifyConfig(mode: IconifyMode.auto);
      final chain = buildProviderChain(config);
      expect(chain, isA<CachingIconifyProvider>());
    });
  });
}
