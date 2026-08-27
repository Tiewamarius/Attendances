import 'dart:convert';

import 'package:attendance/models/kiosk/kiosk_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KioskService {
  static const String baseUrl =
      'http://192.168.1.8:8000/api/v1';

  static const String loginEndpoint =
      '$baseUrl/kiosk/login';

  static const String heartbeatEndpoint =
      '$baseUrl/kiosk/heartbeat';

  static const String scanQrEndpoint =
      '$baseUrl/kiosk/scan-qr';

  static const String checkPinEndpoint =
      '$baseUrl/kiosk/check-pin';

  static const String cameraCheckEndpoint =
      '$baseUrl/kiosk/camera-check';

  static const String meEndpoint =
      '$baseUrl/kiosk/me';

  static const String kioskTokenKey =
      'kiosk_token';

  static const String kioskDataKey =
      'kiosk_data';

  // ============================================================
  // LOGIN KIOSK
  // ============================================================

  Future<KioskModel> login({
    required String code,
    required String apiKey,
    String? deviceId,
    String? deviceName,
    String? deviceModel,
    String? platform,
    String? appVersion,
  }) async {
    debugPrint('========================================');
    debugPrint('KIOSK LOGIN');
    debugPrint('URL: $loginEndpoint');
    debugPrint('CODE: $code');
    debugPrint('========================================');

    final response = await http.post(
      Uri.parse(loginEndpoint),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'code': code,
        'api_key': apiKey,
        if (deviceId != null) 'device_id': deviceId,
        if (deviceName != null) 'device_name': deviceName,
        if (deviceModel != null) 'device_model': deviceModel,
        if (platform != null) 'platform': platform,
        if (appVersion != null) 'app_version': appVersion,
      }),
    );

    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    final body = jsonDecode(response.body);

    final token =
        body['token'] ??
        body['access_token'] ??
        body['data']?['token'] ??
        body['data']?['access_token'];

    if (token == null) {
      throw Exception(
        'Token Kiosk absent dans la réponse.',
      );
    }

    final kioskJson =
        body['kiosk'] ??
        body['data']?['kiosk'] ??
        body['data'];

    if (kioskJson is! Map<String, dynamic>) {
      throw Exception(
        'Informations du Kiosk absentes.',
      );
    }

    final kiosk = KioskModel.fromJson(kioskJson);

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      kioskTokenKey,
      token.toString(),
    );

    await prefs.setString(
      kioskDataKey,
      jsonEncode(kioskJson),
    );

    return kiosk;
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(kioskTokenKey);
  }

  // ============================================================
  // KIOSK CONNECTÉ
  // ============================================================

  Future<KioskModel> me() async {
    final response = await _authorizedGet(
      meEndpoint,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    final body = jsonDecode(response.body);

    final kioskJson =
        body['kiosk'] ??
        body['data']?['kiosk'] ??
        body['data'];

    return KioskModel.fromJson(
      Map<String, dynamic>.from(kioskJson),
    );
  }

  // ============================================================
  // HEARTBEAT
  // ============================================================

  Future<void> heartbeat({
    String? appVersion,
  }) async {
    final response = await _authorizedPost(
      heartbeatEndpoint,
      {
        if (appVersion != null)
          'app_version': appVersion,
      },
    );

    debugPrint(
      'KIOSK HEARTBEAT: ${response.statusCode}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }
  }

  // ============================================================
  // SCAN QR EMPLOYEE
  // ============================================================

  Future<Map<String, dynamic>> scanQr(
    String qrToken,
  ) async {
    debugPrint('========================================');
    debugPrint('KIOSK SCAN QR');
    debugPrint('TOKEN: $qrToken');
    debugPrint('========================================');

    final response = await _authorizedPost(
      scanQrEndpoint,
      {
        'qr_token': qrToken,
      },
    );

    debugPrint(
      'STATUS: ${response.statusCode}',
    );

    debugPrint(
      'BODY: ${response.body}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  // ============================================================
  // PIN
  // ============================================================

  Future<Map<String, dynamic>> checkPin({
    required String employeeCode,
    required String pin,
  }) async {
    final response = await _authorizedPost(
      checkPinEndpoint,
      {
        'employee_code': employeeCode,
        'pin': pin,
      },
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  // ============================================================
  // CAMERA CHECK
  // ============================================================

  Future<Map<String, dynamic>> cameraCheck({
    required String qrToken,
  }) async {
    final response = await _authorizedPost(
      cameraCheckEndpoint,
      {
        'qr_token': qrToken,
      },
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(kioskTokenKey);
    await prefs.remove(kioskDataKey);
  }

  // ============================================================
  // AUTHORIZED GET
  // ============================================================

  Future<http.Response> _authorizedGet(
    String url,
  ) async {
    final token = await getToken();

    return http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // ============================================================
  // AUTHORIZED POST
  // ============================================================

  Future<http.Response> _authorizedPost(
    String url,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();

    return http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _extractErrorMessage(
    http.Response response,
  ) {
    try {
      final body = jsonDecode(response.body);

      return body['message'] ??
          body['error'] ??
          'Erreur serveur (${response.statusCode})';
    } catch (_) {
      return 'Erreur serveur (${response.statusCode})';
    }
  }
}