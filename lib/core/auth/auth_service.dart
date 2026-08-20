import 'dart:convert';

import 'package:attendance/core/network/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.adminMe),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['data'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveLoginData(
    Map<String, dynamic> data,
    String token,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);

    if (data['user'] != null) {
      await prefs.setString('user', jsonEncode(data['user']));
    }

    if (data['roles'] != null) {
      await prefs.setString('roles', jsonEncode(data['roles']));
    }
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();

    final userJson = prefs.getString('user');

    if (userJson == null) {
      return null;
    }

    try {
      return jsonDecode(userJson);
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> getSavedRoles() async {
    final prefs = await SharedPreferences.getInstance();

    final rolesJson = prefs.getString('roles');

    if (rolesJson == null) {
      return [];
    }

    try {
      return List<String>.from(jsonDecode(rolesJson));
    } catch (_) {
      return [];
    }
  }

  static Future<void> logout() async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse(ApiConfig.adminLogout),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('roles');
  }
}
