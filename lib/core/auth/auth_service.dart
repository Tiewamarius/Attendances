 import 'dart:convert';

import 'package:attendance/core/network/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  AuthService._();

  // ==========================================================================
  // STORAGE KEYS
  // ==========================================================================

  static const String _tokenKey = 'token';
  static const String _userKey = 'user';

  /// Organisation actuellement sélectionnée.
  static const String _organizationKey = 'organization';

  /// Toutes les organisations auxquelles l'utilisateur appartient.
  static const String _organizationsKey = 'organizations';

  /// Rôles de l'utilisateur dans l'organisation active.
  static const String _rolesKey = 'roles';

  /// Permissions de l'utilisateur dans l'organisation active.
  static const String _permissionsKey = 'permissions';

  /// Route d'accueil après authentification.
  static const String _homeRouteKey = 'home_route';

  /// Données de l'employé connecté.
  static const String _employeeKey = 'employee';

  // ==========================================================================
  // KIOSK
  // ==========================================================================

  static const String _kioskTokenKey = 'kiosk_token';
  static const String _kioskKey = 'kiosk_data';

  // ==========================================================================
  // DEVICE
  // ==========================================================================

  static const String _deviceIdKey = 'attendance_device_id';

  // ==========================================================================
  // DEVICE ID
  // ==========================================================================

  /// Retourne l'identifiant unique et persistant de l'appareil.
  ///
  /// IMPORTANT :
  /// Le device ID n'est jamais supprimé lors d'un logout.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    final existingId = prefs.getString(_deviceIdKey);

    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final deviceId = const Uuid().v4();

    await prefs.setString(
      _deviceIdKey,
      deviceId,
    );

    return deviceId;
  }

  // ==========================================================================
  // TOKEN UTILISATEUR
  // ==========================================================================

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

  // ==========================================================================
  // HEADERS UTILISATEUR
  // ==========================================================================

  /// Headers utilisés par les requêtes de l'utilisateur.
  ///
  /// [includeOrganization]
  /// true  => ajoute X-Organization-Id
  /// false => ne l'ajoute pas
  ///
  /// Le login ne doit jamais envoyer X-Organization-Id.
  static Future<Map<String, String>> _headers({
    bool contentType = false,
    bool includeOrganization = true,
  }) async {
    final token = await getToken();

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (contentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (includeOrganization) {
      final organizationId = await getOrganizationId();

      if (organizationId != null) {
        headers['X-Organization-Id'] =
            organizationId.toString();
      }
    }

    return headers;
  }

  // ==========================================================================
  // HEADERS KIOSK
  // ==========================================================================

  static Future<Map<String, String>> kioskHeaders({
    bool contentType = false,
  }) async {
    final token = await getKioskToken();

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (contentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // IMPORTANT :
    // Le Kiosk n'envoie pas X-Organization-Id.
    return headers;
  }

  // ==========================================================================
  // LOGIN
  // ==========================================================================

  /// POST /api/v1/auth/login
  ///
  /// Le login :
  /// - authentifie l'utilisateur ;
  /// - retourne le token ;
  /// - retourne toutes les organisations ;
  /// - ne détermine pas encore le rôle.
  ///
  /// Le rôle dépend de l'organisation sélectionnée.
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: await _headers(
          contentType: true,
          includeOrganization: false,
        ),
        body: jsonEncode({
          // IMPORTANT :
          // Laravel attend "login", pas "email".
          'login': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        return false;
      }

      if (response.body.isEmpty) {
        return false;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return false;
      }

      final body = Map<String, dynamic>.from(decoded);

      if (body['status'] != true) {
        return false;
      }

      final rawData = body['data'];

      if (rawData is! Map) {
        return false;
      }

      final data = Map<String, dynamic>.from(rawData);

      // ----------------------------------------------------------------------
      // TOKEN
      // ----------------------------------------------------------------------

      final rawToken = data['token'];

      if (rawToken == null) {
        return false;
      }

      final token = rawToken.toString().trim();

      if (token.isEmpty) {
        return false;
      }

      // ----------------------------------------------------------------------
      // ORGANISATIONS
      // ----------------------------------------------------------------------

      final rawOrganizations = data['organizations'];

      if (rawOrganizations is! List ||
          rawOrganizations.isEmpty) {
        return false;
      }

      // ----------------------------------------------------------------------
      // SAUVEGARDE SESSION
      // ----------------------------------------------------------------------

      await saveLoginData(
        data,
        token,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // SAVE LOGIN DATA
  // ==========================================================================

  static Future<void> saveLoginData(
    Map<String, dynamic> data,
    String token,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // ------------------------------------------------------------------------
    // TOKEN
    // ------------------------------------------------------------------------

    await prefs.setString(
      _tokenKey,
      token,
    );

    // ------------------------------------------------------------------------
    // USER
    // ------------------------------------------------------------------------

    final rawUser = data['user'];

    if (rawUser is Map) {
      await prefs.setString(
        _userKey,
        jsonEncode(
          Map<String, dynamic>.from(rawUser),
        ),
      );
    }

    // ------------------------------------------------------------------------
    // ORGANISATIONS
    // ------------------------------------------------------------------------

    final rawOrganizations = data['organizations'];

    if (rawOrganizations is List) {
      final organizations = rawOrganizations
          .whereType<Map>()
          .map(
            (organization) =>
                Map<String, dynamic>.from(organization),
          )
          .toList();

      await prefs.setString(
        _organizationsKey,
        jsonEncode(organizations),
      );

      // ----------------------------------------------------------------------
      // Première organisation active temporairement
      //
      // Tant qu'on n'a pas encore créé la page de sélection d'organisation,
      // on utilise la première organisation.
      // ----------------------------------------------------------------------

      if (organizations.isNotEmpty) {
        await saveActiveOrganization(
          organizations.first,
        );
      }
    }

    // ------------------------------------------------------------------------
    // ROLES
    // ------------------------------------------------------------------------

    final roles = _extractRoleNames(
      data['roles'],
    );

    await saveRoles(roles);

    // ------------------------------------------------------------------------
    // PERMISSIONS
    // ------------------------------------------------------------------------

    final permissions = _extractPermissionNames(
      data['permissions'],
    );

    await savePermissions(permissions);

    // ------------------------------------------------------------------------
    // EMPLOYEE
    // ------------------------------------------------------------------------

    final rawEmployee = data['employee'];

    if (rawEmployee is Map) {
      await saveEmployee(
        Map<String, dynamic>.from(rawEmployee),
      );
    } else {
      await prefs.remove(_employeeKey);
    }

    // ------------------------------------------------------------------------
    // HOME ROUTE
    // ------------------------------------------------------------------------

    await prefs.setString(
      _homeRouteKey,
      'admin',
    );
  }

  // ==========================================================================
  // CURRENT USER / DASHBOARD
  // ==========================================================================

  /// GET /api/v1/auth/dashboard
  ///
  /// Retourne :
  ///
  /// {
  ///   user,
  ///   organization,
  ///   roles,
  ///   permissions,
  ///   employee
  /// }
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    // Une organisation active est nécessaire.
    final organizationId = await getOrganizationId();

    if (organizationId == null) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.dashboard),
        headers: await _headers(
          includeOrganization: true,
        ),
      );

      // ----------------------------------------------------------------------
      // TOKEN INVALIDE
      // ----------------------------------------------------------------------

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

      dynamic rawData = body['data'];

      if (rawData is! Map) {
        rawData = body;
      }

      if (rawData is! Map) {
        return null;
      }

      final data = Map<String, dynamic>.from(rawData);

      // ----------------------------------------------------------------------
      // ORGANISATION
      // ----------------------------------------------------------------------

      final rawOrganization = data['organization'];

      if (rawOrganization is Map) {
        await saveActiveOrganization(
          Map<String, dynamic>.from(
            rawOrganization,
          ),
        );
      }

      // ----------------------------------------------------------------------
      // ROLES
      // ----------------------------------------------------------------------

      final roles = _extractRoleNames(
        data['roles'],
      );

      await saveRoles(roles);

      // ----------------------------------------------------------------------
      // PERMISSIONS
      // ----------------------------------------------------------------------

      final permissions = _extractPermissionNames(
        data['permissions'],
      );

      await savePermissions(permissions);

      // ----------------------------------------------------------------------
      // USER
      // ----------------------------------------------------------------------

      final rawUser = data['user'];

      if (rawUser is Map) {
        final savedUser =
            Map<String, dynamic>.from(rawUser);

        await saveUser(savedUser);
      }

      // ----------------------------------------------------------------------
      // EMPLOYEE
      // ----------------------------------------------------------------------

      final rawEmployee = data['employee'];

      if (rawEmployee is Map) {
        await saveEmployee(
          Map<String, dynamic>.from(rawEmployee),
        );
      }

      return data;
    } catch (e) {
      return null;
    }
  }

  // ==========================================================================
  // REFRESH CURRENT USER
  // ==========================================================================

  static Future<Map<String, dynamic>?> refreshCurrentUser() async {
    final data = await getCurrentUser();

    if (data == null) {
      return null;
    }

    final rawUser = data['user'];

    if (rawUser is Map) {
      final user =
          Map<String, dynamic>.from(rawUser);

      await saveUser(user);

      return user;
    }

    return null;
  }

  // ==========================================================================
  // USER STORAGE
  // ==========================================================================

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

    final userJson = prefs.getString(
      _userKey,
    );

    if (userJson == null || userJson.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(userJson);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // ACTIVE ORGANIZATION
  // ==========================================================================

  static Future<void> saveActiveOrganization(
    Map<String, dynamic> organization,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _organizationKey,
      jsonEncode(organization),
    );
  }

  static Future<Map<String, dynamic>?>
      getSavedOrganization() async {
    return getOrganization();
  }

  static Future<Map<String, dynamic>?>
      getOrganization() async {
    final prefs =
        await SharedPreferences.getInstance();

    final organizationJson =
        prefs.getString(_organizationKey);

    if (organizationJson == null ||
        organizationJson.isEmpty) {
      return null;
    }

    try {
      final decoded =
          jsonDecode(organizationJson);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<int?> getOrganizationId() async {
    final organization =
        await getOrganization();

    if (organization == null) {
      return null;
    }

    final value = organization['id'];

    if (value is int) {
      return value;
    }

    if (value != null) {
      return int.tryParse(
        value.toString(),
      );
    }

    return null;
  }

  // ==========================================================================
  // ALL ORGANIZATIONS
  // ==========================================================================

  static Future<List<Map<String, dynamic>>>
      getSavedOrganizations() async {
    final prefs =
        await SharedPreferences.getInstance();

    final organizationsJson =
        prefs.getString(
      _organizationsKey,
    );

    if (organizationsJson == null ||
        organizationsJson.isEmpty) {
      return [];
    }

    try {
      final decoded =
          jsonDecode(organizationsJson);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (organization) =>
                Map<String, dynamic>.from(
              organization,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ==========================================================================
  // SWITCH ORGANIZATION
  // ==========================================================================

  /// POST /api/v1/auth/organization/switch
  ///
  /// Retourne les données retournées par Laravel.
  ///
  /// Exemple :
  ///
  /// {
  ///   organization: {...},
  ///   roles: [...],
  ///   permissions: [...]
  /// }
  static Future<Map<String, dynamic>?>
      switchOrganization(
    int organizationId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          ApiConfig.switchOrganization,
        ),
        headers: await _headers(
          contentType: true,
          // Le backend vérifie que l'utilisateur possède
          // l'organisation demandée.
          includeOrganization: true,
        ),
        body: jsonEncode({
          'organization_id': organizationId,
        }),
      );

      // ----------------------------------------------------------------------
      // TOKEN INVALIDE
      // ----------------------------------------------------------------------

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

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        return null;
      }

      final body =
          Map<String, dynamic>.from(decoded);

      if (body['status'] != true) {
        return null;
      }

      // ----------------------------------------------------------------------
      // DATA
      // ----------------------------------------------------------------------

      dynamic rawData = body['data'];

      if (rawData is! Map) {
        rawData = body;
      }

      if (rawData is! Map) {
        return null;
      }

      final data =
          Map<String, dynamic>.from(rawData);

      // ----------------------------------------------------------------------
      // ORGANISATION ACTIVE
      // ----------------------------------------------------------------------

      final rawOrganization =
          data['organization'];

      if (rawOrganization is Map) {
        await saveActiveOrganization(
          Map<String, dynamic>.from(
            rawOrganization,
          ),
        );
      } else {
        // Sécurité minimale.
        await saveActiveOrganization({
          'id': organizationId,
        });
      }

      // ----------------------------------------------------------------------
      // ROLES
      // ----------------------------------------------------------------------

      final roles =
          _extractRoleNames(
        data['roles'],
      );

      await saveRoles(roles);

      // ----------------------------------------------------------------------
      // PERMISSIONS
      // ----------------------------------------------------------------------

      final permissions =
          _extractPermissionNames(
        data['permissions'],
      );

      await savePermissions(
        permissions,
      );

      // ----------------------------------------------------------------------
      // USER
      // ----------------------------------------------------------------------

      final rawUser = data['user'];

      if (rawUser is Map) {
        await saveUser(
          Map<String, dynamic>.from(
            rawUser,
          ),
        );
      }

      return data;
    } catch (e) {
      return null;
    }
  }

  // ==========================================================================
  // ROLES
  // ==========================================================================

  static Future<void> saveRoles(
    List<String> roles,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _rolesKey,
      jsonEncode(
        roles.toSet().toList(),
      ),
    );
  }

  static Future<List<String>> getSavedRoles() async {
    final prefs =
        await SharedPreferences.getInstance();

    final rolesJson =
        prefs.getString(_rolesKey);

    if (rolesJson == null ||
        rolesJson.isEmpty) {
      return [];
    }

    try {
      final decoded =
          jsonDecode(rolesJson);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<String>()
          .map(
            (role) => role.trim(),
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

  // ==========================================================================
  // PERMISSIONS
  // ==========================================================================

  static Future<void> savePermissions(
    List<String> permissions,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _permissionsKey,
      jsonEncode(
        permissions.toSet().toList(),
      ),
    );
  }

  static Future<List<String>>
      getSavedPermissions() async {
    final prefs =
        await SharedPreferences.getInstance();

    final permissionsJson =
        prefs.getString(
      _permissionsKey,
    );

    if (permissionsJson == null ||
        permissionsJson.isEmpty) {
      return [];
    }

    try {
      final decoded =
          jsonDecode(
        permissionsJson,
      );

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<String>()
          .map(
            (permission) => permission.trim(),
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

  // ==========================================================================
  // EXTRACT ROLES
  // ==========================================================================

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
        final map =
            Map<String, dynamic>.from(
          role,
        );

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

  // ==========================================================================
  // EXTRACT PERMISSIONS
  // ==========================================================================

  static List<String> _extractPermissionNames(
    dynamic rawPermissions,
  ) {
    if (rawPermissions is! List) {
      return [];
    }

    final permissions = <String>[];

    for (final permission in rawPermissions) {
      if (permission is String) {
        final value = permission.trim();

        if (value.isNotEmpty) {
          permissions.add(value);
        }

        continue;
      }

      if (permission is Map) {
        final map =
            Map<String, dynamic>.from(
          permission,
        );

        final dynamic name =
            map['name'] ??
                map['permission'] ??
                map['slug'];

        if (name is String) {
          final value = name.trim();

          if (value.isNotEmpty) {
            permissions.add(value);
          }
        }
      }
    }

    return permissions.toSet().toList();
  }

  // ==========================================================================
  // CHECK ROLE
  // ==========================================================================

  static Future<bool> hasRole(
    String role,
  ) async {
    final roles =
        await getSavedRoles();

    return roles.contains(role);
  }

  static Future<bool> hasAnyRole(
    List<String> requiredRoles,
  ) async {
    final roles =
        await getSavedRoles();

    return requiredRoles.any(
      roles.contains,
    );
  }

  static Future<bool> isSuperAdmin() async {
    return hasRole('super_admin');
  }

  static Future<bool>
      isOrganizationAdmin() async {
    return hasRole(
      'organization_admin',
    );
  }

  static Future<bool> isAdminRh() async {
    return hasRole('admin_rh');
  }

  static Future<bool> isManager() async {
    return hasRole('manager');
  }

  static Future<bool> isEmployee() async {
    return hasRole('employee');
  }

  static Future<bool> isAdmin() async {
    return hasAnyRole([
      'super_admin',
      'organization_admin',
      'admin_rh',
    ]);
  }

  // ==========================================================================
  // CHECK PERMISSION
  // ==========================================================================

  static Future<bool> hasPermission(
    String permission,
  ) async {
    final permissions =
        await getSavedPermissions();

    return permissions.contains(
      permission,
    );
  }

  static Future<bool> hasAnyPermission(
    List<String> requiredPermissions,
  ) async {
    final permissions =
        await getSavedPermissions();

    return requiredPermissions.any(
      permissions.contains,
    );
  }

  static Future<bool> hasAllPermissions(
    List<String> requiredPermissions,
  ) async {
    final permissions =
        await getSavedPermissions();

    return requiredPermissions.every(
      permissions.contains,
    );
  }

  // ==========================================================================
  // EMPLOYEE
  // ==========================================================================

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

    final employeeJson =
        prefs.getString(
      _employeeKey,
    );

    if (employeeJson == null ||
        employeeJson.isEmpty) {
      return null;
    }

    try {
      final decoded =
          jsonDecode(employeeJson);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // HOME ROUTE
  // ==========================================================================

  static Future<void> saveHomeRoute(
    String route,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _homeRouteKey,
      route,
    );
  }

  static Future<String> getHomeRoute() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
          _homeRouteKey,
        ) ??
        '/admin';
  }

  // ==========================================================================
  // KIOSK TOKEN
  // ==========================================================================

  static Future<String?> getKioskToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString(
      _kioskTokenKey,
    );

    if (token == null || token.isEmpty) {
      return null;
    }

    return token;
  }

  static Future<bool> isKioskLoggedIn() async {
    final token =
        await getKioskToken();

    return token != null &&
        token.isNotEmpty;
  }

  static Future<void> saveKioskToken(
    String token,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _kioskTokenKey,
      token,
    );
  }

  // ==========================================================================
  // KIOSK DATA
  // ==========================================================================

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

    final kioskJson =
        prefs.getString(
      _kioskKey,
    );

    if (kioskJson == null ||
        kioskJson.isEmpty) {
      return null;
    }

    try {
      final decoded =
          jsonDecode(kioskJson);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // LOGOUT UTILISATEUR
  // ==========================================================================

  static Future<void> logout() async {
    final token =
        await getToken();

    if (token != null &&
        token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse(
            ApiConfig.logout,
          ),
          headers: await _headers(
            includeOrganization: true,
          ),
        );
      } catch (_) {
        // Même si le serveur est inaccessible,
        // la session locale sera supprimée.
      }
    }

    await clearSession();
  }

  // ==========================================================================
  // CLEAR USER SESSION
  // ==========================================================================

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

    // IMPORTANT :
    // Le device ID reste conservé.
  }

  // ==========================================================================
  // CLEAR KIOSK SESSION
  // ==========================================================================

  static Future<void> clearKioskSession() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _kioskTokenKey,
    );

    await prefs.remove(
      _kioskKey,
    );
  }

  // ==========================================================================
  // LOGOUT KIOSK
  // ==========================================================================

  static Future<void> logoutKiosk() async {
    await clearKioskSession();
  }

  // ==========================================================================
  // CLEAR ALL SESSIONS
  // ==========================================================================

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
      _kioskTokenKey,
    );

    await prefs.remove(
      _kioskKey,
    );

    // Le device ID est volontairement conservé.
  }
}