import 'dart:convert';
import 'dart:typed_data';

import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_license.dart';
import '../resolver/alias_resolver.dart';
import 'iconify_json_parser.dart';

/// Handles encoding and decoding of the `.iconbin` format.
///
/// See `docs/binary-format-spec.md` for the format specification.
class BinaryIconFormat {
  const BinaryIconFormat._();

  static const _magic = 0x49434F4E; // "ICON"
  static const _version = 0x01;

  /// Encodes a [ParsedCollection] into a binary blob.
  static Uint8List encode(ParsedCollection collection) {
    final stringTable = _StringTable();

    stringTable.add(collection.prefix);
    stringTable.add(collection.info.name);
    stringTable.add(collection.info.author ?? '');
    stringTable.add(collection.info.license?.title ?? '');
    stringTable.add(collection.info.license?.spdx ?? '');
    stringTable.add(collection.info.license?.url ?? '');

    final sortedIconNames = collection.icons.keys.toList()..sort();
    final sortedAliasNames = collection.aliases.keys.toList()..sort();

    for (final name in sortedIconNames) {
      stringTable.add(name);
      stringTable.add(collection.icons[name]!.body);
    }

    for (final name in sortedAliasNames) {
      stringTable.add(name);
      stringTable.add(collection.aliases[name]!.parent);
    }

    final builder = _BytesBuilder();

    // 1. Header (28 bytes)
    builder.addUint32(_magic);
    builder.addUint8(_version);
    builder.addUint8(0); // Reserved
    builder.addUint16(collection.iconCount);
    builder.addUint16(collection.aliasCount);
    builder.addUint32(stringTable.count);

    final metadataOffsetPos = builder.length;
    builder.addUint32(0); // Metadata Offset
    final iconIndexOffsetPos = builder.length;
    builder.addUint32(0); // Icon Index Offset
    final aliasIndexOffsetPos = builder.length;
    builder.addUint32(0); // Alias Index Offset
    final stringTableOffsetPos = builder.length;
    builder.addUint32(0); // String Table Offset

    // 2. Metadata
    final metadataOffset = builder.length;
    builder.setUint32(metadataOffsetPos, metadataOffset);
    builder.addUint32(stringTable.indexOf(collection.prefix));
    builder.addUint32(stringTable.indexOf(collection.info.name));
    builder.addUint32(collection.info.totalIcons);
    builder.addUint32(stringTable.indexOf(collection.info.author ?? ''));
    builder.addUint32(stringTable.indexOf(collection.info.license?.title ?? ''));
    builder.addUint32(stringTable.indexOf(collection.info.license?.spdx ?? ''));
    builder.addUint32(stringTable.indexOf(collection.info.license?.url ?? ''));
    builder.addUint8(collection.info.requiresAttribution ? 1 : 0);
    builder.addFloat32(collection.defaultWidth);
    builder.addFloat32(collection.defaultHeight);

    // 3. Icon Index
    final iconIndexOffset = builder.length;
    builder.setUint32(iconIndexOffsetPos, iconIndexOffset);
    final iconRecordOffsetPositions = <String, int>{};
    for (final name in sortedIconNames) {
      builder.addUint32(stringTable.indexOf(name));
      iconRecordOffsetPositions[name] = builder.length;
      builder.addUint32(0);
    }

    // 4. Alias Index
    final aliasIndexOffset = builder.length;
    builder.setUint32(aliasIndexOffsetPos, aliasIndexOffset);
    final aliasRecordOffsetPositions = <String, int>{};
    for (final name in sortedAliasNames) {
      builder.addUint32(stringTable.indexOf(name));
      aliasRecordOffsetPositions[name] = builder.length;
      builder.addUint32(0);
    }

    // 5. Icon Records
    for (final name in sortedIconNames) {
      final recordOffset = builder.length;
      builder.setUint32(iconRecordOffsetPositions[name]!, recordOffset);

      final icon = collection.icons[name]!;
      builder.addUint32(stringTable.indexOf(icon.body));
      builder.addFloat32(icon.width);
      builder.addFloat32(icon.height);

      int flags = 0;
      if (icon.hidden) flags |= 0x01;
      if (icon.hFlip) flags |= 0x02;
      if (icon.vFlip) flags |= 0x04;
      builder.addUint8(flags);
      builder.addUint8(icon.rotate);
    }

    // 6. Alias Records
    for (final name in sortedAliasNames) {
      final recordOffset = builder.length;
      builder.setUint32(aliasRecordOffsetPositions[name]!, recordOffset);

      final alias = collection.aliases[name]!;
      builder.addUint32(stringTable.indexOf(alias.parent));
      builder.addFloat32(alias.width ?? 0);
      builder.addFloat32(alias.height ?? 0);

      int flags = 0;
      if (alias.width != null) flags |= 0x01;
      if (alias.height != null) flags |= 0x02;
      if (alias.rotate != null) flags |= 0x04;
      if (alias.hFlip != null) flags |= 0x08;
      if (alias.vFlip != null) flags |= 0x10;
      if (alias.hFlip == true) flags |= 0x20;
      if (alias.vFlip == true) flags |= 0x40;
      builder.addUint8(flags);
      builder.addUint8(alias.rotate ?? 0);
    }

    // 7. String Table
    final stringTableOffset = builder.length;
    builder.setUint32(stringTableOffsetPos, stringTableOffset);
    
    // Write string index (offsets)
    final stringDataOffsetPositions = <int>[];
    for (var i = 0; i < stringTable.count; i++) {
      stringDataOffsetPositions.add(builder.length);
      builder.addUint32(0); // Offset placeholder
    }

    // Write raw strings
    for (var i = 0; i < stringTable.count; i++) {
      final s = stringTable.strings[i];
      final sOffset = builder.length;
      builder.setUint32(stringDataOffsetPositions[i], sOffset);
      
      final bytes = utf8.encode(s);
      builder.addUint32(bytes.length);
      builder.addBytes(bytes);
    }

    return builder.toBytes();
  }

