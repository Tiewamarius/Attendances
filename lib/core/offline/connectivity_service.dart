import 'dart:async';

import 'package:attendance/core/network/api_endpoints.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Détecte si le SERVEUR est joignable (pas seulement le Wi-Fi) :
/// un serveur local éteint doit aussi déclencher le mode hors ligne.
///
/// N'importe quelle réponse HTTP (même 401/404) = serveur joignable.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  /// true = serveur joignable.
  final ValueNotifier<bool> online = ValueNotifier<bool>(true);

  Timer? _timer;
  bool _checking = false;

  /// Démarre la surveillance (idempotent).
  void start({Duration interval = const Duration(seconds: 10)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => check());
    check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Vérifie immédiatement l'accès au serveur.
  Future<bool> check() async {
    if (_checking) return online.value;

    _checking = true;

    try {
      await http
          .get(Uri.parse(ApiConfig.baseUrl))
          .timeout(const Duration(seconds: 4));

      _set(true);
    } catch (_) {
      _set(false);
    } finally {
      _checking = false;
    }

    return online.value;
  }

  /// À appeler quand une requête échoue pour cause réseau :
  /// passe tout de suite en hors ligne sans attendre le prochain test.
  void reportFailure() => _set(false);

  void _set(bool value) {
    if (online.value != value) {
      online.value = value;
      debugPrint('[CONNECTIVITY] ${value ? 'EN LIGNE' : 'HORS LIGNE'}');
    }
  }
}

/// true si l'erreur vient du réseau (serveur injoignable, délai dépassé)
/// et non d'un refus du serveur (PIN incorrect, QR expiré...).
bool isNetworkError(Object error) {
  if (error is TimeoutException) return true;
  if (error is http.ClientException) return true;

  final text = error.toString();

  return text.contains('SocketException') ||
      text.contains('Connection refused') ||
      text.contains('Failed host lookup') ||
      text.contains('Network is unreachable');
}
