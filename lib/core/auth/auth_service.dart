import 'dart:convert';

import 'package:attendance/core/network/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  AuthService._();

  // ===========================================================================
  // STORAGE
  // ===========================================================================

  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static const String _organizationKey = 'organization';
  static const String _organizationsKey = 'organizations';
  static const String _rolesKey = 'roles';
  static const String _permissionsKey = 'permissions';
  static const String _homeRouteKey = 'home_route';
  static const String _employeeKey = 'employee';

  static const String _requiresOrganizationSelectionKey =
      'requires_organization_selection';

  static const String _kioskTokenKey = 'kiosk_token';
  static const String _kioskKey = 'kiosk_data';

  static const String _deviceIdKey = 'attendance_device_id';

  // ===========================================================================
  // DEVICE
  // ===========================================================================

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    final existing = prefs.getString(_deviceIdKey);

    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final deviceId = const Uuid().v4();

    await prefs.setString(
      _deviceIdKey,
      deviceId,
    );

    return deviceId;
  }

  // ===========================================================================
  // USER TOKEN
  // ===========================================================================

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  static Future<void> saveToken(String token) async {
    final value = token.trim();

    if (value.isEmpty) {
      throw Exception('Token utilisateur vide.');
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      value,
    );
  }

  // ===========================================================================
  // KIOSK TOKEN
  // ===========================================================================

  static Future<String?> getKioskToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_kioskTokenKey);

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  // ===========================================================================
  // SESSION STATE
  // ===========================================================================

  static Future<bool> isLoggedIn() async {
    return await getToken() != null;
  }

  static Future<bool> isKioskLoggedIn() async {
    return await getKioskToken() != null;
  }

  static Future<bool> requiresOrganizationSelection() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(
          _requiresOrganizationSelectionKey,
        ) ??
        false;
  }

  static Future<void> _setOrganizationSelectionRequired(
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _requiresOrganizationSelectionKey,
      value,
    );
  }

  static Future<bool> isOrganizationSelected() async {
    final organizationId = await getOrganizationId();

    return organizationId != null;
  }

  static Future<bool> isSessionReady() async {
    final loggedIn = await isLoggedIn();

    if (!loggedIn) {
      return false;
    }

    if (await requiresOrganizationSelection()) {
      return false;
    }

    return await isOrganizationSelected();
  }

  // ===========================================================================
  // HEADERS
  // ===========================================================================

  static Future<Map<String, String>> headers({
    bool kiosk = false,
    bool contentType = false,
    bool includeOrganization = true,
  }) async {
    final result = <String, String>{
      'Accept': 'application/json',
    };

    if (contentType) {
      result['Content-Type'] = 'application/json';
    }

    final token = kiosk
        ? await getKioskToken()
        : await getToken();

    if (token != null && token.isNotEmpty) {
      result['Authorization'] = 'Bearer $token';
    }

    if (!kiosk && includeOrganization) {
      final organizationId = await getOrganizationId();

      if (organizationId != null) {
        result['X-Organization-Id'] =
            organizationId.toString();
      }
    }

    return result;
  }

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final loginValue = email.trim();

      if (loginValue.isEmpty || password.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: await headers(
          contentType: true,
          includeOrganization: false,
        ),
        body: jsonEncode({
          'login': loginValue,
          'password': password,
        }),
      );

      final body = _decodeMap(response);

      if (body == null || body['status'] != true) {
        return false;
      }

      final data = _extractDataMap(body);

      if (data == null) {
        return false;
      }

      final rawToken = data['token'];

      if (rawToken == null) {
        return false;
      }

      final token = rawToken.toString().trim();

      if (token.isEmpty) {
        return false;
      }

      await saveLoginData(
        data,
        token,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // SAVE LOGIN DATA
  // ===========================================================================

  static Future<void> saveLoginData(
    Map<String, dynamic> data,
    String token,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await saveToken(token);

    // USER
    final rawUser = data['user'];

    if (rawUser is Map) {
      await saveUser(
        Map<String, dynamic>.from(rawUser),
      );
    }

    // ORGANIZATIONS
    final organizations = _extractOrganizations(
      data['organizations'],
    );

    await prefs.setString(
      _organizationsKey,
      jsonEncode(organizations),
    );

    // ORGANIZATION SELECTION
    final requiresSelection =
        data['requires_organization_selection'] == true;

    if (requiresSelection) {
      await _setOrganizationSelectionRequired(true);

      await _clearOrganizationContext();

      return;
    }

    // ORGANIZATION ACTIVE
    final rawOrganization = data['organization'];

    if (rawOrganization is Map) {
      await saveActiveOrganization(
        Map<String, dynamic>.from(rawOrganization),
      );
    } else if (organizations.length == 1) {
      await saveActiveOrganization(
        organizations.first,
      );
    } else if (organizations.length > 1) {
      await _setOrganizationSelectionRequired(true);

      await _clearOrganizationContext();

      return;
    } else {
      await _setOrganizationSelectionRequired(false);
      await prefs.remove(_organizationKey);
    }

    // ROLES
    final roles = _extractRoleNames(
      data['roles'],
    );

    await saveRoles(roles);

    // PERMISSIONS
    final permissions = _extractPermissionNames(
      data['permissions'],
    );

    await savePermissions(permissions);

    // HOME
    await saveHomeRoute(
      homeRouteFromRoles(roles),
    );

    // EMPLOYEE
    final rawEmployee = data['employee'];

    if (rawEmployee is Map) {
      await saveEmployee(
        Map<String, dynamic>.from(rawEmployee),
      );
    } else {
      await prefs.remove(_employeeKey);
    }
  }

  // ===========================================================================
  // HOME ROUTE
  // ===========================================================================

  static String homeRouteFromRoles(
    List<String> roles,
  ) {
    final normalized = roles
        .map(
          (role) => role.trim().toLowerCase(),
        )
        .toSet();

    if (normalized.contains('super_admin') ||
        normalized.contains('organization_admin') ||
        normalized.contains('admin_rh')) {
      return '/admin';
    }

    if (normalized.contains('manager')) {
      return '/manager';
    }

    if (normalized.contains('employee')) {
      return '/employees';
    }

    return '/dashboard';
  }

  static Future<void> saveHomeRoute(
    String route,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _homeRouteKey,
      route,
    );
  }

  static Future<String> getHomeRoute() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(
          _homeRouteKey,
        ) ??
        '/dashboard';
  }

  // ===========================================================================
  // CURRENT USER / DASHBOARD
  // ===========================================================================

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    if (await requiresOrganizationSelection()) {
      return null;
    }

    final organizationId = await getOrganizationId();

    if (organizationId == null) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.dashboard),
        headers: await headers(),
      );

      if (response.statusCode == 401) {
        await clearSession();
        return null;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return null;
      }

      final body = _decodeMap(response);

      if (body == null || body['status'] != true) {
        return null;
      }

      final data = _extractDataMap(body);

      if (data == null) {
        return null;
      }

      await _saveContextFromResponse(data);

      return data;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> refreshCurrentUser() async {
    final data = await getCurrentUser();

    if (data == null) {
      return null;
    }

    final rawUser = data['user'];

    if (rawUser is Map) {
      final user = Map<String, dynamic>.from(rawUser);

      await saveUser(user);

      return user;
    }

    return null;
  }

  // ===========================================================================
  // SAVE CONTEXT FROM API
  // ===========================================================================

  static Future<void> _saveContextFromResponse(
    Map<String, dynamic> data,
  ) async {
    final rawOrganization = data['organization'];

    if (rawOrganization is Map) {
      await saveActiveOrganization(
        Map<String, dynamic>.from(rawOrganization),
      );
    }

    final roles = _extractRoleNames(
      data['roles'],
    );

    await saveRoles(roles);

    final permissions = _extractPermissionNames(
      data['permissions'],
    );

    await savePermissions(permissions);

    await saveHomeRoute(
      homeRouteFromRoles(roles),
    );

    final rawUser = data['user'];

    if (rawUser is Map) {
      await saveUser(
        Map<String, dynamic>.from(rawUser),
      );
    }

    final rawEmployee = data['employee'];

    if (rawEmployee is Map) {
      await saveEmployee(
        Map<String, dynamic>.from(rawEmployee),
      );
    }

    await _setOrganizationSelectionRequired(false);
  }

  // ===========================================================================
  // USER
  // ===========================================================================

  static Future<void> saveUser(
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _userKey,
      jsonEncode(user),
    );
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(_userKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  // ===========================================================================
  // ORGANIZATION
  // ===========================================================================

  static Future<void> saveActiveOrganization(
    Map<String, dynamic> organization,
  ) async {
    final id = _toInt(organization['id']);

    if (id == null || id <= 0) {
      throw Exception(
        'Organisation invalide : identifiant manquant.',
      );
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _organizationKey,
      jsonEncode(organization),
    );

    await _setOrganizationSelectionRequired(false);
  }

  static Future<Map<String, dynamic>?> getOrganization() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(_organizationKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  static Future<Map<String, dynamic>?> getSavedOrganization() {
    return getOrganization();
  }

  static Future<int?> getOrganizationId() async {
    final organization = await getOrganization();

    if (organization == null) {
      return null;
    }

    return _toInt(
      organization['id'],
    );
  }

  // ===========================================================================
  // ORGANIZATIONS
  // ===========================================================================

  static Future<List<Map<String, dynamic>>>
      getSavedOrganizations() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(
      _organizationsKey,
    );

    if (value == null || value.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .where(
            (item) => _toInt(item['id']) != null,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // SWITCH ORGANIZATION
  // ===========================================================================

  static Future<Map<String, dynamic>?> switchOrganization(
    int organizationId,
  ) async {
    if (organizationId <= 0) {
      return null;
    }

    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(
          ApiConfig.switchOrganization,
        ),
        headers: await headers(
          contentType: true,
          includeOrganization: false,
        ),
        body: jsonEncode({
          'organization_id': organizationId,
        }),
      );

      if (response.statusCode == 401) {
        await clearSession();
        return null;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return null;
      }

      final body = _decodeMap(response);

      if (body == null || body['status'] != true) {
        return null;
      }

      final data = _extractDataMap(body);

      if (data == null) {
        return null;
      }

      // Nouveau token éventuel
      final rawToken = data['token'];

      if (rawToken != null &&
          rawToken.toString().trim().isNotEmpty) {
        await saveToken(
          rawToken.toString().trim(),
        );
      }

      // On supprime l'ancien contexte organisationnel
      await _clearOrganizationContext();

      // ORGANIZATION
      final rawOrganization =
          data['organization'];

      if (rawOrganization is Map) {
        await saveActiveOrganization(
          Map<String, dynamic>.from(
            rawOrganization,
          ),
        );
      } else {
        await saveActiveOrganization({
          'id': organizationId,
        });
      }

      // ROLES
      final roles = _extractRoleNames(
        data['roles'],
      );

      await saveRoles(roles);

      // PERMISSIONS
      final permissions =
          _extractPermissionNames(
        data['permissions'],
      );

      await savePermissions(
        permissions,
      );

      // HOME
      await saveHomeRoute(
        homeRouteFromRoles(roles),
      );

      // USER
      final rawUser = data['user'];

      if (rawUser is Map) {
        await saveUser(
          Map<String, dynamic>.from(rawUser),
        );
      }

      // EMPLOYEE
      final rawEmployee = data['employee'];

      if (rawEmployee is Map) {
        await saveEmployee(
          Map<String, dynamic>.from(rawEmployee),
        );
      }

      await _setOrganizationSelectionRequired(
        false,
      );

      return data;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // ROLES
  // ===========================================================================

  static Future<void> saveRoles(
    List<String> roles,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final normalized = roles
        .map(
          (role) => role.trim(),
        )
        .where(
          (role) => role.isNotEmpty,
        )
        .toSet()
        .toList();

    await prefs.setString(
      _rolesKey,
      jsonEncode(normalized),
    );
  }

  static Future<List<String>> getSavedRoles() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(_rolesKey);

    if (value == null || value.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map(
            (role) => role.toString().trim(),
          )
          .where(
            (role) => role.isNotEmpty,
          )
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // PERMISSIONS
  // ===========================================================================

  static Future<void> savePermissions(
    List<String> permissions,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final normalized = permissions
        .map(
          (permission) => permission.trim(),
        )
        .where(
          (permission) => permission.isNotEmpty,
        )
        .toSet()
        .toList();

    await prefs.setString(
      _permissionsKey,
      jsonEncode(normalized),
    );
  }

  static Future<List<String>>
      getSavedPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(
      _permissionsKey,
    );

    if (value == null || value.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map(
            (permission) =>
                permission.toString().trim(),
          )
          .where(
            (permission) =>
                permission.isNotEmpty,
          )
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // ROLE CHECKS
  // ===========================================================================

  static Future<bool> hasRole(String role) async {
    final roles = await getSavedRoles();

    return roles.contains(
      role.trim(),
    );
  }

  static Future<bool> hasAnyRole(
    List<String> requiredRoles,
  ) async {
    final roles = await getSavedRoles();

    return requiredRoles.any(
      (role) => roles.contains(
        role.trim(),
      ),
    );
  }

  static Future<bool> hasAllRoles(
    List<String> requiredRoles,
  ) async {
    final roles = await getSavedRoles();

    return requiredRoles.every(
      (role) => roles.contains(
        role.trim(),
      ),
    );
  }

  static Future<bool> isSuperAdmin() =>
      hasRole('super_admin');

  static Future<bool> isOrganizationAdmin() =>
      hasRole('organization_admin');

  static Future<bool> isAdminRh() =>
      hasRole('admin_rh');

  static Future<bool> isManager() =>
      hasRole('manager');

  static Future<bool> isEmployee() =>
      hasRole('employee');

  static Future<bool> isKioskRole() =>
      hasRole('kiosk');

  static Future<bool> isAdmin() =>
      hasAnyRole([
        'super_admin',
        'organization_admin',
        'admin_rh',
      ]);

  // ===========================================================================
  // PERMISSION CHECKS
  // ===========================================================================

  static Future<bool> hasPermission(
    String permission,
  ) async {
    final permissions =
        await getSavedPermissions();

    return permissions.contains(
      permission.trim(),
    );
  }

  static Future<bool> hasAnyPermission(
    List<String> requiredPermissions,
  ) async {
    final permissions =
        await getSavedPermissions();

    return requiredPermissions.any(
      (permission) =>
          permissions.contains(
        permission.trim(),
      ),
    );
  }

  static Future<bool> hasAllPermissions(
    List<String> requiredPermissions,
  ) async {
    final permissions =
        await getSavedPermissions();

    return requiredPermissions.every(
      (permission) =>
          permissions.contains(
        permission.trim(),
      ),
    );
  }

  // ===========================================================================
  // EMPLOYEE
  // ===========================================================================

  static Future<void> saveEmployee(
    Map<String, dynamic> employee,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _employeeKey,
      jsonEncode(employee),
    );
  }

  static Future<Map<String, dynamic>?>
      getSavedEmployee() async {
    final prefs =
        await SharedPreferences.getInstance();

    final value =
        prefs.getString(_employeeKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }
    } catch (_) {}

    return null;
  }

  // ===========================================================================
  // KIOSK
  // ===========================================================================

  static Future<void> saveKioskToken(
    String token,
  ) async {
    final value = token.trim();

    if (value.isEmpty) {
      throw Exception(
        'Token kiosk vide.',
      );
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _kioskTokenKey,
      value,
    );
  }

  static Future<void> saveKioskData(
    Map<String, dynamic> kiosk,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _kioskKey,
      jsonEncode(kiosk),
    );
  }

  static Future<Map<String, dynamic>?>
      getKioskData() async {
    final prefs =
        await SharedPreferences.getInstance();

    final value =
        prefs.getString(_kioskKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }
    } catch (_) {}

    return null;
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  static Future<void> logout() async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse(ApiConfig.logout),
          headers: await headers(),
        );
      } catch (_) {}
    }

    await clearSession();
  }

  // ===========================================================================
  // CLEAR ORGANIZATION CONTEXT
  // ===========================================================================

  static Future<void> _clearOrganizationContext() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_organizationKey);
    await prefs.remove(_rolesKey);
    await prefs.remove(_permissionsKey);
    await prefs.remove(_homeRouteKey);
    await prefs.remove(_employeeKey);
  }

  // ===========================================================================
  // CLEAR USER SESSION
  // ===========================================================================

  static Future<void> clearSession() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_organizationKey);
    await prefs.remove(_organizationsKey);
    await prefs.remove(_rolesKey);
    await prefs.remove(_permissionsKey);
    await prefs.remove(_homeRouteKey);
    await prefs.remove(_employeeKey);
    await prefs.remove(
      _requiresOrganizationSelectionKey,
    );
  }

  // ===========================================================================
  // CLEAR KIOSK SESSION
  // ===========================================================================

  static Future<void> clearKioskSession() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_kioskTokenKey);
    await prefs.remove(_kioskKey);
  }

  static Future<void> logoutKiosk() async {
    await clearKioskSession();
  }

  // ===========================================================================
  // CLEAR ALL
  // ===========================================================================

  static Future<void> clearAllSessions() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_organizationKey);
    await prefs.remove(_organizationsKey);
    await prefs.remove(_rolesKey);
    await prefs.remove(_permissionsKey);
    await prefs.remove(_homeRouteKey);
    await prefs.remove(_employeeKey);

    await prefs.remove(
      _requiresOrganizationSelectionKey,
    );

    await prefs.remove(_kioskTokenKey);
    await prefs.remove(_kioskKey);
  }

  // ===========================================================================
  // RESPONSE HELPERS
  // ===========================================================================

  static Map<String, dynamic>? _decodeMap(
    http.Response response,
  ) {
    if (response.body.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }
    } catch (_) {}

    return null;
  }

  static Map<String, dynamic>? _extractDataMap(
    Map<String, dynamic> body,
  ) {
    final rawData = body['data'];

    if (rawData is Map) {
      return Map<String, dynamic>.from(
        rawData,
      );
    }

    return body;
  }

  // ===========================================================================
  // EXTRACTION
  // ===========================================================================

  static List<Map<String, dynamic>>
      _extractOrganizations(
    dynamic raw,
  ) {
    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .where(
          (item) =>
              _toInt(item['id']) != null,
        )
        .toList();
  }

  static List<String> _extractRoleNames(
    dynamic raw,
  ) {
    if (raw is! List) {
      return [];
    }

    final result = <String>[];

    for (final role in raw) {
      if (role is String) {
        final value = role.trim();

        if (value.isNotEmpty) {
          result.add(value);
        }

        continue;
      }

      if (role is Map) {
        final map =
            Map<String, dynamic>.from(role);

        final name =
            map['name'] ??
            map['role'] ??
            map['slug'];

        if (name != null) {
          final value =
              name.toString().trim();

          if (value.isNotEmpty) {
            result.add(value);
          }
        }
      }
    }

    return result.toSet().toList();
  }

  static List<String> _extractPermissionNames(
    dynamic raw,
  ) {
    if (raw is! List) {
      return [];
    }

    final result = <String>[];

    for (final permission in raw) {
      if (permission is String) {
        final value = permission.trim();

        if (value.isNotEmpty) {
          result.add(value);
        }

        continue;
      }

      if (permission is Map) {
        final map =
            Map<String, dynamic>.from(
          permission,
        );

        final name =
            map['name'] ??
            map['permission'] ??
            map['slug'];

        if (name != null) {
          final value =
              name.toString().trim();

          if (value.isNotEmpty) {
            result.add(value);
          }
        }
      }
    }

    return result.toSet().toList();
  }

  // ===========================================================================
  // INT
  // ===========================================================================

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }
}