import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:iconify_sdk_core/iconify_sdk_core.dart';
import '../render/gzip_utils.dart';

/// An [IconifyProvider] that uses an icon font for optimized monochromatic rendering.
///
/// This provider expects an `icons.font.otf` file and an `icons.font.json`
/// mapping to be present in the asset bundle.
final class FontIconifyProvider extends IconifyProvider {
  FontIconifyProvider({
    this.fontPath = 'assets/iconify/icons.font.otf',
    this.mappingPath = 'assets/iconify/icons.font.json',
    this.compress = false,
  });

  final String fontPath;
  final String mappingPath;
  final bool compress;

  bool _initialized = false;
  Map<String, int>? _mapping;
  String? _fontFamily;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      // 1. Load Mapping
      final actualMappingPath = compress ? '$mappingPath.gz' : mappingPath;
      final mappingByteData = await rootBundle.load(actualMappingPath);
      final mappingBytes = mappingByteData.buffer.asUint8List(
        mappingByteData.offsetInBytes,
        mappingByteData.lengthInBytes,
      );

      final decompressedMapping = actualMappingPath.endsWith('.gz')
          ? await decompressGZip(mappingBytes)
          : mappingBytes;

      final mappingContent = utf8.decode(decompressedMapping);
      final decoded = jsonDecode(mappingContent) as Map<String, dynamic>;
      _mapping = (decoded['icons'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as int),
      );
      _fontFamily = decoded['fontFamily'] as String?;

      // 2. Load and Register Font
      if (_fontFamily != null) {
        final actualFontPath = compress ? '$fontPath.gz' : fontPath;
        final fontByteData = await rootBundle.load(actualFontPath);
        final fontBytes = fontByteData.buffer.asUint8List(
          fontByteData.offsetInBytes,
          fontByteData.lengthInBytes,
        );

        final decompressedFont = actualFontPath.endsWith('.gz')
            ? await decompressGZip(fontBytes)
            : fontBytes;

        final loader = FontLoader(_fontFamily!);
        loader.addFont(Future.value(ByteData.sublistView(decompressedFont)));
        await loader.load();
      }
    } catch (_) {
      _mapping = null;
    }
    _initialized = true;
  }

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    await _ensureInitialized();
    if (_mapping == null || _fontFamily == null) return null;

    final fullName = name.toString();
    final charCode = _mapping![fullName];
    if (charCode == null) return null;

    return IconifyIconData(
      body: String.fromCharCode(charCode),
      fontFamily: _fontFamily,
      width: 24,
      height: 24,
    );
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    return null;
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    await _ensureInitialized();
    return _mapping?.containsKey(name.toString()) ?? false;
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    await _ensureInitialized();
    if (_mapping == null) return false;
    final search = '$prefix:';
    return _mapping!.keys.any((key) => key.startsWith(search));
  }
}
