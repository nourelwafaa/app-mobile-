import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  static const int _port = 3001;

  /// Sur un VRAI téléphone, mets l'IP de ton PC, ex :
  /// 'http://192.168.1.20:3001/api'  (téléphone et PC sur le même Wi-Fi)
  static const String? overrideBaseUrl = null;

  static String get baseUrl {
    if (overrideBaseUrl != null) return overrideBaseUrl!;
    // L'émulateur Android voit le PC via 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_port/api';
    }
    return 'http://localhost:$_port/api'; // simulateur iOS / web
  }

  String? token;

  /// Appelé quand le serveur répond 401 alors qu'on avait un token (session expirée)
  VoidCallback? onUnauthorized;

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
      _request('PUT', path, body: body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encoded = body == null ? null : jsonEncode(body);

    http.Response res;
    try {
      final Future<http.Response> call;
      switch (method) {
        case 'POST':
          call = http.post(uri, headers: headers, body: encoded);
          break;
        case 'PUT':
          call = http.put(uri, headers: headers, body: encoded);
          break;
        default:
          call = http.get(uri, headers: headers);
      }
      res = await call.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException('Le serveur ne répond pas. Réessayez.');
    } catch (_) {
      throw ApiException(
        'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    }

    dynamic decoded;
    try {
      decoded = res.body.isNotEmpty ? jsonDecode(res.body) : <String, dynamic>{};
    } catch (_) {
      decoded = <String, dynamic>{};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }

    final message = (decoded is Map && decoded['message'] != null)
        ? decoded['message'].toString()
        : 'Erreur (${res.statusCode})';

    if (res.statusCode == 401 && token != null) onUnauthorized?.call();
    throw ApiException(message, res.statusCode);
  }
}
