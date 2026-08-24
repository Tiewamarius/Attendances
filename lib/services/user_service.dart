import 'dart:convert';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/admins/dashboard_model.dart';
import 'package:attendance/models/admins/department_model.dart';
import 'package:attendance/models/admins/model_roles.dart';
import 'package:attendance/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserService {
  UserService._();

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
  // RESPONSE
  // ============================================================

  static dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // PROFIL ADMIN
  // ============================================================

  static Future<UserModel?> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.dashboard),
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final body = _decodeResponse(response);

      if (body == null) {
        return null;
      }

      final dynamic rawData = body is Map
          ? body['data'] ?? body
          : body;

      if (rawData is! Map) {
        return null;
      }

      final dynamic rawUser =
          rawData['user'] ?? rawData;

      if (rawUser is! Map) {
        return null;
      }

      return UserModel.fromJson(
        Map<String, dynamic>.from(rawUser),
      );
    } catch (_) {
      return null;
    }
  }

Future<AdminDashboardModel> getDashboard() async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expirée.');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.dashboard),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'Dashboard status: ${response.statusCode}',
      );

      debugPrint(
        'Dashboard response: ${response.body}',
      );

      final body = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          body['message'] ??
              'Impossible de récupérer le dashboard.',
        );
      }

      if (body['success'] != true) {
        throw Exception(
          body['message'] ??
              'Erreur lors du chargement du dashboard.',
        );
      }

      return AdminDashboardModel.fromJson(
        body['data'] ?? {},
      );
    } catch (e) {
      debugPrint( 'Erreur getDashboard(): $e',
      );

      rethrow;
    }
  }
  // ============================================================
// ROLES - SPATIE
// GET /users/roles
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

    final body = _decodeResponse(response);

    if (body == null) {
      return [];
    }

    dynamic data;

    if (body is Map) {
      data = body['data'] ?? body;
    } else {
      data = body;
    }

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => RoleModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  } catch (e) {
    return [];
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

      final body = _decodeResponse(response);

      if (body == null) {
        return [];
      }

      dynamic data;

      if (body is Map) {
        data = body['data'] ?? body;
      } else {
        data = body;
      }

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
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

  // ============================================================
  // DEPARTEMENT - DETAIL
  // ============================================================

  static Future<DepartmentModel?> getDepartment(
    int id,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          ApiConfig.department(id),
        ),
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final body = _decodeResponse(response);

      if (body == null) {
        return null;
      }

      final dynamic data = body is Map
          ? body['data'] ?? body
          : body;

      if (data is! Map) {
        return null;
      }

      return DepartmentModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // DEPARTEMENT - CREATION
  // ============================================================

  static Future<DepartmentModel?> createDepartment({
    required String name,
    String? description,
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

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        return null;
      }

      final body = _decodeResponse(response);

      if (body == null) {
        return null;
      }

      final dynamic data = body is Map
          ? body['data'] ?? body
          : body;

      if (data is! Map) {
        return null;
      }

      return DepartmentModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // DEPARTEMENT - MODIFICATION
  // ============================================================

  static Future<DepartmentModel?> updateDepartment({
    required int id,
    required String name,
    String? description,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          ApiConfig.department(id),
        ),
        headers: await _headers(json: true),
        body: jsonEncode({
          'name': name,
          'description': ?description,
        }),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final body = _decodeResponse(response);

      if (body == null) {
        return null;
      }

      final dynamic data = body is Map
          ? body['data'] ?? body
          : body;

      if (data is! Map) {
        return null;
      }

      return DepartmentModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // DEPARTEMENT - SUPPRESSION
  // ============================================================

  static Future<bool> deleteDepartment(
    int id,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(
          ApiConfig.department(id),
        ),
        headers: await _headers(),
      );

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // UTILISATEURS
  // ============================================================

  static Future<List<UserModel>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.users),
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final body = _decodeResponse(response);

      if (body == null) {
        return [];
      }

      dynamic data;

      if (body is Map) {
        data = body['data'] ?? body;
      } else {
        data = body;
      }

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map(
            (item) => UserModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // UTILISATEUR - DETAIL
  // ============================================================

  static Future<UserModel?> getUser(
    int id,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.user(id)),
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final body = _decodeResponse(response);

      if (body == null) {
        return null;
      }

      final dynamic data = body is Map
          ? body['data'] ?? body
          : body;

      if (data is! Map) {
        return null;
      }

      return UserModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // UTILISATEUR - CREATION
  // ============================================================

  static Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.users),
        headers: await _headers(json: true),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // UTILISATEUR - MODIFICATION
  // ============================================================

  static Future<bool> updateUser({
    required int id,
    required String name,
    required String email,
    String? role,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.user(id)),
        headers: await _headers(json: true),
        body: jsonEncode({
          'name': name,
          'email': email,
          'role': role,
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // UTILISATEUR - SUPPRESSION
  // ============================================================

  static Future<bool> deleteUser(
    int id,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.user(id)),
        headers: await _headers(),
      );

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // DECONNEXION
  // ============================================================

  static Future<bool> logout() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.logout),
        headers: await _headers(),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}