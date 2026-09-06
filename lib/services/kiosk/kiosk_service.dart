import 'dart:convert';

import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/kiosk_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KioskService {
  KioskService();

  // ============================================================
  // STORAGE
  // ============================================================

  static const String kioskTokenKey = 'kiosk_token';
  static const String kioskDataKey = 'kiosk_data';

  // ============================================================
  // LOGIN KIOSK
  // ============================================================

  /// Authentification du Kiosk :
  ///
  /// name + code
  ///
  /// Aucun api_key n'est envoyé par Flutter.
  Future<KioskModel> login({
    required String name,
    required String code,
    String? deviceId,
    String? deviceName,
    String? deviceModel,
    String? platform,
    String? appVersion,
  }) async {
    final cleanName = name.trim();
    final cleanCode = code.trim().toUpperCase();

    if (cleanName.isEmpty) {
      throw Exception(
        'Le nom du Kiosk est obligatoire.',
      );
    }

    if (cleanCode.isEmpty) {
      throw Exception(
        'Le code du Kiosk est obligatoire.',
      );
    }

    debugPrint('========================================');
    debugPrint('KIOSK LOGIN');
    debugPrint('URL: ${ApiConfig.kioskLogin}');
    debugPrint('NAME: $cleanName');
    debugPrint('CODE: $cleanCode');
    debugPrint('========================================');

    final response = await http.post(
      Uri.parse(ApiConfig.kioskLogin),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': cleanName,
        'code': cleanCode,
        if (deviceId != null && deviceId.trim().isNotEmpty)
          'device_id': deviceId.trim(),
        if (deviceName != null && deviceName.trim().isNotEmpty)
          'device_name': deviceName.trim(),
        if (deviceModel != null && deviceModel.trim().isNotEmpty)
          'device_model': deviceModel.trim(),
        if (platform != null && platform.trim().isNotEmpty)
          'platform': platform.trim(),
        if (appVersion != null && appVersion.trim().isNotEmpty)
          'app_version': appVersion.trim(),
      }),
    );

    debugPrint(
      'KIOSK LOGIN STATUS: ${response.statusCode}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    final body = _decodeMap(response);

    // ==========================================================
    // TOKEN SANCTUM
    // ==========================================================

    final dynamic token =
        body['token'] ??
        body['access_token'] ??
        _nestedValue(
          body,
          'data',
          'token',
        ) ??
        _nestedValue(
          body,
          'data',
          'access_token',
        );

    if (token == null ||
        token.toString().trim().isEmpty) {
      throw Exception(
        'Token Kiosk absent dans la réponse du serveur.',
      );
    }

    // ==========================================================
    // KIOSK
    // ==========================================================

    final dynamic kioskData =
        body['kiosk'] ??
        _nestedValue(
          body,
          'data',
          'kiosk',
        ) ??
        (body['data'] is Map ? body['data'] : null);

    if (kioskData is! Map) {
      throw Exception(
        'Informations du Kiosk absentes dans la réponse.',
      );
    }

    final kioskJson = Map<String, dynamic>.from(
      kioskData,
    );

    final kiosk = KioskModel.fromJson(
      kioskJson,
    );

    // ==========================================================
    // SAUVEGARDE SESSION KIOSK
    // ==========================================================

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      kioskTokenKey,
      token.toString().trim(),
    );

    await prefs.setString(
      kioskDataKey,
      jsonEncode(kioskJson),
    );

    debugPrint('KIOSK LOGIN SUCCESS');
    debugPrint('KIOSK ID: ${kiosk.id}');

    return kiosk;
  }

  // ============================================================
  // TOKEN KIOSK
  // ============================================================

  Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString(kioskTokenKey);

    if (token == null ||
        token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  // ============================================================
  // SESSION KIOSK
  // ============================================================

  Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null &&
        token.isNotEmpty;
  }

  // ============================================================
  // KIOSK ME
  // ============================================================

  Future<KioskModel> me() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Session Kiosk inexistante.',
      );
    }

    final response =
        await _authorizedGet(
      ApiConfig.kioskMe,
    );

    debugPrint(
      'KIOSK ME: ${response.statusCode}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    final body =
        _decodeMap(response);

    final dynamic kioskData =
        body['kiosk'] ??
        _nestedValue(
          body,
          'data',
          'kiosk',
        ) ??
        (body['data'] is Map
            ? body['data']
            : null);

    if (kioskData is! Map) {
      throw Exception(
        'Informations du Kiosk absentes.',
      );
    }

    final kioskJson =
        Map<String, dynamic>.from(
      kioskData,
    );

    final kiosk =
        KioskModel.fromJson(
      kioskJson,
    );

    // Mise à jour locale
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      kioskDataKey,
      jsonEncode(kioskJson),
    );

    return kiosk;
  }

  // ============================================================
  // QR DE POINTAGE DU KIOSK
  // ============================================================

  /// Récupère le token QR temporaire généré
  /// par Laravel.
  ///
  /// IMPORTANT :
  /// Ce token n'est PAS le token Sanctum du Kiosk.
  ///
  /// Laravel retourne normalement :
  ///
  /// {
  ///   "status": true,
  ///   "message": "...",
  ///   "data": {
  ///     "token": "...",
  ///     "expires_at": "...",
  ///     "kiosk_id": 1
  ///   }
  /// }
  ///
  /// Le service extrait uniquement :
  ///
  /// "token"
  ///
  /// et retourne un String.
  Future<String> getAttendanceQr() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Session Kiosk inexistante.',
      );
    }

    final response =
        await _authorizedGet(
      ApiConfig.kioskAttendanceQr,
    );

    debugPrint(
      'KIOSK ATTENDANCE QR: ${response.statusCode}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    final body =
        _decodeMap(response);

    // ==========================================================
    // FORMAT PRINCIPAL
    // ==========================================================

    dynamic qrToken;

    final dynamic data =
        body['data'];

    if (data is Map) {
      qrToken = data['token'];
    }

    // ==========================================================
    // FORMAT ALTERNATIF
    // ==========================================================

    qrToken ??= body['token'];

    if (qrToken == null ||
        qrToken.toString().trim().isEmpty) {
      throw Exception(
        'Token QR de pointage absent dans la réponse du serveur.',
      );
    }

    return qrToken.toString().trim();
  }

  // ============================================================
  // HEARTBEAT
  // ============================================================

  Future<void> heartbeat({
    String? appVersion,
  }) async {
    final data =
        <String, dynamic>{};

    if (appVersion != null &&
        appVersion.trim().isNotEmpty) {
      data['app_version'] =
          appVersion.trim();
    }

    final response =
        await _authorizedPost(
      ApiConfig.kioskHeartbeat,
      data,
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
    final cleanToken =
        qrToken.trim();

    if (cleanToken.isEmpty) {
      throw Exception(
        'Token QR invalide.',
      );
    }

    final response =
        await _authorizedPost(
      ApiConfig.kioskQr,
      {
        'token': cleanToken,
      },
    );

    debugPrint(
      'KIOSK SCAN QR: ${response.statusCode}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    return _decodeMap(response);
  }

  // ============================================================
  // PIN EMPLOYEE
  // ============================================================

  Future<Map<String, dynamic>> checkPin({
    required String employeeCode,
    required String pin,
  }) async {
    final cleanEmployeeCode =
        employeeCode.trim();

    final cleanPin =
        pin.trim();

    if (cleanEmployeeCode.isEmpty) {
      throw Exception(
        'Le code employé est obligatoire.',
      );
    }

    if (cleanPin.isEmpty) {
      throw Exception(
        'Le PIN est obligatoire.',
      );
    }

    debugPrint(
      'KIOSK CHECK PIN',
    );

    debugPrint(
      'EMPLOYEE CODE: $cleanEmployeeCode',
    );

    final response =
        await _authorizedPost(
      ApiConfig.kioskPin,
      {
        'employee_code':
            cleanEmployeeCode,
        'pin': cleanPin,
      },
    );

    debugPrint(
      'KIOSK CHECK PIN STATUS: ${response.statusCode}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    return _decodeMap(response);
  }

  // ============================================================
  // CAMERA CHECK
  // ============================================================

  Future<Map<String, dynamic>> cameraCheck({
    required String qrToken,
    double? latitude,
    double? longitude,
  }) async {
    final cleanToken =
        qrToken.trim();

    if (cleanToken.isEmpty) {
      throw Exception(
        'Token QR invalide.',
      );
    }

    final data =
        <String, dynamic>{
      'token': cleanToken,
    };

    if (latitude != null) {
      data['latitude'] =
          latitude;
    }

    if (longitude != null) {
      data['longitude'] =
          longitude;
    }

    debugPrint(
      'KIOSK CAMERA CHECK',
    );

    final response =
        await _authorizedPost(
      ApiConfig.kioskCameraCheck,
      data,
    );

    debugPrint(
      'KIOSK CAMERA CHECK STATUS: ${response.statusCode}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response),
      );
    }

    return _decodeMap(response);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  /// Le logout Kiosk est actuellement local.
  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      kioskTokenKey,
    );

    await prefs.remove(
      kioskDataKey,
    );

    debugPrint(
      'KIOSK SESSION SUPPRIMEE',
    );
  }

  // ============================================================
  // GET AUTHENTIFIE
  // ============================================================

  Future<http.Response> _authorizedGet(
    String url,
  ) async {
    final token =
        await getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Session Kiosk expirée.',
      );
    }

    return http.get(
      Uri.parse(url),
      headers: {
        'Accept':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
    );
  }

  // ============================================================
  // POST AUTHENTIFIE
  // ============================================================

  Future<http.Response> _authorizedPost(
    String url,
    Map<String, dynamic> data,
  ) async {
    final token =
        await getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Session Kiosk expirée.',
      );
    }

    return http.post(
      Uri.parse(url),
      headers: {
        'Accept':
            'application/json',
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  // ============================================================
  // DECODE JSON MAP
  // ============================================================

  Map<String, dynamic> _decodeMap(
    http.Response response,
  ) {
    try {
      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception(
          'Réponse serveur invalide.',
        );
      }

      return Map<String, dynamic>.from(
        decoded,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Réponse JSON invalide du serveur.',
      );
    }
  }

  // ============================================================
  // VALEUR IMBRIQUEE
  // ============================================================

  dynamic _nestedValue(
    Map<String, dynamic> body,
    String parent,
    String child,
  ) {
    final value =
        body[parent];

    if (value is Map) {
      return value[child];
    }

    return null;
  }

  // ============================================================
  // MESSAGE ERREUR
  // ============================================================

  String _extractErrorMessage(
    http.Response response,
  ) {
    try {
      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is Map) {
        // ------------------------------------------------------
        // MESSAGE
        // ------------------------------------------------------

        final message =
            decoded['message'];

        if (message != null &&
            message
                .toString()
                .trim()
                .isNotEmpty) {
          return message.toString();
        }

        // ------------------------------------------------------
        // ERROR
        // ------------------------------------------------------

        final error =
            decoded['error'];

        if (error != null &&
            error
                .toString()
                .trim()
                .isNotEmpty) {
          return error.toString();
        }

        // ------------------------------------------------------
        // LARAVEL VALIDATION
        // ------------------------------------------------------

        final errors =
            decoded['errors'];

        if (errors is Map) {
          for (final entry
              in errors.entries) {
            final value =
                entry.value;

            if (value is List &&
                value.isNotEmpty) {
              return value.first
                  .toString();
            }

            if (value != null) {
              return value.toString();
            }
          }
        }
      }
    } catch (_) {
      // Message générique ci-dessous.
    }

    switch (response.statusCode) {
      case 400:
        return 'Requête invalide.';

      case 401:
        return 'Session Kiosk invalide ou expirée.';

      case 403:
        return 'Accès Kiosk refusé.';

      case 404:
        return 'Ressource Kiosk introuvable.';

      case 422:
        return 'Les données envoyées sont invalides.';

      case 429:
        return 'Trop de tentatives. Veuillez patienter.';

      case 500:
        return 'Erreur interne du serveur.';

      default:
        return 'Erreur serveur (${response.statusCode}).';
    }
  }
}