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
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool loading = false;
  bool checkingInstallation = true;

  bool showKioskButton = false;
  bool showSetupButton = false;

  @override
  void initState() {
    super.initState();
    _checkInstallationStatus();
  }

  // ============================================================
  // VÉRIFICATION INSTALLATION
  // ============================================================

  Future<void> _checkInstallationStatus() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.installationStatus),
        headers: const {
          'Accept': 'application/json',
        },
      );

      debugPrint(
        'INSTALLATION STATUS : ${response.statusCode}',
      );

      debugPrint(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          'Impossible de vérifier l’état de l’installation.',
        );
      }

      final data = jsonDecode(response.body);

      final result = data['data'] ?? {};

      if (!mounted) return;

      setState(() {
        showKioskButton =
            result['show_kiosk_button'] == true;

        // À adapter au nom exact retourné par Laravel
        showSetupButton =
            result['show_setup_button'] == true;

        checkingInstallation = false;
      });
    } catch (e) {
      debugPrint(
        'INSTALLATION STATUS ERROR : $e',
      );

      if (!mounted) return;

      setState(() {
        showKioskButton = false;
        showSetupButton = false;
        checkingInstallation = false;
      });
    }
  }

  // ============================================================
  // CONNEXION
  // ============================================================

  Future<void> _login() async {
    final login = loginController.text.trim();
    final password = passwordController.text.trim();

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
      final url = '${ApiConfig.baseUrl}/auth/login';

      debugPrint('LOGIN URL : $url');

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

      debugPrint(
        'LOGIN STATUS : ${response.statusCode}',
      );

      debugPrint(response.body);

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ??
              'Identifiants incorrects.',
        );
      }

      final result = data['data'] ?? {};

      final token = result['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception(
          'Token d’authentification manquant.',
        );
      }

      final roles = result['roles'] != null
          ? List<String>.from(result['roles'])
          : <String>[];

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'token',
        token.toString(),
      );

      await prefs.setString(
        'user',
        jsonEncode(result['user']),
      );

      await prefs.setString(
        'roles',
        jsonEncode(roles),
      );

      // ========================================================
      // DÉTERMINATION DU RÔLE
      // ========================================================

      final route = _getHomeRoute(roles);

      await prefs.setString(
        'home_route',
        route,
      );

      if (!mounted) return;

      _redirectAfterLogin(route);
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR : $e');
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      _showMessage(
        e.toString()
            .replaceFirst('Exception:', '')
            .trim(),
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ============================================================
  // ROUTE SELON LE RÔLE
  // ============================================================

  String _getHomeRoute(List<String> roles) {
    if (roles.contains('kiosk')) {
      return 'kiosk';
    }

    if (roles.contains('super_admin') ||
        roles.contains('admin_rh')) {
      return 'admin';
    }

    if (roles.contains('manager')) {
      return 'manager';
    }

    if (roles.contains('employee')) {
      return 'employees';
    }

    return 'dashboard';
  }

  // ============================================================
  // REDIRECTION
  // ============================================================

  void _redirectAfterLogin(String route) {
    switch (route) {
      case 'kiosk':
        context.goNamed('kiosk');
        break;

      case 'admin':
        context.goNamed('admin');
        break;

      case 'manager':
        context.goNamed('manager');
        break;

      case 'employees':
        context.goNamed('employees');
        break;

      default:
        context.goNamed('dashboard');
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      body: SafeArea(
        child: checkingInstallation
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : isMobile
                ? _mobileLayout()
                : _desktopLayout(),
      ),

      // ========================================================
      // KIOSK
      // ========================================================

      floatingActionButton:
          showKioskButton
              ? FloatingActionButton.extended(
                  onPressed: loading
                      ? null
                      : () {
                          context.goNamed(
                            'kiosk-login',
                          );
                        },
                  backgroundColor:
                      const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  icon: const Icon(
                    Icons.point_of_sale,
                  ),
                  label: const Text(
                    'Connexion Kiosk',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: _desktopBrand(),
        ),

        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: _loginForm(),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BRAND DESKTOP
  // ============================================================

  Widget _desktopBrand() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_Splash.jpg',
                height: 120,
              ),

              const SizedBox(height: 35),

              const Text(
                'Système de Gestion\n'
                'de Présence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Pointage employés en temps réel\n'
                'Gestion RH centralisée',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white24,
                  ),
                  borderRadius:
                      BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.white70,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Accès sécurisé',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _mobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 35),

          Image.asset(
            'assets/images/logo_Splash.jpg',
            height: 90,
          ),

          const SizedBox(height: 25),

          const Icon(
            Icons.fingerprint,
            size: 80,
            color: Color(0xFF0F172A),
          ),

          const SizedBox(height: 15),

          const Text(
            'Bienvenue',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Connectez-vous à votre espace',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 25),

          _loginForm(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ============================================================
  // FORMULAIRE
  // ============================================================

  Widget _loginForm() {
    return Card(
      elevation: 5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Connexion',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Accédez à votre espace personnel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // LOGIN
            // ==================================================

            TextField(
              controller: loginController,
              keyboardType:
                  TextInputType.emailAddress,
              textInputAction:
                  TextInputAction.next,
              decoration: InputDecoration(
                labelText:
                    'Email ou numéro de téléphone',
                prefixIcon: const Icon(
                  Icons.person_outline,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // PASSWORD
            // ==================================================

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction:
                  TextInputAction.done,
              onSubmitted: (_) {
                if (!loading) {
                  _login();
                }
              },
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon:
                    const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword =
                          !obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // MOT DE PASSE OUBLIÉ
            // ==================================================

            Align(
              alignment: Alignment.centerRight,
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
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // CONNEXION
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                    loading ? null : _login,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login),
                          SizedBox(width: 10),
                          Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // SÉPARATEUR
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey.shade300,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Text(
                    'AUTRES ACCÈS',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey.shade500,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.grey.shade300,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // PREMIÈRE CONFIGURATION
            // ==================================================

            if (showSetupButton)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () {
                          context.goNamed(
                            'setup-admin',
                          );
                        },
                  icon: const Icon(
                    Icons.settings_outlined,
                  ),
                  label: const Text(
                    'Première configuration',
                  ),
                ),
              ),

            // ==================================================
            // KIOSK
            // ==================================================

            if (showKioskButton)
              Padding(
                padding:
                    const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : () {
                            context.goNamed(
                              'kiosk-login',
                            );
                          },
                    icon: const Icon(
                      Icons.point_of_sale_outlined,
                    ),
                    label: const Text(
                      'Configurer / connecter un Kiosk',
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Text(
              'Attendance • Gestion de présence',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}