  /// Decodes a binary blob into a [ParsedCollection].
  static ParsedCollection decode(Uint8List bytes) {
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    if (data.getUint32(0) != _magic) {
      throw const FormatException('Invalid .iconbin format: Magic bytes mismatch');
    }
    if (data.getUint8(4) != _version) {
      throw FormatException('Unsupported .iconbin version: ${data.getUint8(4)}');
    }

    final iconCount = data.getUint16(6);
    final aliasCount = data.getUint16(8);
    final stringCount = data.getUint32(10);
    final metadataOffset = data.getUint32(14);
    final iconIndexOffset = data.getUint32(18);
    final aliasIndexOffset = data.getUint32(22);
    final stringTableOffset = data.getUint32(26);

    String readString(int index) {
      if (index >= stringCount) return '';
      final offsetToOffset = stringTableOffset + (index * 4);
      final sOffset = data.getUint32(offsetToOffset);
      final len = data.getUint32(sOffset);
      final bytesView = Uint8List.view(
          data.buffer, data.offsetInBytes + sOffset + 4, len);
      return utf8.decode(bytesView);
    }

    var offset = metadataOffset;
    final prefix = readString(data.getUint32(offset)); offset += 4;
    final name = readString(data.getUint32(offset)); offset += 4;
    final totalIcons = data.getUint32(offset); offset += 4;
    final author = readString(data.getUint32(offset)); offset += 4;
    final licenseTitle = readString(data.getUint32(offset)); offset += 4;
    final licenseSpdx = readString(data.getUint32(offset)); offset += 4;
    final licenseUrl = readString(data.getUint32(offset)); offset += 4;
    final requiresAttribution = data.getUint8(offset) == 1; offset += 1;
    final defaultWidth = data.getFloat32(offset); offset += 4;
    final defaultHeight = data.getFloat32(offset); offset += 4;

    final info = IconifyCollectionInfo(
      prefix: prefix,
      name: name,
      totalIcons: totalIcons,
      author: author.isEmpty ? null : author,
      license: IconifyLicense(
        title: licenseTitle.isEmpty ? null : licenseTitle,
        spdx: licenseSpdx.isEmpty ? null : licenseSpdx,
        url: licenseUrl.isEmpty ? null : licenseUrl,
        requiresAttribution: requiresAttribution,
      ),
    );

    final icons = <String, IconifyIconData>{};
    for (var i = 0; i < iconCount; i++) {
      final idxOffset = iconIndexOffset + (i * 8);
      final nameIdx = data.getUint32(idxOffset);
      final recordOffset = data.getUint32(idxOffset + 4);
      final iconName = readString(nameIdx);
      
      var rOffset = recordOffset;
      final body = readString(data.getUint32(rOffset)); rOffset += 4;
      final width = data.getFloat32(rOffset); rOffset += 4;
      final height = data.getFloat32(rOffset); rOffset += 4;
      final flags = data.getUint8(rOffset); rOffset += 1;
      final rotate = data.getUint8(rOffset);

      icons[iconName] = IconifyIconData(
        body: body,
        width: width.toDouble(),
        height: height.toDouble(),
        hidden: (flags & 0x01) != 0,
        hFlip: (flags & 0x02) != 0,
        vFlip: (flags & 0x04) != 0,
        rotate: rotate,
      );
    }

    final aliases = <String, AliasEntry>{};
    for (var i = 0; i < aliasCount; i++) {
      final idxOffset = aliasIndexOffset + (i * 8);
      final nameIdx = data.getUint32(idxOffset);
      final recordOffset = data.getUint32(idxOffset + 4);
      final aliasName = readString(nameIdx);
      
      var rOffset = recordOffset;
      final parent = readString(data.getUint32(rOffset)); rOffset += 4;
      final width = data.getFloat32(rOffset); rOffset += 4;
      final height = data.getFloat32(rOffset); rOffset += 4;
      final flags = data.getUint8(rOffset); rOffset += 1;
      final rotate = data.getUint8(rOffset);

      aliases[aliasName] = AliasEntry(
        parent: parent,
        width: (flags & 0x01) != 0 ? width.toDouble() : null,
        height: (flags & 0x02) != 0 ? height.toDouble() : null,
        rotate: (flags & 0x04) != 0 ? rotate : null,
        hFlip: (flags & 0x08) != 0 ? (flags & 0x20) != 0 : null,
        vFlip: (flags & 0x10) != 0 ? (flags & 0x40) != 0 : null,
      );
    }

    return ParsedCollection(
      prefix: prefix,
      info: info,
      icons: icons,
      aliases: aliases,
      defaultWidth: defaultWidth.toDouble(),
      defaultHeight: defaultHeight.toDouble(),
    );
  }

