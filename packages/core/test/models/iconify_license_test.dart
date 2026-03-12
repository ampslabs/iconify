import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import 'package:test/test.dart';

void main() {
  group('IconifyLicense', () {
    test('fromJson and toJson round-trip', () {
      final original = const IconifyLicense(
        title: 'MIT License',
        spdx: 'MIT',
        url: 'https://opensource.org/licenses/MIT',
        requiresAttribution: false,
      );
      final json = original.toJson();
      final decoded = IconifyLicense.fromJson(json);

      expect(decoded.title, original.title);
      expect(decoded.spdx, original.spdx);
      expect(decoded.url, original.url);
      expect(decoded.requiresAttribution, original.requiresAttribution);
    });

    test('isKnownCommercialFriendly identifies safe licenses', () {
      expect(const IconifyLicense(spdx: 'MIT').isKnownCommercialFriendly, isTrue);
      expect(const IconifyLicense(spdx: 'Apache-2.0').isKnownCommercialFriendly, isTrue);
      expect(const IconifyLicense(spdx: 'ISC').isKnownCommercialFriendly, isTrue);
      expect(const IconifyLicense(spdx: 'CC0-1.0').isKnownCommercialFriendly, isTrue);
    });

    test('isKnownCommercialFriendly identifies unsafe or unknown licenses', () {
      expect(const IconifyLicense(spdx: 'CC-BY-4.0').isKnownCommercialFriendly, isFalse);
      expect(const IconifyLicense(spdx: 'GPL-3.0').isKnownCommercialFriendly, isFalse);
      expect(const IconifyLicense(spdx: null).isKnownCommercialFriendly, isFalse);
      expect(const IconifyLicense(spdx: 'Custom').isKnownCommercialFriendly, isFalse);
    });

    test('requiresAttribution defaults to false', () {
      expect(const IconifyLicense().requiresAttribution, isFalse);
    });

    test('copyWith works', () {
      const original = IconifyLicense(spdx: 'MIT');
      final copy = original.copyWith(requiresAttribution: true);
      expect(copy.spdx, 'MIT');
      expect(copy.requiresAttribution, isTrue);
    });

    test('value equality', () {
      expect(
        const IconifyLicense(spdx: 'MIT'),
        equals(const IconifyLicense(spdx: 'MIT')),
      );
      expect(
        const IconifyLicense(spdx: 'MIT'),
        isNot(equals(const IconifyLicense(spdx: 'Apache-2.0'))),
      );
    });
  });
}
