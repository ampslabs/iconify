import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/iconify_exception.dart';
import '../guard/dev_mode_guard.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] that fetches icons from the Iconify HTTP API.
///
/// **Important**: debug and development only, never the recommended production path.
final class RemoteIconifyProvider implements IconifyProvider {
  RemoteIconifyProvider({
    String? apiBase,
    http.Client? httpClient,
    bool allowInRelease = false,
    Duration timeout = const Duration(seconds: 10),
    Map<String, String>? additionalHeaders,
  })  : _apiBase = apiBase ?? 'https://api.iconify.design',
        _client = httpClient ?? http.Client(),
        _allowInRelease = allowInRelease,
        _timeout = timeout,
        _headers = {
          'User-Agent': 'iconify_sdk_core/0.1.0 (Dart)',
          ...?additionalHeaders,
        };

  final String _apiBase;
  final http.Client _client;
  final bool _allowInRelease;
  final Duration _timeout;
  final Map<String, String> _headers;
  bool _disposed = false;

  bool get _isAllowed =>
      _allowInRelease || DevModeGuard.isRemoteAllowedInCurrentBuild();

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    _checkDisposed();
    if (!_isAllowed) return null;

    final uri =
        Uri.parse('$_apiBase/${name.prefix}.json?icons=${name.iconName}');

    try {
      final response =
          await _client.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw IconifyNetworkException(
          message:
              'HTTP ${response.statusCode} fetching $name: ${response.reasonPhrase}',
          statusCode: response.statusCode,
          uri: uri,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final icons = json['icons'] as Map<String, dynamic>?;
      if (icons == null || !icons.containsKey(name.iconName)) return null;

      // Apply collection-level defaults to icon-level data
      final defaultWidth = (json['width'] as num?)?.toDouble() ?? 24.0;
      final defaultHeight = (json['height'] as num?)?.toDouble() ?? 24.0;
      final iconJson = Map<String, dynamic>.from(
          icons[name.iconName] as Map<String, dynamic>);
      iconJson.putIfAbsent('width', () => defaultWidth);
      iconJson.putIfAbsent('height', () => defaultHeight);

      return IconifyIconData.fromJson(iconJson);
    } on IconifyException {
      rethrow;
    } catch (e) {
      throw IconifyNetworkException(
        message: 'Network error fetching $name: $e',
        uri: uri,
      );
    }
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    _checkDisposed();
    if (!_isAllowed) return null;

    final uri = Uri.parse('$_apiBase/collection?prefix=$prefix&info=1');

    try {
      final response =
          await _client.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw IconifyNetworkException(
          message: 'HTTP ${response.statusCode} fetching collection $prefix',
          statusCode: response.statusCode,
          uri: uri,
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return IconifyCollectionInfo.fromJson(prefix, json);
    } on IconifyException {
      rethrow;
    } catch (e) {
      throw IconifyNetworkException(
        message: 'Network error fetching collection $prefix: $e',
        uri: uri,
      );
    }
  }

  @override
  Future<bool> hasIcon(IconifyName name) async {
    try {
      return await getIcon(name) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasCollection(String prefix) async {
    try {
      return await getCollection(prefix) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _client.close();
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError(
        'RemoteIconifyProvider has been disposed and cannot be used.',
      );
    }
  }
}
