import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:http/http.dart' as http;

/// QR personnel de l'employé connecté (lu par la caméra du kiosk).
class QrService {
  Future<Map<String, String>> _headers(String token) =>
      AuthService.userHeaders(token: token);

  /// Retourne le token QR actif (créé côté serveur s'il n'existe pas).
  Future<String> getMyQr(String token) async {
    final response = await http.get(
      Uri.parse(ApiConfig.myQr),
      headers: await _headers(token),
    );

    return _extractToken(response);
  }

  /// Révoque l'ancien QR et retourne le nouveau token.
  Future<String> refreshMyQr(String token) async {
    final response = await http.post(
      Uri.parse(ApiConfig.myQrRefresh),
      headers: await _headers(token),
    );

    return _extractToken(response);
  }

  String _extractToken(http.Response response) {
    Map<String, dynamic> body = {};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) body = Map<String, dynamic>.from(decoded);
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['message']?.toString() ??
            'Impossible de récupérer votre QR (${response.statusCode}).',
      );
    }

    final qr = (body['data'] is Map) ? body['data']['qr'] : null;
    final value = qr is Map ? qr['token']?.toString() : null;

    if (value == null || value.isEmpty) {
      throw Exception('QR absent dans la réponse du serveur.');
    }

    return value;
  }
}
