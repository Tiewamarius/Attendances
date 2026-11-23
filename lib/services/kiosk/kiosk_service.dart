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

  /// Délai max d'une requête : au-delà, le kiosk passe hors ligne.
  static const Duration _requestTimeout = Duration(seconds: 8);

  // ============================================================
  // KIOSK EN CACHE (démarrage hors ligne)
  // ============================================================

  Future<KioskModel?> getCachedKiosk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kioskDataKey);

    if (raw == null || raw.isEmpty) return null;

    try {
      return KioskModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw)),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // SYNCHRONISATION DES POINTAGES HORS LIGNE
  // ============================================================

  /// Retourne un résultat par pointage traité :
  /// { client_id, status: 'synced'|'rejected', message, employee }.
  Future<List<Map<String, dynamic>>> syncPunches(
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _authorizedPost(
      ApiConfig.kioskSync,
      {'items': items},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response));
    }

    final data = _decodeMap(response)['data'];

    return data is List
        ? data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
  }

  // ============================================================
  // ANNUAIRE HORS LIGNE
  // ============================================================

  /// Jeu de données (empreintes QR/PIN, état du jour) pour reconnaître
  /// les employés sans réseau. Voir KioskDirectory.
  Future<Map<String, dynamic>> getSyncData() async {
    final response = await _authorizedGet(ApiConfig.kioskSyncData);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response));
    }

    final data = _decodeMap(response)['data'];

    if (data is! Map) {
      throw Exception('Réponse serveur invalide.');
    }

    return Map<String, dynamic>.from(data);
  }

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

  /// Le PIN est unique dans l'organisation : il identifie seul
  /// l'employé, aucun code employé n'est envoyé.
  Future<Map<String, dynamic>> checkPin({
    required String pin,
    String? employeeCode,
  }) async {
    final cleanPin =
        pin.trim();

    if (cleanPin.isEmpty) {
      throw Exception(
        'Le PIN est obligatoire.',
      );
    }

    debugPrint(
      'KIOSK CHECK PIN',
    );

    final response =
        await _authorizedPost(
      ApiConfig.kioskPin,
      {
        'pin': cleanPin,
        // Seulement si le PIN est partagé entre plusieurs employés.
        if (employeeCode != null && employeeCode.trim().isNotEmpty)
          'employee_code': employeeCode.trim(),
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
  // SCAN EVENTS (QR scanné avec le téléphone de l'employé)
  // ============================================================

  /// Sans [afterId] : retourne seulement `last_id` (amorçage).
  /// Avec [afterId] : retourne les nouveaux pointages.
  Future<({int lastId, List<Map<String, dynamic>> events})>
      getScanEvents({int? afterId}) async {
    final url = afterId == null
        ? ApiConfig.kioskScanEvents
        : '${ApiConfig.kioskScanEvents}?after=$afterId';

    final response = await _authorizedGet(url);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response));
    }

    final body = _decodeMap(response);

    final rawEvents = body['data'];

    return (
      lastId: int.tryParse('${body['last_id']}') ?? 0,
      events: rawEvents is List
          ? rawEvents
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[],
    );
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
    ).timeout(_requestTimeout);
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
    ).timeout(_requestTimeout);
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