import 'dart:convert';

import 'package:attendance/core/network/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();

  // ============================================================
  // STORAGE KEYS
  // ============================================================

  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static const String _rolesKey = 'roles';

  // ============================================================
  // TOKEN
  // ============================================================

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();

    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        return false;
      }

      if (response.body.isEmpty) {
        return false;
      }

      final body = jsonDecode(response.body);

      if (body is! Map) {
        return false;
      }

      final data = body['data'];

      if (data is! Map) {
        return false;
      }

      final token = data['token'];

      if (token == null ||
          token.toString().isEmpty) {
        return false;
      }

      await saveLoginData(
        Map<String, dynamic>.from(data),
        token.toString(),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.me),
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return null;
      }

      if (response.body.isEmpty) {
        return null;
      }

      final body = jsonDecode(response.body);

      if (body is! Map) {
        return null;
      }

      final data = body['data'] ?? body;

      if (data is! Map) {
        return null;
      }

      final user = data['user'] ?? data;

      if (user is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(user);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // SAVE LOGIN DATA
  // ============================================================

  static Future<void> saveLoginData(
    Map<String, dynamic> data,
    String token,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      token,
    );

    final user = data['user'];

    if (user is Map) {
      await prefs.setString(
        _userKey,
        jsonEncode(user),
      );
    }

    final roles = data['roles'];

    if (roles is List) {
      await prefs.setString(
        _rolesKey,
        jsonEncode(roles),
      );
    }
  }

  // ============================================================
  // SAVED USER
  // ============================================================

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();

    final userJson = prefs.getString(_userKey);

    if (userJson == null ||
        userJson.isEmpty) {
      return null;
    }

    try {
      final data = jsonDecode(userJson);

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // SAVED ROLES
  // ============================================================

  static Future<List<String>> getSavedRoles() async {
    final prefs = await SharedPreferences.getInstance();

    final rolesJson = prefs.getString(_rolesKey);

    if (rolesJson == null ||
        rolesJson.isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(rolesJson);

      if (data is! List) {
        return [];
      }

      return data
          .map((role) => role.toString())
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // CHECK ROLE
  // ============================================================

  static Future<bool> hasRole(
    String role,
  ) async {
    final roles = await getSavedRoles();

    return roles.contains(role);
  }

  // ============================================================
  // ADMIN
  // ============================================================

  static Future<bool> isSuperAdmin() async {
    return hasRole('super_admin');
  }

  static Future<bool> isAdminRh() async {
    return hasRole('admin_rh');
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    final token = await getToken();

    if (token != null &&
        token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse(ApiConfig.logout),
          headers: await _headers(),
        );
      } catch (_) {}
    }

    await clearSession();
  }

  // ============================================================
  // CLEAR SESSION
  // ============================================================

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_rolesKey);
  }
}