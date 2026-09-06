import 'dart:async';

import 'package:attendance/models/kiosk_model.dart';
import 'package:attendance/services/kiosk/kiosk_service.dart';
import 'package:flutter/foundation.dart';

class KioskController extends ChangeNotifier {
  final KioskService _service;

  KioskController({
    KioskService? service,
  }) : _service = service ?? KioskService();

  // ============================================================
  // STATE
  // ============================================================

  KioskModel? _kiosk;

  bool _isLoading = false;

  bool _isAuthenticated = false;

  String? _errorMessage;

  Timer? _heartbeatTimer;

  // ============================================================
  // GETTERS
  // ============================================================

  KioskModel? get kiosk => _kiosk;

  bool get isLoading => _isLoading;

  bool get isAuthenticated =>
      _isAuthenticated;

  String? get errorMessage =>
      _errorMessage;

  bool get hasKiosk =>
      _kiosk != null;

  // ============================================================
  // LOGIN
  // ============================================================
  //
  // Authentification avec :
  //
  //     NOM + CODE
  //
  // Aucun api_key.
  //
  // ============================================================

  Future<bool> login({
    required String name,
    required String code,
    String? deviceId,
    String? deviceName,
    String? deviceModel,
    String? platform,
    String? appVersion,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final kiosk =
          await _service.login(
        name: name,
        code: code,
        deviceId: deviceId,
        deviceName: deviceName,
        deviceModel: deviceModel,
        platform: platform,
        appVersion: appVersion,
      );

      _kiosk = kiosk;

      _isAuthenticated = true;

      _errorMessage = null;

      _startHeartbeat(
        appVersion: kiosk.appVersion ??
            appVersion,
      );

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        '❌ KIOSK LOGIN ERROR: $e',
      );

      _errorMessage =
          _cleanError(e);

      _isAuthenticated = false;

      _kiosk = null;

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CHECK SESSION
  // ============================================================

  Future<bool> checkSession() async {
    final token =
        await _service.getToken();

    if (token == null ||
        token.isEmpty) {
      _isAuthenticated = false;
      _kiosk = null;

      notifyListeners();

      return false;
    }

    try {
      final kiosk =
          await _service.me();

      _kiosk = kiosk;

      _isAuthenticated = true;

      _errorMessage = null;

      _startHeartbeat(
        appVersion: kiosk.appVersion,
      );

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        '❌ KIOSK SESSION ERROR: $e',
      );

      /*
       * Si le serveur renvoie 401/403,
       * la session n'est plus valide.
       *
       * On déconnecte alors le Kiosk.
       */
      if (_isAuthenticationError(e)) {
        await logout();
      } else {
        /*
         * Pour une simple erreur réseau,
         * on peut conserver la session locale.
         */
        _errorMessage =
            _cleanError(e);

        notifyListeners();
      }

      return false;
    }
  }

  // ============================================================
  // HEARTBEAT
  // ============================================================

  void _startHeartbeat({
    String? appVersion,
  }) {
    _heartbeatTimer?.cancel();

    /*
     * Premier heartbeat après 2 minutes.
     */

    _heartbeatTimer =
        Timer.periodic(
      const Duration(minutes: 2),
      (_) async {
        try {
          await _service.heartbeat(
            appVersion: appVersion,
          );

          debugPrint(
            '💓 Kiosk heartbeat envoyé',
          );
        } catch (e) {
          debugPrint(
            '❌ Heartbeat error: $e',
          );

          /*
           * Une coupure réseau temporaire
           * ne détruit PAS la session.
           */
        }
      },
    );
  }

  // ============================================================
  // QR
  // ============================================================

  Future<Map<String, dynamic>?> scanQr(
    String qrToken,
  ) async {
    try {
      _errorMessage = null;

      final result =
          await _service.scanQr(
        qrToken,
      );

      notifyListeners();

      return result;
    } catch (e) {
      debugPrint(
        '❌ KIOSK QR ERROR: $e',
      );

      _errorMessage =
          _cleanError(e);

      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // PIN
  // ============================================================

  Future<Map<String, dynamic>?> checkPin({
    required String employeeCode,
    required String pin,
  }) async {
    try {
      _errorMessage = null;

      final result =
          await _service.checkPin(
        employeeCode: employeeCode,
        pin: pin,
      );

      notifyListeners();

      return result;
    } catch (e) {
      debugPrint(
        '❌ KIOSK PIN ERROR: $e',
      );

      _errorMessage =
          _cleanError(e);

      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<Map<String, dynamic>?> cameraCheck({
    required String qrToken,
    double? latitude,
    double? longitude,
  }) async {
    try {
      _errorMessage = null;

      final result =
          await _service.cameraCheck(
        qrToken: qrToken,
        latitude: latitude,
        longitude: longitude,
      );

      notifyListeners();

      return result;
    } catch (e) {
      debugPrint(
        '❌ KIOSK CAMERA ERROR: $e',
      );

      _errorMessage =
          _cleanError(e);

      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = null;

    await _service.logout();

    _kiosk = null;

    _isAuthenticated = false;

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;

    notifyListeners();
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  bool _isAuthenticationError(
    Object error,
  ) {
    final message =
        error.toString().toLowerCase();

    return message.contains('401') ||
        message.contains('403') ||
        message.contains('session kiosk expirée') ||
        message.contains('non authentifié') ||
        message.contains('token');
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = null;

    super.dispose();
  }
}