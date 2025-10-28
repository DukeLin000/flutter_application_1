// lib/api/api_client.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiClient {
  ApiClient._internal({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;
  static final ApiClient I = ApiClient._internal();

  // ← 你的服務主機（不含 /api）
  static String get _defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://10.0.2.2:8080';
  }

  // ← 統一管理 API base path
  static const String _apiBasePath = '/api';

  String _baseUrl;
  String get baseUrl => _baseUrl;
  void setBaseUrl(String url) => _baseUrl = url;

  final _timeout = const Duration(seconds: 15);
  final Map<String, String> _headers = const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  // ---------- 基礎傳送與解碼 ----------

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

  // ---------- Health ----------

  Future<bool> ping() async {
    final req = http.Request('GET', _uri('$_apiBasePath/health'))..headers.addAll(_headers);
    try {
      final resp = await _send(req);
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ---------- Profile ----------
  // POST /api/profile
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) async {
    final req = http.Request('POST', _uri('$_apiBasePath/profile'))
      ..headers.addAll(_headers)
      ..body = jsonEncode(profile);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- Items (衣櫃 CRUD) ----------

  // POST /api/items
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> item) async {
    final req = http.Request('POST', _uri('$_apiBasePath/items'))
      ..headers.addAll(_headers)
      ..body = jsonEncode(item);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // GET /api/items[?category=&brand=]
  Future<List<dynamic>> listItems({String? category, String? brand}) async {
    final q = <String, dynamic>{};
    if (category != null) q['category'] = category;
    if (brand != null) q['brand'] = brand;
    final req = http.Request('GET', _uri('$_apiBasePath/items', q))..headers.addAll(_headers);
    final resp = await _send(req);
    return _decodeList(resp);
  }

  // GET /api/items/{id}
  Future<Map<String, dynamic>> getItem(int id) async {
    final req = http.Request('GET', _uri('$_apiBasePath/items/$id'))..headers.addAll(_headers);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // PUT /api/items/{id}
  Future<Map<String, dynamic>> updateItem(int id, Map<String, dynamic> patch) async {
    final req = http.Request('PUT', _uri('$_apiBasePath/items/$id'))
      ..headers.addAll(_headers)
      ..body = jsonEncode(patch);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // DELETE /api/items/{id}
  Future<Map<String, dynamic>> deleteItem(int id) async {
    final req = http.Request('DELETE', _uri('$_apiBasePath/items/$id'))..headers.addAll(_headers);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- Outfits (穿搭) ----------

  // POST /api/outfits
  Future<Map<String, dynamic>> createOutfit(Map<String, dynamic> outfit) async {
    final req = http.Request('POST', _uri('$_apiBasePath/outfits'))
      ..headers.addAll(_headers)
      ..body = jsonEncode(outfit);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // GET /api/outfits
  Future<List<dynamic>> listOutfits() async {
    final req = http.Request('GET', _uri('$_apiBasePath/outfits'))..headers.addAll(_headers);
    final resp = await _send(req);
    return _decodeList(resp);
  }

  // GET /api/outfits/{id}
  Future<Map<String, dynamic>> getOutfit(int id) async {
    final req = http.Request('GET', _uri('$_apiBasePath/outfits/$id'))..headers.addAll(_headers);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- AI / Capsule / Shops (Stub 功能) ----------

  // POST /api/ai/recommend-outfit  body: { profile: {...}, items: [...] }
  Future<Map<String, dynamic>> recommendOutfit({
    required Map<String, dynamic> profile,
    required List<dynamic> items,
  }) async {
    final body = {'profile': profile, 'items': items};
    final req = http.Request('POST', _uri('$_apiBasePath/ai/recommend-outfit'))
      ..headers.addAll(_headers)
      ..body = jsonEncode(body);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // GET /api/capsule/suggest?style=street
  Future<Map<String, dynamic>> suggestCapsule({String style = 'street'}) async {
    final req = http.Request('GET', _uri('$_apiBasePath/capsule/suggest', {'style': style}))
      ..headers.addAll(_headers);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // GET /api/shops/nearby?lat=&lng=&radius=
  Future<Map<String, dynamic>> nearbyShops({
    required double lat,
    required double lng,
    int radius = 2000,
  }) async {
    final req = http.Request('GET', _uri('$_apiBasePath/shops/nearby', {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    }))..headers.addAll(_headers);
    final resp = await _send(req);
    return _decodeMap(resp);
  }

  // ---------- Upload（開發用，bytes 版，Web/原生皆可） ----------

  // POST /api/uploads/image  (multipart: file)
  Future<Map<String, dynamic>> uploadImageBytes(
    Uint8List bytes, {
    required String filename,
    String contentType = 'application/octet-stream',
  }) async {
    final uri = _uri('$_apiBasePath/uploads/image');
    final req = http.MultipartRequest('POST', uri);
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