  /// Extracts a single icon from a binary blob without decoding the entire collection.
  static IconifyIconData? decodeIcon(Uint8List bytes, String iconName) {
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    if (data.getUint32(0) != _magic) return null;

    final iconCount = data.getUint16(6);
    final stringCount = data.getUint32(10);
    final iconIndexOffset = data.getUint32(18);
    final stringTableOffset = data.getUint32(26);

    String readString(int index) {
      if (index >= stringCount) return '';
      final offsetToOffset = stringTableOffset + (index * 4);
      final sOffset = data.getUint32(offsetToOffset);
      final len = data.getUint32(sOffset);
      final sBytes = Uint8List.view(
          data.buffer, data.offsetInBytes + sOffset + 4, len);
      return utf8.decode(sBytes);
    }

    int low = 0;
    int high = iconCount - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final idxOffset = iconIndexOffset + (mid * 8);
      final nameIdx = data.getUint32(idxOffset);
      final currentName = readString(nameIdx);
      final cmp = iconName.compareTo(currentName);

      if (cmp == 0) {
        final recordOffset = data.getUint32(idxOffset + 4);
        var rOffset = recordOffset;
        final body = readString(data.getUint32(rOffset)); rOffset += 4;
        final width = data.getFloat32(rOffset); rOffset += 4;
        final height = data.getFloat32(rOffset); rOffset += 4;
        final flags = data.getUint8(rOffset); rOffset += 1;
        final rotate = data.getUint8(rOffset);

        return IconifyIconData(
          body: body,
          width: width.toDouble(),
          height: height.toDouble(),
          hidden: (flags & 0x01) != 0,
          hFlip: (flags & 0x02) != 0,
          vFlip: (flags & 0x04) != 0,
          rotate: rotate,
        );
      } else if (cmp < 0) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    return null;
  }
}

class _StringTable {
  final List<String> strings = [];
  final Map<String, int> _index = {};

  int get count => strings.length;

  void add(String s) {
    if (!_index.containsKey(s)) {
      _index[s] = strings.length;
      strings.add(s);
    }
  }

  int indexOf(String s) => _index[s] ?? -1;
}

class _BytesBuilder {
  Uint8List _buffer = Uint8List(1024);
  int _length = 0;

  int get length => _length;

  void _ensure(int additional) {
    if (_length + additional > _buffer.length) {
      var newSize = _buffer.length * 2;
      while (newSize < _length + additional) {
        newSize *= 2;
      }
      final newBuffer = Uint8List(newSize);
      newBuffer.setRange(0, _length, _buffer);
      _buffer = newBuffer;
    }
  }

  void addUint8(int value) {
    _ensure(1);
    _buffer[_length++] = value;
  }

  void addUint16(int value) {
    _ensure(2);
    ByteData.view(_buffer.buffer, _buffer.offsetInBytes + _length, 2)
        .setUint16(0, value);
    _length += 2;
  }

  void addUint32(int value) {
    _ensure(4);
    ByteData.view(_buffer.buffer, _buffer.offsetInBytes + _length, 4)
        .setUint32(0, value);
    _length += 4;
  }

  void addFloat32(double value) {
    _ensure(4);
    ByteData.view(_buffer.buffer, _buffer.offsetInBytes + _length, 4)
        .setFloat32(0, value);
    _length += 4;
  }

  void addBytes(List<int> bytes) {
    _ensure(bytes.length);
    _buffer.setRange(_length, _length + bytes.length, bytes);
    _length += bytes.length;
  }

  void setUint32(int offset, int value) {
    ByteData.view(_buffer.buffer, _buffer.offsetInBytes + offset, 4)
        .setUint32(0, value);
  }

  Uint8List toBytes() => Uint8List.fromList(_buffer.sublist(0, _length));
}
