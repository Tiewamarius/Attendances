import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/offline/connectivity_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cache de lecture : les écrans restent consultables sans réseau.
///
/// Principe « réseau d'abord » :
/// - serveur joignable : réponse du serveur, copie gardée sur l'appareil ;
/// - serveur injoignable (coupure, délai dépassé) : dernière copie connue.
///
/// Une erreur du serveur (401, 403, 422...) n'est JAMAIS remplacée par le
/// cache : seules les pannes réseau le sont.
///
/// Le cache est propre à l'organisation active et effacé à la déconnexion.
class ReadCache {
  ReadCache._();

  static const String _prefix = 'rc:';

  /// Délai max avant de considérer le serveur injoignable.
  static const Duration _timeout = Duration(seconds: 8);

  /// Drop-in pour `http.get(...)` : remplacez
  /// `await http.get(url, headers: h)` par
  /// `await ReadCache.cachedGet('nom', () async => http.get(url, headers: await h))`.
  static Future<http.Response> cachedGet(
    String name,
    Future<http.Response> Function() request,
  ) async {
    final key = await _key(name);
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await request().timeout(_timeout);

      if (response.statusCode == 200) {
        await prefs.setString(key, response.body);
      }

      return response;
    } catch (e) {
      if (!isNetworkError(e)) rethrow;

      ConnectivityService.instance.reportFailure();

      final cached = prefs.getString(key);

      if (cached == null) rethrow;

      return http.Response.bytes(
        utf8.encode(cached),
        200,
        headers: const {
          'content-type': 'application/json; charset=utf-8',
          'x-offline-cache': '1',
        },
      );
    }
  }

  /// true si la réponse vient de la copie locale (affichage « hors ligne »).
  static bool isFromCache(http.Response response) =>
      response.headers['x-offline-cache'] == '1';

  /// Efface toutes les copies locales (déconnexion, changement de compte).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    // 'cache_' : copies faites par l'historique de présence et le QR employé.
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_prefix) || k.startsWith('cache_'));

    for (final key in keys.toList()) {
      await prefs.remove(key);
    }
  }

  static Future<String> _key(String name) async {
    final organizationId = await AuthService.getOrganizationId();

    return '$_prefix${organizationId ?? 0}:$name';
  }
}
