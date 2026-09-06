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
  // ========================================================================
  // CONTROLLERS
  // ========================================================================

  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  // ========================================================================
  // STATE
  // ========================================================================

  bool obscurePassword = true;
  bool loading = false;

  // ========================================================================
  // DISPOSE
  // ========================================================================

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ========================================================================
  // LOGIN
  // ========================================================================

  Future<void> _login() async {
    final login = loginController.text.trim();
    final password = passwordController.text;

    // ----------------------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------------------

    if (login.isEmpty || password.isEmpty) {
      _showMessage(
        'Veuillez remplir tous les champs.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
    });

    try {
      // ====================================================================
      // API
      // ====================================================================

      final url = ApiConfig.login;

      debugPrint('');
      debugPrint('======================================================');
      debugPrint('                    LOGIN START                       ');
      debugPrint('======================================================');
      debugPrint('LOGIN SAISI : $login');
      debugPrint('URL API     : $url');
      debugPrint('======================================================');

      final response = await http.post(
        Uri.parse(url),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'login': login,
          'password': password,
        }),
      );

      // ====================================================================
      // RESPONSE API
      // ====================================================================

      debugPrint('');
      debugPrint('================ API RESPONSE =================');
      debugPrint('STATUS CODE : ${response.statusCode}');
      debugPrint('BODY :');
      debugPrint(response.body);
      debugPrint('===============================================');

      // ====================================================================
      // PARSE RESPONSE
      // ====================================================================

      Map<String, dynamic> body = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);

          debugPrint('');
          debugPrint('================ JSON =================');
          debugPrint('JSON TYPE : ${decoded.runtimeType}');
          debugPrint('=======================================');

          if (decoded is Map) {
            body = Map<String, dynamic>.from(decoded);
          }
        } catch (e) {
          debugPrint('');
          debugPrint('ERREUR JSON : $e');

          throw Exception(
            'La réponse du serveur n\'est pas un JSON valide.',
          );
        }
      }

      // ====================================================================
      // ERROR HTTP
      // ====================================================================

      if (response.statusCode != 200) {
        final message =
            body['message']?.toString() ??
            'Identifiants incorrects.';

        debugPrint('');
        debugPrint(
          '================ LOGIN ERROR HTTP ================',
        );
        debugPrint('STATUS  : ${response.statusCode}');
        debugPrint('MESSAGE : $message');
        debugPrint(
          '===================================================',
        );

        throw Exception(message);
      }

      // ====================================================================
      // STATUS API
      // ====================================================================

      final apiStatus = body['status'];

      debugPrint('');
      debugPrint('================ API STATUS =================');
      debugPrint('STATUS : $apiStatus');
      debugPrint('MESSAGE : ${body['message']}');
      debugPrint('==============================================');

      if (apiStatus == false) {
        throw Exception(
          body['message']?.toString() ??
              'Connexion refusée.',
        );
      }

      // ====================================================================
      // DATA
      // ====================================================================

      final rawData = body['data'];

      debugPrint('');
      debugPrint('================ DATA =================');
      debugPrint('DATA : $rawData');
      debugPrint('TYPE : ${rawData.runtimeType}');
      debugPrint('========================================');

      if (rawData is! Map) {
        throw Exception(
          'Réponse serveur invalide : data est absent ou incorrect.',
        );
      }

      final data = Map<String, dynamic>.from(rawData);

      // ====================================================================
      // TOKEN
      // ====================================================================

      final rawToken = data['token'];

      debugPrint('');
      debugPrint('================ TOKEN =================');
      debugPrint('TOKEN PRESENT : ${rawToken != null}');
      debugPrint('TOKEN TYPE    : ${rawToken.runtimeType}');

      if (rawToken != null) {
        final tokenString = rawToken.toString();

        debugPrint(
          'TOKEN : ${tokenString.length > 20 ? '${tokenString.substring(0, 20)}...' : tokenString}',
        );
      }

      debugPrint('========================================');

      if (rawToken == null) {
        throw Exception(
          'Token d’authentification manquant.',
        );
      }

      final token = rawToken.toString().trim();

      if (token.isEmpty) {
        throw Exception(
          'Token d’authentification invalide.',
        );
      }

      // ====================================================================
      // USER
      // ====================================================================

      final rawUser = data['user'];

      debugPrint('');
      debugPrint('================ USER =================');
      debugPrint('USER : $rawUser');
      debugPrint('TYPE : ${rawUser.runtimeType}');
      debugPrint('=======================================');

      if (rawUser is! Map) {
        throw Exception(
          'Utilisateur absent de la réponse.',
        );
      }

      final user = Map<String, dynamic>.from(rawUser);

      // ====================================================================
      // ORGANIZATIONS
      // ====================================================================

      final rawOrganizations = data['organizations'];

      debugPrint('');
      debugPrint(
        '================ ORGANIZATIONS =================',
      );
      debugPrint(
        'ORGANIZATIONS : $rawOrganizations',
      );
      debugPrint(
        'TYPE : ${rawOrganizations.runtimeType}',
      );
      debugPrint(
        '===============================================',
      );

      if (rawOrganizations is! List) {
        throw Exception(
          'La liste des organisations est absente.',
        );
      }

      if (rawOrganizations.isEmpty) {
        throw Exception(
          'Aucune organisation associée à cet utilisateur.',
        );
      }

      // ====================================================================
      // ORGANISATIONS VALIDES
      // ====================================================================

      final organizations = <Map<String, dynamic>>[];

      for (final item in rawOrganizations) {
        if (item is Map) {
          organizations.add(
            Map<String, dynamic>.from(item),
          );
        }
      }

      if (organizations.isEmpty) {
        throw Exception(
          'Aucune organisation valide trouvée.',
        );
      }

      debugPrint('');
      debugPrint(
        'NOMBRE D\'ORGANISATIONS : ${organizations.length}',
      );

      for (final organization in organizations) {
        debugPrint(
          ' - ID=${organization['id']} '
          'NAME=${organization['name']} '
          'SLUG=${organization['slug']}',
        );
      }

      // ====================================================================
      // ORGANISATION ACTIVE
      // ====================================================================

      /*
       * Pour le moment :
       *
       * - 1 organisation  => elle devient automatiquement active
       * - plusieurs       => première organisation temporairement active
       *
       * La sélection d'organisation pourra ensuite être ajoutée
       * sans modifier le fonctionnement du login.
       */

      final organization = organizations.first;

      debugPrint('');
      debugPrint(
        '================ ORGANISATION ACTIVE ================',
      );
      debugPrint(
        'ID   : ${organization['id']}',
      );
      debugPrint(
        'NAME : ${organization['name']}',
      );
      debugPrint(
        'SLUG : ${organization['slug']}',
      );
      debugPrint(
        '======================================================',
      );

      // ====================================================================
      // EMPLOYEE
      // ====================================================================

      final employee = data['employee'];

      debugPrint('');
      debugPrint('================ EMPLOYEE =================');
      debugPrint('EMPLOYEE : $employee');
      debugPrint('TYPE     : ${employee.runtimeType}');
      debugPrint('===========================================');

      // ====================================================================
      // ROLES
      // ====================================================================

      /*
       * IMPORTANT :
       *
       * Le endpoint LOGIN actuel ne retourne pas les rôles.
       *
       * Exemple actuel :
       *
       * data = {
       *   token,
       *   user,
       *   organizations,
       *   employee
       * }
       *
       * Les rôles et permissions devront être récupérés depuis
       * l'endpoint de profil/dashboard de l'organisation.
       */

      final rawRoles = data['roles'];

      debugPrint('');
      debugPrint('================ ROLES =================');
      debugPrint('ROLES : $rawRoles');
      debugPrint('TYPE  : ${rawRoles.runtimeType}');
      debugPrint('========================================');

      final roles = <String>[];

      if (rawRoles is List) {
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

            if (value is String &&
                value.trim().isNotEmpty) {
              roles.add(value.trim());
            }
          }
        }
      }

      final uniqueRoles = roles.toSet().toList();

      debugPrint(
        'ROLES FINAUX : $uniqueRoles',
      );

      // ====================================================================
      // PERMISSIONS
      // ====================================================================

      final rawPermissions = data['permissions'];

      final permissions = <String>[];

      if (rawPermissions is List) {
        for (final permission in rawPermissions) {
          if (permission is String &&
              permission.trim().isNotEmpty) {
            permissions.add(
              permission.trim(),
            );
          }
        }
      }

      debugPrint('');
      debugPrint(
        '================ PERMISSIONS =================',
      );
      debugPrint(
        'PERMISSIONS : $permissions',
      );
      debugPrint(
        '===============================================',
      );

      // ====================================================================
      // SHARED PREFERENCES
      // ====================================================================

      final prefs =
          await SharedPreferences.getInstance();

      debugPrint('');
      debugPrint(
        '================ SAVE SESSION =================',
      );

      // --------------------------------------------------------------------
      // TOKEN
      // --------------------------------------------------------------------

      await prefs.setString(
        'token',
        token,
      );

      debugPrint(
        'TOKEN SAUVEGARDÉ : '
        '${prefs.getString('token') != null}',
      );

      // --------------------------------------------------------------------
      // USER
      // --------------------------------------------------------------------

      await prefs.setString(
        'user',
        jsonEncode(user),
      );

      debugPrint(
        'USER SAUVEGARDÉ : '
        '${prefs.getString('user')}',
      );

      // --------------------------------------------------------------------
      // ORGANISATION ACTIVE
      // --------------------------------------------------------------------

      await prefs.setString(
        'organization',
        jsonEncode(organization),
      );

      debugPrint(
        'ORGANISATION ACTIVE SAUVEGARDÉE : '
        '${prefs.getString('organization')}',
      );

      // --------------------------------------------------------------------
      // TOUTES LES ORGANISATIONS
      // --------------------------------------------------------------------

      await prefs.setString(
        'organizations',
        jsonEncode(organizations),
      );

      debugPrint(
        'ORGANISATIONS SAUVEGARDÉES : '
        '${prefs.getString('organizations')}',
      );

      // --------------------------------------------------------------------
      // ORGANISATION ID
      // --------------------------------------------------------------------

      if (organization['id'] != null) {
        await prefs.setString(
          'organization_id',
          organization['id'].toString(),
        );
      }

      debugPrint(
        'ORGANIZATION ID : '
        '${prefs.getString('organization_id')}',
      );

      // --------------------------------------------------------------------
      // ORGANISATION SLUG
      // --------------------------------------------------------------------

      if (organization['slug'] != null) {
        await prefs.setString(
          'organization_slug',
          organization['slug'].toString(),
        );
      }

      debugPrint(
        'ORGANIZATION SLUG : '
        '${prefs.getString('organization_slug')}',
      );

      // --------------------------------------------------------------------
      // ROLES
      // --------------------------------------------------------------------

      await prefs.setString(
        'roles',
        jsonEncode(uniqueRoles),
      );

      debugPrint(
        'ROLES SAUVEGARDÉS : '
        '${prefs.getString('roles')}',
      );

      // --------------------------------------------------------------------
      // PERMISSIONS
      // --------------------------------------------------------------------

      await prefs.setString(
        'permissions',
        jsonEncode(permissions),
      );

      debugPrint(
        'PERMISSIONS SAUVEGARDÉES : '
        '${prefs.getString('permissions')}',
      );

      // --------------------------------------------------------------------
      // EMPLOYEE
      // --------------------------------------------------------------------

      if (employee is Map) {
        await prefs.setString(
          'employee',
          jsonEncode(
            Map<String, dynamic>.from(employee),
          ),
        );

        debugPrint(
          'EMPLOYEE SAUVEGARDÉ : '
          '${prefs.getString('employee')}',
        );
      } else {
        await prefs.remove('employee');

        debugPrint(
          'EMPLOYEE : aucun employee sauvegardé.',
        );
      }

      debugPrint(
        '================================================',
      );

      // ====================================================================
      // HOME ROUTE
      // ====================================================================

      /*
       * IMPORTANT :
       *
       * Le LOGIN actuel ne retourne pas les rôles.
       *
       * Donc nous ne pouvons pas encore déterminer correctement
       * la page d'accueil à partir du rôle.
       *
       * Pour ton architecture actuelle :
       *
       * organisation active
       *        ↓
       *      /admin
       *
       * Le rôle réel sera récupéré ensuite depuis l'API
       * de l'organisation.
       */

      const homeRoute = 'admin';

      await prefs.setString(
        'home_route',
        homeRoute,
      );

      debugPrint('');
      debugPrint(
        '================ HOME ROUTE =================',
      );
      debugPrint(
        'HOME ROUTE : $homeRoute',
      );
      debugPrint(
        'HOME ROUTE PREFS : '
        '${prefs.getString('home_route')}',
      );
      debugPrint(
        '==============================================',
      );

      // ====================================================================
      // SESSION DEBUG
      // ====================================================================

      debugPrint('');
      debugPrint(
        '================ SESSION =================',
      );
      debugPrint(
        'AUTHENTIFIÉ      : ${prefs.getString('token') != null}',
      );
      debugPrint(
        'USER             : ${prefs.getString('user') != null}',
      );
      debugPrint(
        'ORGANISATION     : ${prefs.getString('organization') != null}',
      );
      debugPrint(
        'ORGANISATIONS    : ${prefs.getString('organizations') != null}',
      );
      debugPrint(
        'ORGANISATION ID  : ${prefs.getString('organization_id')}',
      );
      debugPrint(
        'ORGANISATION SLUG: ${prefs.getString('organization_slug')}',
      );
      debugPrint(
        'ROLES            : ${prefs.getString('roles')}',
      );
      debugPrint(
        'PERMISSIONS      : ${prefs.getString('permissions')}',
      );
      debugPrint(
        'HOME ROUTE       : ${prefs.getString('home_route')}',
      );
      debugPrint(
        '============================================',
      );

      // ====================================================================
      // REDIRECTION
      // ====================================================================

      if (!mounted) {
        debugPrint(
          'WIDGET NON MOUNTED : redirection annulée.',
        );
        return;
      }

      debugPrint('');
      debugPrint(
        '================ REDIRECTION =================',
      );
      debugPrint(
        'GO NAMED : admin',
      );
      debugPrint(
        '==============================================',
      );

      context.goNamed('admin');
    } catch (e) {
      debugPrint('');
      debugPrint(
        '================ LOGIN EXCEPTION ================',
      );
      debugPrint(
        'ERREUR : $e',
      );
      debugPrint(
        '==================================================',
      );

      if (mounted) {
        _showMessage(
          e.toString().replaceFirst(
            'Exception: ',
            '',
          ),
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

  // ========================================================================
  // REDIRECTION
  // ========================================================================

  void _redirectAfterLogin(String route) {
    debugPrint('');
    debugPrint(
      '==============================================',
    );
    debugPrint(
      '             REDIRECTION LOGIN                ',
    );
    debugPrint(
      '==============================================',
    );
    debugPrint(
      'ROUTE REÇUE : $route',
    );

    switch (route) {
      case 'admin':
        debugPrint(
          'GO NAMED => admin',
        );

        context.goNamed('admin');
        break;

      case 'employees':
        debugPrint(
          'GO NAMED => employees',
        );

        context.goNamed('employees');
        break;

      case 'kiosk':
        debugPrint(
          'GO NAMED => kiosk',
        );

        context.goNamed('kiosk');
        break;

      default:
        debugPrint(
          'ROUTE INCONNUE : $route',
        );

        debugPrint(
          'FALLBACK => admin',
        );

        context.goNamed('admin');
    }

    debugPrint(
      '==============================================',
    );
  }

  // ========================================================================
  // MESSAGE
  // ========================================================================

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
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ========================================================================
  // BUILD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width;

    final isMobile = width < 850;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),
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

  // ========================================================================
  // KIOSK BUTTON
  // ========================================================================

  Widget _kioskButton() {
    return FloatingActionButton(
      heroTag: 'login-kiosk-button',
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
          const Color(0xFF0F172A),
      foregroundColor: Colors.white,
      elevation: 8,
      tooltip: 'Activer le pointeur',
      child: const Icon(
        Icons.point_of_sale_rounded,
        size: 27,
      ),
    );
  }

  // ========================================================================
  // DESKTOP
  // ========================================================================

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
            padding: const EdgeInsets.symmetric(
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

  // ========================================================================
  // DESKTOP BRAND
  // ========================================================================

  Widget _desktopBrand() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    Colors.white.withOpacity(0.035),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    Colors.white.withOpacity(0.025),
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
                      border: Border.all(
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
                          style: TextStyle(
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

  // ========================================================================
  // MOBILE
  // ========================================================================

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
            decoration: BoxDecoration(
              color:
                  const Color(0xFF0F172A),
              borderRadius:
                  BorderRadius.circular(20),
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
              color:
                  Color(0xFF0F172A),
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

  // ========================================================================
  // LOGIN FORM
  // ========================================================================

  Widget _loginForm() {
    return Container(
      padding:
          const EdgeInsets.all(30),
      decoration: BoxDecoration(
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
              color:
                  Color(0xFF0F172A),
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

          _input(
            controller:
                loginController,
            label: 'Email',
            hint:
                'vous@entreprise.com',
            icon:
                Icons.email_outlined,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 16),

          _passwordInput(),

          const SizedBox(height: 8),

          Align(
            alignment:
                Alignment.centerRight,
            child: TextButton(
              onPressed: loading
                  ? null
                  : () {
                      debugPrint(
                        'REDIRECTION => forgot-password',
                      );

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
                    const Color(
                  0xFF0F172A,
                ),
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
                          strokeWidth: 2.5,
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
                    color:
                        Colors.grey.shade500,
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

          SizedBox(
            width:
                double.infinity,
            height: 50,
            child:
                OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () {
                      debugPrint(
                        'REDIRECTION => setup-admin',
                      );

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
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xFF0F172A,
                ),
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

  // ========================================================================
  // INPUT
  // ========================================================================

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
      controller: controller,
      enabled: !loading,
      keyboardType:
          keyboardType,
      textInputAction:
          textInputAction,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight:
            FontWeight.w500,
        color:
            Color(0xFF0F172A),
      ),
      decoration:
          InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 21,
        ),
        filled: true,
        fillColor:
            const Color(0xFFF8FAFC),
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
                Color(0xFF0F172A),
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

  // ========================================================================
  // PASSWORD
  // ========================================================================

  Widget _passwordInput() {
    return TextField(
      controller:
          passwordController,
      enabled: !loading,
      obscureText:
          obscurePassword,
      textInputAction:
          TextInputAction.done,
      onSubmitted: (_) {
        if (!loading) {
          _login();
        }
      },
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight:
            FontWeight.w500,
        color:
            Color(0xFF0F172A),
      ),
      decoration:
          InputDecoration(
        labelText:
            'Mot de passe',
        hintText:
            'Votre mot de passe',
        prefixIcon:
            const Icon(
          Icons
              .lock_outline_rounded,
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
          icon: Icon(
            obscurePassword
                ? Icons
                    .visibility_off_outlined
                : Icons
                    .visibility_outlined,
          ),
        ),
        filled: true,
        fillColor:
            const Color(0xFFF8FAFC),
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
                Color(0xFF0F172A),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}