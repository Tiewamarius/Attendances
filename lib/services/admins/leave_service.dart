import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/admins/leave_model..dart';
import 'package:http/http.dart' as http;


class LeaveService {
  LeaveService._();

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // LISTE DES CONGES
  // ============================================================

  static Future<List<LeaveModel>> getLeaves() async {
    final response = await http.get(
      Uri.parse(ApiConfig.leaves),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Impossible de charger les congés '
        '(${response.statusCode})',
      );
    }

    final body = jsonDecode(response.body);

    dynamic data = body;

    if (body is Map && body['data'] != null) {
      data = body['data'];
    }

    if (data is Map && data['data'] != null) {
      data = data['data'];
    }

    if (data is! List) {
      return [];
    }

    return data
        .map(
          (item) => LeaveModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ============================================================
  // APPROUVER MANAGER
  // ============================================================

  static Future<void> managerApprove(int id) async {
    final response = await http.post(
      Uri.parse(ApiConfig.managerApproveLeave(id)),
      headers: await _headers(),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        _extractError(response),
      );
    }
  }

  // ============================================================
  // REFUSER MANAGER
  // ============================================================

  static Future<void> managerReject(int id) async {
    final response = await http.post(
      Uri.parse(ApiConfig.managerRejectLeave(id)),
      headers: await _headers(),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        _extractError(response),
      );
    }
  }

  // ============================================================
  // APPROUVER HR
  // ============================================================

  static Future<void> hrApprove(int id) async {
    final response = await http.post(
      Uri.parse(ApiConfig.hrApproveLeave(id)),
      headers: await _headers(),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        _extractError(response),
      );
    }
  }

  // ============================================================
  // REFUSER HR
  // ============================================================

  static Future<void> hrReject(int id) async {
    final response = await http.post(
      Uri.parse(ApiConfig.hrRejectLeave(id)),
      headers: await _headers(),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        _extractError(response),
      );
    }
  }

  // ============================================================
  // ERREUR API
  // ============================================================

  static String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map) {
        return body['message']?.toString() ??
            body['error']?.toString() ??
            'Erreur serveur (${response.statusCode})';
      }
    } catch (_) {}

    return 'Erreur serveur (${response.statusCode})';
  }
}