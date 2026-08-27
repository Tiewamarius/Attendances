import 'dart:async';

import 'package:attendance/models/kiosk/kiosk_model.dart';
import 'package:attendance/services/kiosk/kiosk_service.dart';
import 'package:flutter/foundation.dart';

class KioskController extends ChangeNotifier {
  final KioskService _service;

  KioskController({
    KioskService? service,
  }) : _service = service ?? KioskService();

  // ============================================================
  // ÉTAT
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

  bool get isAuthenticated => _isAuthenticated;

  String? get errorMessage => _errorMessage;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login({
    required String code,
    required String apiKey,
    String? deviceId,
    String? deviceName,
    String? deviceModel,
    String? platform,
    String? appVersion,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final kiosk = await _service.login(
        code: code,
        apiKey: apiKey,
        deviceId: deviceId,
        deviceName: deviceName,
        deviceModel: deviceModel,
        platform: platform,
        appVersion: appVersion,
      );

      _kiosk = kiosk;
      _isAuthenticated = true;

      _startHeartbeat(
        appVersion: appVersion,
      );

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint(
        '❌ KIOSK LOGIN ERROR: $e',
      );

      _errorMessage =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      _isAuthenticated = false;

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
    try {
      final token =
          await _service.getToken();

      if (token == null ||
          token.trim().isEmpty) {
        return false;
      }

      final kiosk =
          await _service.me();

      _kiosk = kiosk;
      _isAuthenticated = true;

      notifyListeners();

      _startHeartbeat();

      return true;
    } catch (e) {
      debugPrint(
        '❌ KIOSK SESSION ERROR: $e',
      );

      await logout();

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

    _heartbeatTimer = Timer.periodic(
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
        }
      },
    );
  }

  // ============================================================
  // SCAN QR
  // ============================================================

  Future<Map<String, dynamic>?> scanQr(
    String qrToken,
  ) async {
    try {
      _errorMessage = null;

      return await _service.scanQr(
        qrToken,
      );
    } catch (e) {
      _errorMessage =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

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

      return await _service.checkPin(
        employeeCode: employeeCode,
        pin: pin,
      );
    } catch (e) {
      _errorMessage =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<Map<String, dynamic>?> cameraCheck({
    required String qrToken,
  }) async {
    try {
      _errorMessage = null;

      return await _service.cameraCheck(
        qrToken: qrToken,
      );
    } catch (e) {
      _errorMessage =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    _heartbeatTimer?.cancel();

    await _service.logout();

    _kiosk = null;
    _isAuthenticated = false;
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}