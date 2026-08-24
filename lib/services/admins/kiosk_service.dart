import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/admins/kiosk_model..dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class KioskService {
  KioskService._();

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await AuthService.getToken();

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
      if (json) 'Content-Type': 'application/json',
    };
  }

  // ============================================================
  // GET KIOSKS
  // ============================================================

  static Future<List<KioskModel>> getKiosks() async {
    final response = await http.get(
      Uri.parse(ApiConfig.kiosks),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Impossible de récupérer les kiosks '
        '(${response.statusCode})',
      );
    }

    final body = jsonDecode(response.body);

    final data = body['data'] ?? body;

    if (data is! List) {
      throw Exception('Format de réponse kiosks invalide');
    }

    return data
        .map<KioskModel>(
          (item) => KioskModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  // ============================================================
  // GET KIOSK
  // ============================================================

  static Future<KioskModel> getKiosk(int id) async {
    final response = await http.get(
      Uri.parse(ApiConfig.kiosk(id)),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Impossible de récupérer le kiosk '
        '(${response.statusCode})',
      );
    }

    final body = jsonDecode(response.body);

    final data = body['data'] ?? body;

    return KioskModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ============================================================
  // CREATE
  // ============================================================

  // ============================================================
// CREATE
// ============================================================

static Future<KioskModel> createKiosk({
  required String name,
  String? location,
  required String method,
  String? ipAddress,
  required bool active,
}) async {
  try {
    final response = await http.post(
      Uri.parse(ApiConfig.kiosks),
      headers: await _headers(json: true),
      body: jsonEncode({
        'name': name,
        'location': location,
        'method': method,
        'ip_address': ipAddress,
        'active': active,
      }),
    );

    debugPrint(
      'CREATE KIOSK STATUS: ${response.statusCode}',
    );

    debugPrint(
      'CREATE KIOSK BODY: ${response.body}',
    );

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      
      final body = jsonDecode(response.body);

      final data = body['data'] ?? body;

      if (data is! Map) {
        throw Exception(
          'Format de réponse du kiosk invalide',
        );
      }

      return KioskModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    throw Exception(_extractError(response));
  } catch (e) {
    debugPrint(
      'Erreur KioskService.createKiosk(): $e',
    );

    rethrow;
  }
}
  // ============================================================
  // UPDATE
  // ============================================================

  static Future<KioskModel> updateKiosk({
    required int id,
    required String name,
    // required String code,
    String? location,
    required String method,
    String? ipAddress,
    required bool active,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.kiosk(id)),
      headers: await _headers(json: true),
      body: jsonEncode({
        'name': name,
        // 'code': code,
        'location': location,
        'method': method,
        'ip_address': ipAddress,
        'active': active,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final body = jsonDecode(response.body);

    final data = body['data'] ?? body;

    return KioskModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  static Future<KioskModel> toggleKiosk(int id) async {
    final response = await http.patch(
      Uri.parse(ApiConfig.kioskToggle(id)),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final body = jsonDecode(response.body);

    final data = body['data'] ?? body;

    return KioskModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ============================================================
  // DELETE
  // ============================================================

  static Future<void> deleteKiosk(int id) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.kiosk(id)),
      headers: await _headers(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  static String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      return body['message']?.toString() ??
          'Erreur serveur (${response.statusCode})';
    } catch (_) {
      return 'Erreur serveur (${response.statusCode})';
    }
  }
}
