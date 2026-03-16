import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

/// An [IconifyProvider] that uses SVG Sprite Sheets for optimized web rendering.
///
/// This provider expects an `icons.sprite.svg` file and an `icons.sprite.json`
/// manifest to be present in the asset bundle.
final class SpriteIconifyProvider extends IconifyProvider {
  SpriteIconifyProvider({
    this.assetPath = 'assets/iconify/icons.sprite.svg',
    this.manifestPath = 'assets/iconify/icons.sprite.json',
  });

  final String assetPath;
  final String manifestPath;

  bool _initialized = false;
  Map<String, dynamic>? _manifest;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final manifestContent = await rootBundle.loadString(manifestPath);
      final decoded = jsonDecode(manifestContent) as Map<String, dynamic>;
      _manifest = decoded['icons'] as Map<String, dynamic>?;
    } catch (_) {
      _manifest = null;
    }
    _initialized = true;
  }

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    await _ensureInitialized();
    if (_manifest == null) return null;

    final fullName = name.toString();
    if (!_manifest!.containsKey(fullName)) return null;

    final iconInfo = _manifest![fullName] as Map<String, dynamic>;
    final id = '${name.prefix}-${name.iconName}';

    return IconifyIconData(
      // The HTML renderer can render this <use> tag efficiently
      // when it points to an external SVG file in the assets.
      body: '<use href="$assetPath#$id" />',
      width: (iconInfo['width'] as num?)?.toDouble() ?? 24.0,
      height: (iconInfo['height'] as num?)?.toDouble() ?? 24.0,
    );
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    return null; // Minimal metadata provided by sprite provider
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    await _ensureInitialized();
    return _manifest?.containsKey(name.toString()) ?? false;
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    await _ensureInitialized();
    if (_manifest == null) return false;
    // Check if any icon in the manifest starts with this prefix
    final search = '$prefix:';
    return _manifest!.keys.any((key) => key.startsWith(search));
  }
}
