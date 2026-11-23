import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/core/offline/connectivity_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// QR personnel de l'employé connecté (lu par la caméra du kiosk).
class QrService {
  Future<Map<String, String>> _headers(String token) =>
      AuthService.userHeaders(token: token);

  /// Retourne le token QR actif (créé côté serveur s'il n'existe pas).
  ///
  /// Hors ligne : retourne la dernière copie locale (le QR est permanent,
  /// il reste lisible par le kiosk, qui le synchronisera plus tard).
  Future<String> getMyQr(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.myQr),
            headers: await _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      final value = _extractToken(response);

      await _saveCache(token, value);

      return value;
    } catch (e) {
      if (isNetworkError(e)) {
        ConnectivityService.instance.reportFailure();

        final cached = await _readCache(token);

        if (cached != null) return cached;

        throw Exception(
          'Hors ligne : ouvrez cet écran une fois avec la connexion '
          'pour enregistrer votre QR.',
        );
      }

      rethrow;
    }
  }

  /// Révoque l'ancien QR et retourne le nouveau token (nécessite la connexion).
  Future<String> refreshMyQr(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.myQrRefresh),
            headers: await _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      final value = _extractToken(response);

      await _saveCache(token, value);

      return value;
    } catch (e) {
      if (isNetworkError(e)) {
        throw Exception('Renouvellement impossible hors ligne.');
      }

      rethrow;
    }
  }

  // Clé liée à la session : un autre compte ne voit jamais ce QR.
  String _cacheKey(String token) => 'cache_my_qr_${token.hashCode}';

  Future<void> _saveCache(String token, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(token), value);
  }

  Future<String?> _readCache(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKey(token));
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
