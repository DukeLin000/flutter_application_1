// lib/api/api_client.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Login 前：先呼叫 `preflight(baseUrl)`
/// Login 成功：`boot(baseUrl: ..., token: ...)` 或先 boot 再 `setToken(token)`
class ApiClient {
  ApiClient._internal({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;
  static final ApiClient I = ApiClient._internal();

  // ---- Base URL ----
  static String get _defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:8088'; // ← Web 預設 8088
    return 'http://10.0.2.2:8088';              // ← Android 模擬器連本機 8088
  }

  static const String _apiBasePath = '/api';

  String _baseUrl;
  String get baseUrl => _baseUrl;
  void setBaseUrl(String url) => _baseUrl = url;

  // ---- Auth / Ready 狀態 ----
  String? _authToken;
  bool _ready = false;
  bool get isReady => _ready;

  Future<void> boot({required String baseUrl, String? token}) async {
    _baseUrl = baseUrl;
    _authToken = token;
    _ready = true;
  }

  void setToken(String token) {
    _authToken = token;
  }

  void logout() {
    _authToken = null;
    _ready = false;
  }

  // ---- Timeout / Headers ----
  final _timeout = const Duration(seconds: 15);

  // 基礎表頭（不含授權）
  final Map<String, String> _baseHeaders = const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 動態表頭：自動帶上 Authorization（若已登入）
  Map<String, String> _headersAll([Map<String, String>? extra]) {
    final h = Map<String, String>.of(_baseHeaders);
    if (_authToken != null && _authToken!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_authToken';
    }
    if (extra != null) h.addAll(extra);
    return h;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  // 供 preflight 使用：不改動目前 instance baseUrl 的情況下組 URI
  Uri _composeUri(String baseUrl, String path, [Map<String, dynamic>? query]) {
    final b = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$b$p').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  // ---------- 低階傳送與解碼 ----------
  Future<http.Response> _send(http.BaseRequest request) async {
    final streamed = await request.send().timeout(_timeout);
    return http.Response.fromStream(streamed);
  }

  Map<String, dynamic> _decodeMap(http.Response resp) {
    final text = resp.bodyBytes.isNotEmpty ? utf8.decode(resp.bodyBytes) : '';
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (text.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }
    throw ApiException(resp.statusCode, text.isEmpty ? 'HTTP ${resp.statusCode}' : text);
  }

  List<dynamic> _decodeList(http.Response resp) {
    final text = resp.bodyBytes.isNotEmpty ? utf8.decode(resp.bodyBytes) : '';
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (text.isEmpty) return <dynamic>[];
      final decoded = jsonDecode(text);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
      return <dynamic>[];
    }
    throw ApiException(resp.statusCode, text.isEmpty ? 'HTTP ${resp.statusCode}' : text);
  }

  // ---------- Preflight / Health ----------
  /// 登入前健康檢查：優先打 /api/profile/ping；再回退 /api/health → /actuator/health → /health
  Future<PreflightResult> preflight(String baseUrl) async {
    final candidates = <String>[
      '$_apiBasePath/profile', // ← 對應 ProfileController#ping
      '$_apiBasePath/health',
      '/actuator/health',
      '/health',
    ];
    String lastDetail = 'no-response';
    for (final p in candidates) {
      try {
        final req = http.Request('GET', _composeUri(baseUrl, p))
          ..headers.addAll(_headersAll());
        final resp = await _send(req);
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          return PreflightResult(true, 'ok($p)');
        } else {
          lastDetail = 'HTTP ${resp.statusCode} @ $p';
        }
      } catch (e) {
        lastDetail = '$e @ $p';
      }
    }
    return PreflightResult(false, lastDetail);
  }

  /// App 內健康檢查（用目前 instance baseUrl／Token）
  Future<bool> ping() async {
    final req = http.Request('GET', _uri('$_apiBasePath/profile/ping')) // ← 改這裡
      ..headers.addAll(_headersAll());
    try {
      final resp = await _send(req);
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ---------- Profile ----------
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) async {
    final req = http.Request('POST', _uri('$_apiBasePath/profile'))
      ..headers.addAll(_headersAll())
      ..body = jsonEncode(profile);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  /// 依照 ID 回讀（支援 "P-1" 或 "1"）
  Future<Map<String, dynamic>> getProfile(String id) async {
    final req = http.Request('GET', _uri('$_apiBasePath/profile/$id'))
      ..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- Items (衣櫃 CRUD) ----------
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> item) async {
    final req = http.Request('POST', _uri('$_apiBasePath/items'))
      ..headers.addAll(_headersAll())
      ..body = jsonEncode(item);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  Future<List<dynamic>> listItems({String? category, String? brand}) async {
    final q = <String, dynamic>{};
    if (category != null) q['category'] = category;
    if (brand != null) q['brand'] = brand;
    final req = http.Request('GET', _uri('$_apiBasePath/items', q))..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeList(resp);
  }

  Future<Map<String, dynamic>> getItem(int id) async {
    final req = http.Request('GET', _uri('$_apiBasePath/items/$id'))..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  Future<Map<String, dynamic>> updateItem(int id, Map<String, dynamic> patch) async {
    final req = http.Request('PUT', _uri('$_apiBasePath/items/$id'))
      ..headers.addAll(_headersAll())
      ..body = jsonEncode(patch);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  Future<Map<String, dynamic>> deleteItem(int id) async {
    final req = http.Request('DELETE', _uri('$_apiBasePath/items/$id'))..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- Outfits (穿搭) ----------
  Future<Map<String, dynamic>> createOutfit(Map<String, dynamic> outfit) async {
    final req = http.Request('POST', _uri('$_apiBasePath/outfits'))
      ..headers.addAll(_headersAll())
      ..body = jsonEncode(outfit);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  Future<List<dynamic>> listOutfits() async {
    final req = http.Request('GET', _uri('$_apiBasePath/outfits'))..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeList(resp);
  }

  Future<Map<String, dynamic>> getOutfit(int id) async {
    final req = http.Request('GET', _uri('$_apiBasePath/outfits/$id'))..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- AI / Capsule / Shops ----------
  Future<Map<String, dynamic>> recommendOutfit({
    required Map<String, dynamic> profile,
    required List<dynamic> items,
  }) async {
    final body = {'profile': profile, 'items': items};
    final req = http.Request('POST', _uri('$_apiBasePath/ai/recommend-outfit'))
      ..headers.addAll(_headersAll())
      ..body = jsonEncode(body);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  Future<Map<String, dynamic>> suggestCapsule({String style = 'street'}) async {
    final req = http.Request('GET', _uri('$_apiBasePath/capsule/suggest', {'style': style}))
      ..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  Future<Map<String, dynamic>> nearbyShops({
    required double lat,
    required double lng,
    int radius = 2000,
  }) async {
    final req = http.Request('GET', _uri('$_apiBasePath/shops/nearby', {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    }))..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- Upload（bytes 版） ----------
  Future<Map<String, dynamic>> uploadImageBytes(
    Uint8List bytes, {
    required String filename,
    String contentType = 'application/octet-stream',
  }) async {
    final uri = _uri('$_apiBasePath/uploads/image');
    final req = http.MultipartRequest('POST', uri);
    // 加上授權表頭（若有）
    req.headers.addAll(_headersAll());
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    );
    final streamed = await req.send().timeout(_timeout);
    final resp = await http.Response.fromStream(streamed);
    return _decodeMap(resp);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Preflight 結果（登入前健康檢查）
class PreflightResult {
  final bool ok;
  final String detail;
  const PreflightResult(this.ok, this.detail);
}
