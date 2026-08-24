import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/employees/employee_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmployeeService {
  EmployeeService._();

  static final EmployeeService instance = EmployeeService._();

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers({
    bool json = false,
  }) async {
    final token = await AuthService.getToken();

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    debugPrint('========================================');
    debugPrint('EMPLOYEE API HEADERS');
    debugPrint('TOKEN PRESENT: ${token != null && token.isNotEmpty}');
    debugPrint('========================================');

    return headers;
  }

  // ============================================================
  // GET PROFILE
  // ============================================================

  Future<EmployeeModel> getProfile() async {
  try {
    final headers = await _headers();

    debugPrint('========================================');
    debugPrint('GET EMPLOYEE PROFILE');
    debugPrint('URL: ${ApiConfig.dashboard}');
    debugPrint('========================================');

    final response = await http.get(
      Uri.parse(ApiConfig.dashboard),
      headers: headers,
    );

    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('========================================');

    // ==========================================================
    // 401
    // ==========================================================

    if (response.statusCode == 401) {
      throw Exception(
        'Session expirée ou token invalide. Veuillez vous reconnecter.',
      );
    }

    // ==========================================================
    // AUTRES ERREURS
    // ==========================================================

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Erreur serveur (${response.statusCode})',
      );
    }

    // ==========================================================
    // DECODAGE JSON
    // ==========================================================

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Format de réponse API invalide.',
      );
    }

    // ==========================================================
    // DATA
    // ==========================================================

    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'La propriété "data" est absente ou invalide.',
      );
    }

    // ==========================================================
    // USER
    // ==========================================================

    final user = data['user'];

    if (user is! Map<String, dynamic>) {
      throw Exception(
        'Les informations utilisateur sont absentes.',
      );
    }

    // ==========================================================
    // EMPLOYEE
    // ==========================================================

    final employee = user['employee'];

    if (employee is! Map<String, dynamic>) {
      throw Exception(
        'Les informations employé sont absentes.',
      );
    }

    final employeeData = Map<String, dynamic>.from(employee);

    // On peut également récupérer certaines informations
    // provenant de "user".
    employeeData['user_id'] ??= user['id'];
    employeeData['email'] ??= user['email'];
    employeeData['name'] ??= user['name'];

    debugPrint('========================================');
    debugPrint('EMPLOYEE DATA EXTRAITE');
    debugPrint('$employeeData');
    debugPrint('========================================');

    return EmployeeModel.fromJson(employeeData);
  } catch (e) {
    debugPrint(
      'EmployeeService.getProfile ERROR: $e',
    );

    rethrow;
  }
}
}