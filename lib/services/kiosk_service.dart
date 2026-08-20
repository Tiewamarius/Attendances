import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/model_kiosk.dart';
import 'package:http/http.dart' as http;

class KioskService {
  KioskService._();

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers({
    bool json = false,
  }) async {
    final token = await AuthService.getToken();

    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET KIOSKS
  // ============================================================

  static Future<List<KioskModel>> getKiosks() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.kiosks),
        headers: await _headers(),
      );

      print('KIOSKS STATUS : ${response.statusCode}');
      print('KIOSKS RESPONSE : ${response.body}');

      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body);

      final List data = body['data'] ?? body;

      return data
          .map(
            (item) => KioskModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (e) {
      print('Erreur KIOSKS : $e');
      return [];
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  static Future<bool> createKiosk({
    required String name,
    required String code,
    required String location,
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
          'code': code,
          'location': location,
          'method': method,
          'ip_address': ipAddress,
          'active': active,
        }),
      );

      print('CREATE KIOSK STATUS : ${response.statusCode}');
      print('CREATE KIOSK RESPONSE : ${response.body}');

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      print('Erreur création kiosk : $e');
      return false;
    }
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  static Future<bool> toggleKiosk(int id) async {
    try {
      final response = await http.patch(
        Uri.parse(ApiConfig.kioskToggle(id)),
        headers: await _headers(),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  static Future<bool> deleteKiosk(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.kiosk(id)),
        headers: await _headers(),
      );

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}