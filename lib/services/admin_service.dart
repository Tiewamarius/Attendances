import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/model_department.dart';
import 'package:attendance/models/model_roles.dart';
import 'package:attendance/models/users/user_model.dart';
import 'package:http/http.dart' as http;

class AdminService {
  AdminService._();

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
  // PROFIL
  // ============================================================

  static Future<UserModel?> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminMe),
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body);

      final data = body['data'] ?? body;

      final user = data['user'] ?? data;

      return UserModel.fromJson(
        Map<String, dynamic>.from(user),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.adminUpdate),
        headers: await _headers(json: true),
        body: jsonEncode({
          'name': name,
          'email': email,
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // DEPARTEMENTS
  // ============================================================

  static Future<List<DepartmentModel>> getDepartments() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.departments),
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body);

      final List data = body['data'] ?? body;

      return data
          .map(
            (item) => DepartmentModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> createDepartment({
    required String name,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.departments),
        headers: await _headers(json: true),
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteDepartment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.department(id)),
        headers: await _headers(),
      );

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // ROLES
  // ============================================================

  static Future<List<RoleModel>> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.roles),
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body);

      final List data = body['data'] ?? body;

      return data
          .map(
            (item) => RoleModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> createRole({
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.roles),
        headers: await _headers(json: true),
        body: jsonEncode({
          'name': name,
        }),
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}