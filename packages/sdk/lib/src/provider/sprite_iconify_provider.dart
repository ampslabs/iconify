import 'package:flutter/services.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';

/// An [IconifyProvider] that uses SVG Sprite Sheets for optimized web rendering.
///
/// This provider expects an `icons.sprite.svg` file to be present in the
/// asset bundle. It returns lightweight [IconifyIconData] that uses the
/// `<use>` tag to reference symbols within the sprite sheet.
final class SpriteIconifyProvider extends IconifyProvider {
  SpriteIconifyProvider({
    this.assetPath = 'assets/iconify/icons.sprite.svg',
  });

  final String assetPath;
  bool _manifestChecked = false;
  Set<String>? _availableIcons;

  Future<void> _ensureManifest() async {
    if (_manifestChecked) return;
    try {
      // In a real implementation, we might have a small JSON manifest
      // telling us which icons are in the sprite sheet.
      // For now, we assume if the sprite file exists, it contains the used icons.
      await rootBundle.load(assetPath);
      _availableIcons = {}; // Empty means "unknown but file exists"
    } catch (_) {
      _availableIcons = null;
    }
    _manifestChecked = true;
  }

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    await _ensureManifest();
    if (_availableIcons == null) return null;

    final id = '${name.prefix}-${name.iconName}';

    // Return an icon data that uses the <use> tag.
    // Note: This requires the sprite sheet to be injected into the DOM
    // or referenced correctly. For Flutter Web HTML renderer,
    // referencing the asset file works best.
    return IconifyIconData(
      body: '<use href="$assetPath#$id" />',
      // Natural size is hard to know without manifest,
      // but IconifyIcon will scale it anyway.
      width: 24,
      height: 24,
    );
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    return null; // Not supported by sprite provider
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    await _ensureManifest();
    return _availableIcons != null;
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    await _ensureManifest();
    return _availableIcons != null;
  }
}
