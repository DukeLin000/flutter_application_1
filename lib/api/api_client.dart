import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiClient {
  ApiClient._internal({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;
  static final ApiClient I = ApiClient._internal();

  // ---- Base URL 設定 (修正版) ----
  static String get _defaultBaseUrl {
    // 1. 如果編譯時有指定 --dart-define=API_BASE_URL=... 則優先使用
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    // 2. Web 環境
    if (kIsWeb) return 'http://localhost:8088';

    // 3. 根據作業系統決定 (iOS/macOS 用 localhost，Android 用 10.0.2.2)
    if (defaultTargetPlatform == TargetPlatform.iOS || 
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'http://localhost:8088';
    }

    // 4. 預設為 Android 模擬器位址
    return 'http://10.0.2.2:8088';
  }

  static const String _apiBasePath = '/api';

  String _baseUrl;
  String get baseUrl => _baseUrl;
  void setBaseUrl(String url) => _baseUrl = url;

  String? _authToken;
  bool _ready = false;
  bool get isReady => _ready;

  Future<void> boot({required String baseUrl, String? token}) async {
    _baseUrl = baseUrl;
    _authToken = token;
    _ready = true;
  }

  void setToken(String token) => _authToken = token;
  void logout() { _authToken = null; _ready = false; }

  final _timeout = const Duration(seconds: 15);

  final Map<String, String> _baseHeaders = const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

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

  Uri _composeUri(String baseUrl, String path, [Map<String, dynamic>? query]) {
    final b = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$b$p').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<http.Response> _send(http.BaseRequest request) async {
    final streamed = await request.send().timeout(_timeout);
    return http.Response.fromStream(streamed);
  }

  Map<String, dynamic> _decodeMap(http.Response resp) {
    final text = resp.bodyBytes.isNotEmpty ? utf8.decode(resp.bodyBytes) : '';
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (text.isEmpty) return <String, dynamic>{};
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'data': decoded};
      } catch (e) {
        return {};
      }
    }
    throw ApiException(resp.statusCode, text.isEmpty ? 'HTTP ${resp.statusCode}' : text);
  }

  List<dynamic> _decodeList(http.Response resp) {
    final text = resp.bodyBytes.isNotEmpty ? utf8.decode(resp.bodyBytes) : '';
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (text.isEmpty) return <dynamic>[];
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          if (decoded.containsKey('content') && decoded['content'] is List) {
            return decoded['content'] as List;
          }
          if (decoded.containsKey('data') && decoded['data'] is List) {
            return decoded['data'] as List;
          }
        }
        return <dynamic>[];
      } catch (e) {
        return <dynamic>[];
      }
    }
    throw ApiException(resp.statusCode, text.isEmpty ? 'HTTP ${resp.statusCode}' : text);
  }

  // ---------- Auth ----------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final req = http.Request('POST', _uri('$_apiBasePath/auth/login'))
      ..headers.addAll(_headersAll())
      ..body = jsonEncode({'email': email, 'password': password});
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  Future<Map<String, dynamic>> register(String email, String password, String displayName) async {
    final req = http.Request('POST', _uri('$_apiBasePath/auth/register'))
      ..headers.addAll(_headersAll())
      ..body = jsonEncode({'email': email, 'password': password, 'displayName': displayName});
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- Preflight ----------
  Future<PreflightResult> preflight(String baseUrl) async {
    final candidates = <String>[
      '$_apiBasePath/profile/ping',
      '$_apiBasePath/health',
      '/actuator/health',
      '/health',
    ];
    String lastDetail = 'no-response';
    for (final p in candidates) {
      try {
        final req = http.Request('GET', _composeUri(baseUrl, p))
          ..headers.addAll(_baseHeaders);
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

  Future<bool> ping() async {
    final req = http.Request('GET', _uri('$_apiBasePath/profile/ping'))
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

  Future<Map<String, dynamic>> getMyProfile() async {
    final req = http.Request('GET', _uri('$_apiBasePath/profile/me'))
      ..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- Items ----------
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> item) async {
    final req = http.Request('POST', _uri('$_apiBasePath/items'))
      ..headers.addAll(_headersAll())
      ..body = jsonEncode(item);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  Future<List<dynamic>> listItems({String? category, String? brand}) async {
    final q = <String, dynamic>{};
    if (category != null && category != 'all' && category.isNotEmpty) {
      q['category'] = category;
    }
    if (brand != null && brand.isNotEmpty) {
      q['brand'] = brand;
    }
    
    final req = http.Request('GET', _uri('$_apiBasePath/items', q))..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeList(resp);
  }
  
  Future<Map<String, dynamic>> deleteItem(String id) async {
     final req = http.Request('DELETE', _uri('$_apiBasePath/items/$id'))..headers.addAll(_headersAll());
     final resp = await _send(req);
     return _decodeMap(resp);
  }

  // ---------- Outfits ----------
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

  // ---------- Outfits (Extended: Like & Unlike) ----------

  // 新增：按讚
  Future<void> likeOutfit(String id) async {
    final req = http.Request('POST', _uri('$_apiBasePath/outfits/$id/like'))
      ..headers.addAll(_headersAll());
    final resp = await _send(req);
    // 200-299 視為成功，否則拋出異常
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, '按讚失敗');
    }
  }

  // 新增：取消按讚
  Future<void> unlikeOutfit(String id) async {
    final req = http.Request('DELETE', _uri('$_apiBasePath/outfits/$id/like'))
      ..headers.addAll(_headersAll());
    final resp = await _send(req);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, '取消按讚失敗');
    }
  }

  // ---------- Comments (New) ----------

  // 新增：取得留言列表
  Future<List<dynamic>> getComments(String outfitId) async {
    final req = http.Request('GET', _uri('$_apiBasePath/outfits/$outfitId/comments'))
      ..headers.addAll(_headersAll());
    final resp = await _send(req);
    return _decodeList(resp);
  }

  // 新增：發送留言
  Future<Map<String, dynamic>> postComment(String outfitId, String text) async {
    final req = http.Request('POST', _uri('$_apiBasePath/outfits/$outfitId/comments'))
      ..headers.addAll(_headersAll())
      // 假設後端接收的 JSON 欄位為 "content"
      ..body = jsonEncode({'content': text}); 
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- Upload ----------
  Future<Map<String, dynamic>> uploadImageBytes(
    Uint8List bytes, {
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final uri = _uri('$_apiBasePath/files'); 
    final req = http.MultipartRequest('POST', uri);
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

class PreflightResult {
  final bool ok;
  final String detail;
  const PreflightResult(this.ok, this.detail);
}