// lib/api/api_client.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._internal({String? baseUrl})
      : _baseUrl = baseUrl ?? _defaultBaseUrl;
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
  final _headers = const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  // ✅ 改成 /api/profile（若你的實際路徑不同，改這行即可）
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) async {
    final resp = await http
        .post(_uri('$_apiBasePath/profile'),
            headers: _headers, body: jsonEncode(profile))
        .timeout(_timeout);
    return _decode(resp);
  }

  // ✅ 改成 /api/health
  Future<bool> ping() async {
    final resp = await http
        .get(_uri('$_apiBasePath/health'), headers: _headers)
        .timeout(_timeout);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Map<String, dynamic> _decode(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return <String, dynamic>{};
      final body = utf8.decode(resp.bodyBytes);
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }
    final body = resp.bodyBytes.isNotEmpty ? utf8.decode(resp.bodyBytes) : '';
    throw ApiException(resp.statusCode,
        body.isEmpty ? 'HTTP ${resp.statusCode}' : body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
