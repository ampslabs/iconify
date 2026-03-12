import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/iconify_exception.dart';
import '../guard/dev_mode_guard.dart';
import '../models/iconify_collection_info.dart';
import '../models/iconify_icon_data.dart';
import '../models/iconify_name.dart';
import '../parser/iconify_json_parser.dart';
import 'iconify_provider.dart';

/// An [IconifyProvider] that fetches icons from the Iconify HTTP API.
///
/// **Important**: This provider is intended for debug and development only.
/// In production, use local snapshots or generated code.
///
/// This provider automatically batches concurrent requests for icons from the
/// same collection into a single HTTP call to minimize network overhead and
/// be respectful of the community-funded Iconify API.
final class RemoteIconifyProvider implements IconifyProvider {
  RemoteIconifyProvider({
    String? apiBase,
    http.Client? httpClient,
    bool allowInRelease = false,
    this.batchWindow = const Duration(milliseconds: 50),
    this.requestTimeout = const Duration(seconds: 10),
    Map<String, String>? additionalHeaders,
  })  : _apiBase = apiBase ?? 'https://api.iconify.design',
        _client = httpClient ?? http.Client(),
        _allowInRelease = allowInRelease,
        _headers = {
          'User-Agent': 'iconify_sdk_core/0.1.0 (Dart)',
          ...?additionalHeaders,
        };

  final String _apiBase;
  final http.Client _client;
  final bool _allowInRelease;

  /// The duration to wait for concurrent requests before dispatching a batch.
  final Duration batchWindow;

  /// Timeout for individual HTTP requests.
  final Duration requestTimeout;

  final Map<String, String> _headers;
  bool _disposed = false;

  /// Cached collections fetched from GitHub.
  final _collectionCache = <String, ParsedCollection>{};

  /// Pending requests for the batched API (fallback).
  final _pending = <String, List<_PendingRequest>>{};
  Timer? _batchTimer;

  bool get _isAllowed =>
      _allowInRelease || DevModeGuard.isRemoteAllowedInCurrentBuild();

  @override
  Future<IconifyIconData?> getIcon(IconifyName name) async {
    _checkDisposed();
    if (!_isAllowed) return null;

    // 1. Check GitHub-fetched collection cache
    if (_collectionCache.containsKey(name.prefix)) {
      return _collectionCache[name.prefix]!.getIcon(name.iconName);
    }

    // 2. Attempt to fetch full collection from GitHub (Raw)
    try {
      final githubUri = Uri.parse(
          'https://raw.githubusercontent.com/iconify/icon-sets/master/json/${name.prefix}.json');
      
      // Diagnostic logging for debugging.
      // ignore: avoid_print
      print('Iconify SDK [REMOTE]: Trying GitHub Raw for ${name.prefix}...');
      final response = await _client.get(githubUri).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final collection = IconifyJsonParser.parseCollectionString(response.body);
        _collectionCache[name.prefix] = collection;
        // Diagnostic logging for debugging.
      // ignore: avoid_print
        print('Iconify SDK [REMOTE]: Successfully cached ${name.prefix} from GitHub');
        return collection.getIcon(name.iconName);
      }
    } catch (e) {
      // Diagnostic logging for debugging.
      // ignore: avoid_print
      print('Iconify SDK [REMOTE]: GitHub fetch failed for ${name.prefix}, falling back to API: $e');
    }

    // 3. Fallback: Use micro-batching API
    final completer = Completer<IconifyIconData?>();
    _pending.putIfAbsent(name.prefix, () => []).add(
          _PendingRequest(name.iconName, completer),
        );

    _startBatchTimer();
    return completer.future;
  }

  void _startBatchTimer() {
    if (_batchTimer?.isActive ?? false) return;
    _batchTimer = Timer(batchWindow, _flushBatch);
  }

  Future<void> _flushBatch() async {
    if (_pending.isEmpty) return;

    // Take a snapshot of pending requests and clear the map
    final batches = Map<String, List<_PendingRequest>>.from(_pending);
    _pending.clear();

    for (final entry in batches.entries) {
      final prefix = entry.key;
      final requests = entry.value;
      final iconNames = requests.map((r) => r.iconName).toSet().toList();

      final uri =
          Uri.parse('$_apiBase/$prefix.json?icons=${iconNames.join(',')}');

      try {
        // Diagnostic logging for debugging.
      // ignore: avoid_print
        print('Iconify SDK [REMOTE]: Fetching ${iconNames.length} icons for $prefix...');
        final response =
            await _client.get(uri, headers: _headers).timeout(requestTimeout);

        if (response.statusCode == 404) {
          // Diagnostic logging for debugging.
      // ignore: avoid_print
          print('Iconify SDK [REMOTE]: 404 Not Found for $prefix');
          for (final req in requests) {
            req.completer.complete(null);
          }
          continue;
        }

        if (response.statusCode != 200) {
          // Diagnostic logging for debugging.
      // ignore: avoid_print
          print('Iconify SDK [REMOTE]: HTTP ${response.statusCode} for $prefix');
          final error = IconifyNetworkException(
            message: 'HTTP ${response.statusCode} fetching batch for $prefix',
            statusCode: response.statusCode,
            uri: uri,
          );
          for (final req in requests) {
            req.completer.completeError(error);
          }
          continue;
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Diagnostic logging for debugging.
      // ignore: avoid_print
        print('Iconify SDK [REMOTE]: Successfully fetched $prefix batch');

        final icons = json['icons'] as Map<String, dynamic>? ?? {};

        final defaultWidth = (json['width'] as num?)?.toDouble() ?? 24.0;
        final defaultHeight = (json['height'] as num?)?.toDouble() ?? 24.0;

        for (final req in requests) {
          final iconData = icons[req.iconName] as Map<String, dynamic>?;
          if (iconData == null) {
            req.completer.complete(null);
          } else {
            final iconJson = Map<String, dynamic>.from(iconData);
            iconJson.putIfAbsent('width', () => defaultWidth);
            iconJson.putIfAbsent('height', () => defaultHeight);
            req.completer.complete(IconifyIconData.fromJson(iconJson));
          }
        }
      } catch (e, stack) {
        final error = e is IconifyException
            ? e
            : IconifyNetworkException(
                message: 'Network error fetching batch for $prefix: $e',
                uri: uri,
              );
        for (final req in requests) {
          if (!req.completer.isCompleted) {
            req.completer.completeError(error, stack);
          }
        }
      }
    }
  }

  @override
  Future<IconifyCollectionInfo?> getCollection(String prefix) async {
    _checkDisposed();
    if (!_isAllowed) return null;

    final uri = Uri.parse('$_apiBase/collection?prefix=$prefix&info=1');

    try {
      final response =
          await _client.get(uri, headers: _headers).timeout(requestTimeout);
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
    _batchTimer?.cancel();
    _collectionCache.clear();
    // Fail any pending requests
    for (final requests in _pending.values) {
      for (final req in requests) {
        req.completer.completeError(StateError('Provider disposed'));
      }
    }
    _pending.clear();
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

final class _PendingRequest {
  _PendingRequest(this.iconName, this.completer);
  final String iconName;
  final Completer<IconifyIconData?> completer;
}
