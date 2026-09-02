import 'dart:convert';

import 'package:attendance/core/network/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  AuthService._();

  // ============================================================
  // STORAGE KEYS
  // ============================================================

  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static const String _rolesKey = 'roles';
  static const String _deviceIdKey = 'attendance_device_id';


// =======================================================
// Info device
// =====================================================

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    // On récupère l'ID déjà généré
    final existingId = prefs.getString(_deviceIdKey);

    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    // Génération d'un nouvel ID
    final deviceId = const Uuid().v4();

    await prefs.setString(
      _deviceIdKey,
      deviceId,
    );

    return deviceId;
  }
  // ============================================================
  // TOKEN
  // ============================================================

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) {
      return null;
    }

    return token;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers({
    bool contentType = false,
  }) async {
    final token = await getToken();

    return {
      'Accept': 'application/json',
      if (contentType) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // LOGIN
  //
  // POST /api/v1/auth/login
  // ============================================================

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: await _headers(contentType: true),
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      // ----------------------------------------------------------
      // LOGIN REFUSÉ
      // ----------------------------------------------------------

      if (response.statusCode != 200) {
        return false;
      }

      if (response.body.isEmpty) {
        return false;
      }

      // ----------------------------------------------------------
      // JSON
      // ----------------------------------------------------------

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return false;
      }

      final body = Map<String, dynamic>.from(decoded);

      // ----------------------------------------------------------
      // DATA
      // ----------------------------------------------------------

      final rawData = body['data'];

      if (rawData is! Map) {
        return false;
      }

      final data = Map<String, dynamic>.from(rawData);

      // ----------------------------------------------------------
      // TOKEN
      // ----------------------------------------------------------

      final rawToken = data['token'];

      if (rawToken == null) {
        return false;
      }

      final token = rawToken.toString().trim();

      if (token.isEmpty) {
        return false;
      }

      // ----------------------------------------------------------
      // SAUVEGARDE
      // ----------------------------------------------------------

      await saveLoginData(
        data,
        token,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // CURRENT USER
  //
  // GET /api/v1/auth/dashboard
  // ============================================================

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.dashboard),
        headers: await _headers(),
      );

      // ----------------------------------------------------------
      // TOKEN INVALIDE / NON AUTORISÉ
      // ----------------------------------------------------------

      if (response.statusCode == 401) {
        await clearSession();
        return null;
      }

      if (response.statusCode != 200) {
        return null;
      }

      if (response.body.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return null;
      }

      final body = Map<String, dynamic>.from(decoded);

      // ----------------------------------------------------------
      // DATA
      // ----------------------------------------------------------

      dynamic data = body['data'];

      if (data is Map) {
        data = Map<String, dynamic>.from(data);
      } else {
        data = body;
      }

      // ----------------------------------------------------------
      // USER
      // ----------------------------------------------------------

      dynamic user = data['user'];

      if (user is Map) {
        return Map<String, dynamic>.from(user);
      }

      // Certains endpoints peuvent directement retourner
      // l'utilisateur dans "data".

      return Map<String, dynamic>.from(data);

    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // REFRESH CURRENT USER
  //
  // Utilise /auth/me et met à jour le cache local.
  // ============================================================

  static Future<Map<String, dynamic>?> refreshCurrentUser() async {
    final user = await getCurrentUser();

    if (user == null) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _userKey,
      jsonEncode(user),
    );

    return user;
  }

  // ============================================================
  // SAVE LOGIN DATA
  // ============================================================

  static Future<void> saveLoginData(
    Map<String, dynamic> data,
    String token,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // ----------------------------------------------------------
    // TOKEN
    // ----------------------------------------------------------

    await prefs.setString(
      _tokenKey,
      token,
    );

    // ----------------------------------------------------------
    // USER
    // ----------------------------------------------------------

    final rawUser = data['user'];

    if (rawUser is Map) {
      await prefs.setString(
        _userKey,
        jsonEncode(
          Map<String, dynamic>.from(rawUser),
        ),
      );
    }

    // ----------------------------------------------------------
    // ROLES
    // ----------------------------------------------------------

    final roles = _extractRoleNames(data['roles']);

    await prefs.setString(
      _rolesKey,
      jsonEncode(roles),
    );
  }



  static List<String> _extractRoleNames(
    dynamic rawRoles,
  ) {
    if (rawRoles is! List) {
      return [];
    }

    final roles = <String>[];

    for (final role in rawRoles) {
      
      if (role is String) {
        final value = role.trim();

        if (value.isNotEmpty) {
          roles.add(value);
        }

        continue;
      }
 
      if (role is Map) {
        final map = Map<String, dynamic>.from(role);

        final dynamic name =
            map['name'] ??
            map['role'] ??
            map['slug'];

        if (name is String) {
          final value = name.trim();

          if (value.isNotEmpty) {
            roles.add(value);
          }
        }
      }
    }

    return roles.toSet().toList();
  }

  // ============================================================
  // SAVED USER
  // ============================================================

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();

    final userJson = prefs.getString(_userKey);

    if (userJson == null || userJson.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(userJson);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // SAVED ROLES
  // ============================================================

  static Future<List<String>> getSavedRoles() async {
    final prefs = await SharedPreferences.getInstance();

    final rolesJson = prefs.getString(_rolesKey);

    if (rolesJson == null || rolesJson.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rolesJson);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<String>()
          .map((role) => role.trim())
          .where((role) => role.isNotEmpty)
          .toList();
    } catch (e) {
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
  // CHECK MULTIPLE ROLES
  // ============================================================

  static Future<bool> hasAnyRole(
    List<String> requiredRoles,
  ) async {
    final roles = await getSavedRoles();

    return requiredRoles.any(
      roles.contains,
    );
  }

  // ============================================================
  // SUPER ADMIN
  // ============================================================

  static Future<bool> isSuperAdmin() async {
    return hasRole('super_admin');
  }

  // ============================================================
  // ADMIN RH
  // ============================================================

  static Future<bool> isAdminRh() async {
    return hasRole('admin_rh');
  }

  // ============================================================
  // MANAGER
  // ============================================================

  static Future<bool> isManager() async {
    return hasRole('manager');
  }

  // ============================================================
  // EMPLOYEE
  // ============================================================

  static Future<bool> isEmployee() async {
    return hasRole('employee');
  }

  // ============================================================
  // KIOSK
  // ============================================================

  static Future<bool> isKiosk() async {
    return hasRole('kiosk');
  }

  // ============================================================
  // ADMINISTRATEUR
  // ============================================================

  static Future<bool> isAdmin() async {
    return hasAnyRole([
      'super_admin',
      'admin_rh',
    ]);
  }

  // ============================================================
  // LOGOUT
  //
  // POST /api/v1/auth/logout
  // ============================================================

  static Future<void> logout() async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(ApiConfig.logout),
          headers: await _headers(),
        );

        // Dans tous les cas, on nettoie la session locale.
        if (response.statusCode == 401 ||
            response.statusCode == 200 ||
            response.statusCode == 204) {
          // Rien à faire ici.
        }
      } catch (_) {
        // Même si le serveur est inaccessible,
        // on supprime la session locale.
      }
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