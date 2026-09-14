import 'dart:convert';

import 'package:attendance/core/network/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ==========================================================================
  // CONTROLLERS
  // ==========================================================================

  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ==========================================================================
  // STATE
  // ==========================================================================

  bool obscurePassword = true;
  bool loading = false;

  // ==========================================================================
  // CONSTANTS
  // ==========================================================================

  static const Color _primaryColor = Color(0xFF0F172A);
  static const Color _backgroundColor = Color(0xFFF8FAFC);

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // LOGIN
  // ==========================================================================

  Future<void> _login() async {
    final login = loginController.text.trim();
    final password = passwordController.text;

    // --------------------------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------------------------

    if (login.isEmpty || password.isEmpty) {
      _showMessage(
        'Veuillez remplir tous les champs.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      // ========================================================================
      // API LOGIN
      // ========================================================================


      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'login': login,
          'password': password,
        }),
      );

      // ========================================================================
      // PARSE RESPONSE
      // ========================================================================

      debugPrint('');
      debugPrint('================ API RESPONSE =================');
      debugPrint('STATUS CODE : ${response.statusCode}');
      debugPrint('BODY : ${response.body}');
      debugPrint('===============================================');

      final body = _parseResponse(response.body);

      // ========================================================================
      // HTTP ERROR
      // ========================================================================

      if (response.statusCode != 200) {
        throw Exception(
          body['message']?.toString() ??
              'Identifiants incorrects.',
        );
      }

      // ========================================================================
      // API STATUS
      // ========================================================================

      if (body['status'] != true) {
        throw Exception(
          body['message']?.toString() ??
              'Connexion refusée.',
        );
      }

      // ========================================================================
      // DATA
      // ========================================================================

      final rawData = body['data'];

      if (rawData is! Map) {
        throw Exception(
          'Réponse serveur invalide : data est absent ou incorrect.',
        );
      }

      final data = Map<String, dynamic>.from(rawData);

      // ========================================================================
      // TOKEN
      // ========================================================================

      final rawToken = data['token'];

      if (rawToken == null ||
          rawToken.toString().trim().isEmpty) {
        throw Exception(
          'Token d’authentification manquant.',
        );
      }

      final token = rawToken.toString().trim();

      debugPrint('TOKEN PRESENT : true');

      // ========================================================================
      // USER
      // ========================================================================

      final rawUser = data['user'];

      if (rawUser is! Map) {
        throw Exception(
          'Utilisateur absent de la réponse.',
        );
      }

      final user = Map<String, dynamic>.from(rawUser);

      // ========================================================================
      // ORGANIZATIONS
      // ========================================================================

      final organizations = _extractOrganizations(
        data['organizations'],
      );

      if (organizations.isEmpty) {
        throw Exception(
          'Aucune organisation active associée à cet utilisateur.',
        );
      }

      debugPrint('');
      debugPrint('================ ORGANIZATIONS =================');
      debugPrint(
        'NOMBRE : ${organizations.length}',
      );

      for (final organization in organizations) {
        debugPrint(
          'ID=${organization['id']} '
          'NAME=${organization['name']} '
          'SLUG=${organization['slug']}',
        );
      }

      debugPrint('===============================================');

      // ========================================================================
      // EMPLOYEE
      // ========================================================================

      final employee = _extractMap(
        data['employee'],
      );

      // ========================================================================
      // SAVE BASIC SESSION
      // ========================================================================
      //
      // On sauvegarde déjà le token et l'utilisateur.
      //
      // MAIS si plusieurs organisations existent, on ne sauvegarde PAS encore
      // d'organisation active, de rôle ou de permissions.
      //
      // Cela évite de considérer la session comme complètement initialisée.
      // ========================================================================

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'token',
        token,
      );

      await prefs.setString(
        'user',
        jsonEncode(user),
      );

      await prefs.setString(
        'organizations',
        jsonEncode(organizations),
      );

      if (employee != null) {
        await prefs.setString(
          'employee',
          jsonEncode(employee),
        );
      } else {
        await prefs.remove('employee');
      }

      // ========================================================================
      // VERIFICATION MULTI-ORGANISATION
      // ========================================================================

      final requiresOrganizationSelection =
          data['requires_organization_selection'] == true;

      debugPrint('');
      debugPrint('================ ORGANIZATION MODE =============');
      debugPrint(
        'REQUIRES SELECTION : $requiresOrganizationSelection',
      );
      debugPrint(
        'COUNT              : ${organizations.length}',
      );
      debugPrint('===============================================');

      // ========================================================================
      // CAS 1 : PLUSIEURS ORGANISATIONS
      // ========================================================================

      if (requiresOrganizationSelection ||
          organizations.length > 1) {
        await _prepareOrganizationSelection(prefs);

        if (!mounted) {
          return;
        }

        await _showOrganizationSelection(
          token: token,
          organizations: organizations,
        );

        return;
      }

      // ========================================================================
      // CAS 2 : UNE SEULE ORGANISATION
      // ========================================================================

      final rawOrganization = data['organization'];

      Map<String, dynamic> organization;

      if (rawOrganization is Map) {
        organization = Map<String, dynamic>.from(
          rawOrganization,
        );
      } else {
        organization = organizations.first;
      }

      await _completeLogin(
        prefs: prefs,
        token: token,
        organization: organization,
        roles: _extractRoles(data['roles']),
        permissions: _extractPermissions(
          data['permissions'],
        ),
      );
    } catch (e) {
      debugPrint('');
      debugPrint('================ LOGIN ERROR ==================');
      debugPrint('ERROR : $e');
      debugPrint('===============================================');

      if (mounted) {
        _showMessage(
          _cleanExceptionMessage(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ==========================================================================
  // PARSE RESPONSE
  // ==========================================================================

  Map<String, dynamic> _parseResponse(String responseBody) {
    if (responseBody.trim().isEmpty) {
      throw Exception(
        'Le serveur a retourné une réponse vide.',
      );
    }

    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is! Map) {
        throw Exception(
          'La réponse du serveur n’est pas valide.',
        );
      }

      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      if (e is Exception &&
          e.toString().contains('La réponse')) {
        rethrow;
      }

      throw Exception(
        'La réponse du serveur n’est pas un JSON valide.',
      );
    }
  }

  // ==========================================================================
  // EXTRACT MAP
  // ==========================================================================

  Map<String, dynamic>? _extractMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  // ==========================================================================
  // EXTRACT ORGANIZATIONS
  // ==========================================================================

  List<Map<String, dynamic>> _extractOrganizations(
    dynamic rawOrganizations,
  ) {
    if (rawOrganizations is! List) {
      return [];
    }

    final organizations = <Map<String, dynamic>>[];

    for (final item in rawOrganizations) {
      if (item is Map) {
        final organization =
            Map<String, dynamic>.from(item);

        if (organization['id'] != null) {
          organizations.add(organization);
        }
      }
    }

    return organizations;
  }

  // ==========================================================================
  // EXTRACT ROLES
  // ==========================================================================

  List<String> _extractRoles(dynamic rawRoles) {
    final roles = <String>[];

    if (rawRoles is! List) {
      return roles;
    }

    for (final role in rawRoles) {
      if (role is String) {
        final value = role.trim();

        if (value.isNotEmpty) {
          roles.add(value);
        }
      } else if (role is Map) {
        final map = Map<String, dynamic>.from(role);

        final value =
            map['name'] ??
            map['role'] ??
            map['slug'];

        if (value is String) {
          final roleName = value.trim();

          if (roleName.isNotEmpty) {
            roles.add(roleName);
          }
        }
      }
    }

    return roles.toSet().toList();
  }

  // ==========================================================================
  // EXTRACT PERMISSIONS
  // ==========================================================================

  List<String> _extractPermissions(
    dynamic rawPermissions,
  ) {
    final permissions = <String>[];

    if (rawPermissions is! List) {
      return permissions;
    }

    for (final permission in rawPermissions) {
      if (permission is String) {
        final value = permission.trim();

        if (value.isNotEmpty) {
          permissions.add(value);
        }
      } else if (permission is Map) {
        final map = Map<String, dynamic>.from(
          permission,
        );

        final value =
            map['name'] ??
            map['permission'] ??
            map['slug'];

        if (value is String) {
          final permissionName = value.trim();

          if (permissionName.isNotEmpty) {
            permissions.add(permissionName);
          }
        }
      }
    }

    return permissions.toSet().toList();
  }

  // ==========================================================================
  // PREPARE ORGANIZATION SELECTION
  // ==========================================================================

  Future<void> _prepareOrganizationSelection(
    SharedPreferences prefs,
  ) async {
    await prefs.remove('organization');
    await prefs.remove('organization_id');
    await prefs.remove('organization_slug');
    await prefs.remove('roles');
    await prefs.remove('permissions');
    await prefs.remove('home_route');
  }

  // ==========================================================================
  // ORGANIZATION SELECTION
  // ==========================================================================

  Future<void> _showOrganizationSelection({
    required String token,
    required List<Map<String, dynamic>> organizations,
  }) async {
    if (!mounted) {
      return;
    }

    final selectedOrganization =
        await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.business_rounded,
                color: _primaryColor,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Choisir une organisation',
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: organizations.length,
              separatorBuilder: (_, __) {
                return const SizedBox(height: 8);
              },
              itemBuilder: (context, index) {
                final organization =
                    organizations[index];

                final name =
                    organization['name']
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true
                        ? organization['name']
                              .toString()
                        : 'Organisation';

                final slug =
                    organization['slug']
                        ?.toString()
                        .trim();

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(dialogContext)
                          .pop(organization);
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFF8FAFC),
                        border: Border.all(
                          color:
                              const Color(0xFFE2E8F0),
                        ),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration:
                                BoxDecoration(
                              color:
                                  _primaryColor,
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: const Icon(
                              Icons.business_rounded,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        _primaryColor,
                                  ),
                                ),
                                if (slug != null &&
                                    slug.isNotEmpty) ...[
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    slug,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                      color:
                                          Color(
                                        0xFF64748B,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            size: 16,
                            color:
                                Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      Navigator.of(dialogContext)
                          .pop();
                    },
              child: const Text(
                'Annuler',
              ),
            ),
          ],
        );
      },
    );

    if (selectedOrganization == null) {
      /*
       * L'utilisateur a annulé.
       *
       * Le token de base a été sauvegardé temporairement,
       * mais la session n'est pas complète.
       */
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.remove('token');
      await prefs.remove('user');
      await prefs.remove('organizations');
      await prefs.remove('employee');
      await prefs.remove('organization');
      await prefs.remove('organization_id');
      await prefs.remove('organization_slug');
      await prefs.remove('roles');
      await prefs.remove('permissions');
      await prefs.remove('home_route');

      return;
    }

    final organizationId =
        selectedOrganization['id'];

    if (organizationId == null) {
      _showMessage(
        'Organisation invalide.',
        isError: true,
      );
      return;
    }

    // --------------------------------------------------------------------------
    // SWITCH ORGANIZATION
    // --------------------------------------------------------------------------

    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final switchData =
          await _switchOrganization(
        token,
        organizationId,
      );

      final prefs =
          await SharedPreferences.getInstance();

      await _completeLogin(
        prefs: prefs,
        token: token,
        organization:
            switchData['organization'] is Map
                ? Map<String, dynamic>.from(
                    switchData['organization'],
                  )
                : selectedOrganization,
        roles: _extractRoles(
          switchData['roles'],
        ),
        permissions: _extractPermissions(
          switchData['permissions'],
        ),
      );
    } catch (e) {
      debugPrint(
        'ERREUR SELECTION ORGANISATION : $e',
      );

      if (mounted) {
        _showMessage(
          _cleanExceptionMessage(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ==========================================================================
  // SWITCH ORGANIZATION API
  // ==========================================================================

  Future<Map<String, dynamic>> _switchOrganization(
    String token,
    dynamic organizationId,
  ) async {
    debugPrint('');
    debugPrint(
      '================ SWITCH ORGANIZATION ============',
    );
    debugPrint(
      'ORGANIZATION ID : $organizationId',
    );
    debugPrint(
      'URL             : ${ApiConfig.switchOrganization}',
    );
    debugPrint(
      '=================================================',
    );

    final response = await http.post(
      Uri.parse(
        ApiConfig.switchOrganization,
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'organization_id': organizationId,
      }),
    );

    debugPrint(
      'SWITCH STATUS : ${response.statusCode}',
    );
    debugPrint(
      'SWITCH BODY   : ${response.body}',
    );

    final body = _parseResponse(
      response.body,
    );

    if (response.statusCode != 200 ||
        body['status'] != true) {
      throw Exception(
        body['message']?.toString() ??
            'Impossible de sélectionner cette organisation.',
      );
    }

    final rawData = body['data'];

    if (rawData is! Map) {
      throw Exception(
        'Réponse organisation invalide.',
      );
    }

    return Map<String, dynamic>.from(
      rawData,
    );
  }

  // ==========================================================================
  // COMPLETE LOGIN
  // ==========================================================================

  Future<void> _completeLogin({
    required SharedPreferences prefs,
    required String token,
    required Map<String, dynamic> organization,
    required List<String> roles,
    required List<String> permissions,
  }) async {
    final organizationId =
        organization['id'];

    if (organizationId == null) {
      throw Exception(
        'Identifiant de l’organisation manquant.',
      );
    }

    // --------------------------------------------------------------------------
    // ORGANIZATION
    // --------------------------------------------------------------------------

    await prefs.setString(
      'organization',
      jsonEncode(organization),
    );

    await prefs.setString(
      'organization_id',
      organizationId.toString(),
    );

    if (organization['slug'] != null) {
      await prefs.setString(
        'organization_slug',
        organization['slug'].toString(),
      );
    } else {
      await prefs.remove(
        'organization_slug',
      );
    }

    // --------------------------------------------------------------------------
    // ROLES
    // --------------------------------------------------------------------------

    final uniqueRoles =
        roles.toSet().toList();

    await prefs.setString(
      'roles',
      jsonEncode(uniqueRoles),
    );

    // --------------------------------------------------------------------------
    // PERMISSIONS
    // --------------------------------------------------------------------------

    final uniquePermissions =
        permissions.toSet().toList();

    await prefs.setString(
      'permissions',
      jsonEncode(uniquePermissions),
    );

    // --------------------------------------------------------------------------
    // HOME ROUTE
    // --------------------------------------------------------------------------

    final homeRoute =
        _getHomeRoute(uniqueRoles);

    await prefs.setString(
      'home_route',
      homeRoute,
    );

    // --------------------------------------------------------------------------
    // DEBUG
    // --------------------------------------------------------------------------

    debugPrint('');
    debugPrint(
      '======================================================',
    );
    debugPrint(
      '                 LOGIN COMPLETED                     ',
    );
    debugPrint(
      '======================================================',
    );
    debugPrint(
      'ORGANIZATION : ${organization['name']}',
    );
    debugPrint(
      'ORGANIZATION ID : $organizationId',
    );
    debugPrint(
      'ROLES : $uniqueRoles',
    );
    debugPrint(
      'PERMISSIONS : $uniquePermissions',
    );
    debugPrint(
      'HOME ROUTE : $homeRoute',
    );
    debugPrint(
      '======================================================',
    );

    if (!mounted) {
      return;
    }

    // --------------------------------------------------------------------------
    // REDIRECTION
    // --------------------------------------------------------------------------

    _redirectAfterLogin(
      homeRoute,
    );
  }

  // ==========================================================================
  // HOME ROUTE
  // ==========================================================================

  String _getHomeRoute(
    List<String> roles,
  ) {
    /*
     * --------------------------------------------------------------------------
     * ADMIN
     * --------------------------------------------------------------------------
     */

    if (roles.contains('super_admin')) {
      return 'admin';
    }

    if (roles.contains('organization_admin')) {
      return 'admin';
    }

    if (roles.contains('admin_rh')) {
      return 'admin';
    }

    /*
     * --------------------------------------------------------------------------
     * MANAGER
     * --------------------------------------------------------------------------
     */

    if (roles.contains('manager')) {
      return 'manager';
    }

    /*
     * --------------------------------------------------------------------------
     * EMPLOYEE
     * --------------------------------------------------------------------------
     */

    if (roles.contains('employee')) {
      return 'employees';
    }

    /*
     * --------------------------------------------------------------------------
     * KIOSK
     * --------------------------------------------------------------------------
     */

    if (roles.contains('kiosk')) {
      return 'kiosk';
    }

    /*
     * --------------------------------------------------------------------------
     * FALLBACK
     * --------------------------------------------------------------------------
     *
     * On ne redirige plus automatiquement vers admin.
     * Un compte sans rôle connu ne doit pas obtenir un accès administrateur.
     */

    return 'dashboard';
  }

  // ==========================================================================
  // REDIRECTION
  // ==========================================================================

  void _redirectAfterLogin(
    String route,
  ) {
    if (!mounted) {
      return;
    }

    debugPrint('');
    debugPrint(
      '================ REDIRECTION =================',
    );
    debugPrint(
      'ROUTE : $route',
    );

    switch (route) {
      case 'admin':
        debugPrint(
          'GO NAMED => admin',
        );

        context.goNamed(
          'admin',
        );
        break;

      case 'manager':
        debugPrint(
          'GO NAMED => manager',
        );

        context.goNamed(
          'manager',
        );
        break;

      case 'employees':
        debugPrint(
          'GO NAMED => employees',
        );

        context.goNamed(
          'employees',
        );
        break;

      case 'kiosk':
        debugPrint(
          'GO NAMED => kiosk',
        );

        context.goNamed(
          'kiosk',
        );
        break;

      case 'dashboard':
        debugPrint(
          'GO NAMED => dashboard',
        );

        context.goNamed(
          'dashboard',
        );
        break;

      default:
        debugPrint(
          'ROUTE INCONNUE : $route',
        );

        context.goNamed(
          'dashboard',
        );
        break;
    }

    debugPrint(
      '==============================================',
    );
  }

  // ==========================================================================
  // MESSAGE
  // ==========================================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ==========================================================================
  // CLEAN EXCEPTION MESSAGE
  // ==========================================================================

  String _cleanExceptionMessage(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final width =
        MediaQuery.sizeOf(context).width;

    final isMobile =
        width < 850;

    return Scaffold(
      backgroundColor:
          _backgroundColor,
      body: SafeArea(
        child: isMobile
            ? _mobileLayout()
            : _desktopLayout(),
      ),
      floatingActionButton:
          _kioskButton(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
    );
  }

  // ==========================================================================
  // KIOSK BUTTON
  // ==========================================================================

  Widget _kioskButton() {
    return FloatingActionButton(
      heroTag:
          'login-kiosk-button',
      onPressed: loading
          ? null
          : () {
              debugPrint(
                'REDIRECTION => kiosk-login',
              );

              context.goNamed(
                'kiosk-login',
              );
            },
      backgroundColor:
          _primaryColor,
      foregroundColor:
          Colors.white,
      elevation: 8,
      tooltip:
          'Activer le pointeur',
      child: const Icon(
        Icons.point_of_sale_rounded,
        size: 27,
      ),
    );
  }

  // ==========================================================================
  // DESKTOP
  // ==========================================================================

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _desktopBrand(),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 50,
              vertical: 40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 470,
                ),
                child: _loginForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // DESKTOP BRAND
  // ==========================================================================

  Widget _desktopBrand() {
    return Container(
      color: _primaryColor,
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 330,
              height: 330,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: Colors.white
                    .withOpacity(0.035),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: Colors.white
                    .withOpacity(0.025),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(60),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_Splash.jpg',
                    height: 115,
                  ),
                  const SizedBox(height: 42),
                  const Text(
                    'Système de Gestion\n'
                    'de Présence',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.1,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Pointage des employés en temps réel\n'
                    'Gestion RH centralisée',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(0.65),
                      fontSize: 17,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 42),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.05),
                      border:
                          Border.all(
                        color: Colors.white
                            .withOpacity(0.12),
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          color:
                              Colors.white70,
                          size: 18,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Accès sécurisé',
                          style:
                              TextStyle(
                            color:
                                Colors.white70,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MOBILE
  // ==========================================================================

  Widget _mobileLayout() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        25,
        20,
        100,
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo_Splash.jpg',
            height: 85,
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration:
                BoxDecoration(
              color: _primaryColor,
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bienvenue',
            style: TextStyle(
              fontSize: 29,
              fontWeight:
                  FontWeight.w800,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Connectez-vous à votre espace',
            style: TextStyle(
              color:
                  Colors.grey.shade600,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 28),
          _loginForm(),
        ],
      ),
    );
  }

  // ==========================================================================
  // LOGIN FORM
  // ==========================================================================

  Widget _loginForm() {
    return Container(
      padding:
          const EdgeInsets.all(30),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(26),
        border: Border.all(
          color:
              const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.055),
            blurRadius: 30,
            offset:
                const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Connexion',
            style: TextStyle(
              fontSize: 29,
              fontWeight:
                  FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accédez à votre espace personnel.',
            style: TextStyle(
              color:
                  Colors.grey.shade600,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 30),

          // --------------------------------------------------------------------
          // LOGIN
          // --------------------------------------------------------------------

          _input(
            controller:
                loginController,
            label:
                'Email ou numéro de téléphone',
            hint:
                'vous@entreprise.com ou 07...',
            icon:
                Icons.person_outline_rounded,
            keyboardType:
                TextInputType.text,
            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------------------------
          // PASSWORD
          // --------------------------------------------------------------------

          _passwordInput(),

          const SizedBox(height: 8),

          // --------------------------------------------------------------------
          // FORGOT PASSWORD
          // --------------------------------------------------------------------

          Align(
            alignment:
                Alignment.centerRight,
            child: TextButton(
              onPressed: loading
                  ? null
                  : () {
                      context.goNamed(
                        'forgot-password',
                      );
                    },
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------------------------
          // LOGIN BUTTON
          // --------------------------------------------------------------------

          SizedBox(
            width:
                double.infinity,
            height: 56,
            child:
                ElevatedButton(
              onPressed:
                  loading
                      ? null
                      : _login,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    _primaryColor,
                disabledBackgroundColor:
                    const Color(
                  0xFF94A3B8,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
              child:
                  AnimatedSwitcher(
                duration:
                    const Duration(
                  milliseconds: 200,
                ),
                child: loading
                    ? const SizedBox(
                        key: ValueKey(
                          'loading',
                        ),
                        width: 23,
                        height: 23,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2.5,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Row(
                        key: ValueKey(
                          'login',
                        ),
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Icon(
                            Icons
                                .login_rounded,
                            size: 20,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Se connecter',
                            style:
                                TextStyle(
                              fontSize:
                                  15.5,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 26),

          // --------------------------------------------------------------------
          // SEPARATOR
          // --------------------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: Divider(
                  color:
                      Colors.grey.shade300,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                ),
                child: Text(
                  'NOUVEL ESPACE',
                  style:
                      TextStyle(
                    fontSize: 10.5,
                    color: Colors
                        .grey
                        .shade500,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing:
                        0.7,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color:
                      Colors.grey.shade300,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // --------------------------------------------------------------------
          // CREATE ORGANIZATION
          // --------------------------------------------------------------------

          SizedBox(
            width:
                double.infinity,
            height: 50,
            child:
                OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () {
                      context.goNamed(
                        'setup-admin',
                      );
                    },
              icon: const Icon(
                Icons
                    .add_business_outlined,
                size: 20,
              ),
              label: const Text(
                'Créer une organisation',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    _primaryColor,
                side:
                    const BorderSide(
                  color:
                      Color(0xFFCBD5E1),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'Attendance • Gestion de présence',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color:
                    Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // INPUT
  // ==========================================================================

  Widget _input({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction?
        textInputAction,
  }) {
    return TextField(
      controller:
          controller,
      enabled: !loading,
      keyboardType:
          keyboardType,
      textInputAction:
          textInputAction,
      autofillHints: const [
        AutofillHints.username,
      ],
      style:
          const TextStyle(
        fontSize: 14.5,
        fontWeight:
            FontWeight.w500,
        color:
            _primaryColor,
      ),
      decoration:
          InputDecoration(
        labelText:
            label,
        hintText:
            hint,
        prefixIcon:
            Icon(
          icon,
          size: 21,
        ),
        filled: true,
        fillColor:
            _backgroundColor,
        labelStyle:
            const TextStyle(
          color:
              Color(0xFF64748B),
        ),
        hintStyle:
            const TextStyle(
          color:
              Color(0xFF94A3B8),
          fontSize: 13.5,
        ),
        prefixIconColor:
            const Color(
          0xFF64748B,
        ),
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color:
                _primaryColor,
            width: 1.5,
          ),
        ),
        disabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // PASSWORD
  // ==========================================================================

  Widget _passwordInput() {
    return TextField(
      controller:
          passwordController,
      enabled: !loading,
      obscureText:
          obscurePassword,
      textInputAction:
          TextInputAction.done,
      autofillHints: const [
        AutofillHints.password,
      ],
      onSubmitted: (_) {
        if (!loading) {
          _login();
        }
      },
      style:
          const TextStyle(
        fontSize: 14.5,
        fontWeight:
            FontWeight.w500,
        color:
            _primaryColor,
      ),
      decoration:
          InputDecoration(
        labelText:
            'Mot de passe',
        hintText:
            'Votre mot de passe',
        prefixIcon:
            const Icon(
          Icons.lock_outline_rounded,
          size: 21,
        ),
        suffixIcon:
            IconButton(
          tooltip:
              obscurePassword
                  ? 'Afficher le mot de passe'
                  : 'Masquer le mot de passe',
          onPressed:
              loading
                  ? null
                  : () {
                      setState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
          icon:
              Icon(
            obscurePassword
                ? Icons
                    .visibility_off_outlined
                : Icons
                    .visibility_outlined,
          ),
        ),
        filled: true,
        fillColor:
            _backgroundColor,
        labelStyle:
            const TextStyle(
          color:
              Color(0xFF64748B),
        ),
        hintStyle:
            const TextStyle(
          color:
              Color(0xFF94A3B8),
          fontSize: 13.5,
        ),
        prefixIconColor:
            const Color(
          0xFF64748B,
        ),
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color:
                _primaryColor,
            width: 1.5,
          ),
        ),
        disabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }
}