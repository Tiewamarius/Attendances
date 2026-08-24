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
  bool showKioskButton = false;
  bool checkingInstallation = true;
  bool superAdminExists = false;

  final loginController = TextEditingController();

  final passwordController = TextEditingController();

  bool obscurePassword = true;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    checkInstallationStatus();
  }

  Future<void> checkInstallationStatus() async {
    try {
      final url = ApiConfig.installationStatus;

      debugPrint('INSTALLATION STATUS URL : $url');

      final response = await http.get(
        Uri.parse(url),
        headers: const {'Accept': 'application/json'},
      );

      debugPrint('INSTALLATION STATUS : ${response.statusCode}');

      debugPrint(response.body);

      if (response.statusCode != 200) {
        throw Exception('Impossible de vérifier l’état de l’installation');
      }

      final data = jsonDecode(response.body);

      final result = data['data'];

      if (!mounted) return;

      setState(() {
        showKioskButton = result['show_kiosk_button'] == true;
        checkingInstallation = false;
      });
    } catch (e) {
      debugPrint('INSTALLATION STATUS ERROR : $e');

      if (!mounted) return;

      setState(() {
        showKioskButton = false;
        checkingInstallation = false;
      });
    }
  }

  Future<void> login() async {
    if (loginController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final url = '${ApiConfig.baseUrl}/auth/login';

      debugPrint("LOGIN URL : $url");

      final response = await http.post(
        Uri.parse(url),

        headers: const {
          'Accept': 'application/json',

          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          "login": loginController.text.trim(),

          "password": passwordController.text.trim(),
        }),
      );

      debugPrint("STATUS : ${response.statusCode}");

      debugPrint(response.body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final result = data['data'];

        final token = result['token'];

        final roles = result['roles'] != null
            ? List<String>.from(result['roles'])
            : [];

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', token);

        await prefs.setString('user', jsonEncode(result['user']));

        await prefs.setString('roles', jsonEncode(roles));

        String homeRoute = 'dashboard';

        if (roles.contains('kiosk')) {
          homeRoute = 'kiosk';
        } else if (roles.contains('super_admin') ||
            roles.contains('admin_rh')) {
          homeRoute = 'admin';
        } else if (roles.contains('employee')) {
          homeRoute = 'employees';
        }

        await prefs.setString('home_route', homeRoute);

        if (!mounted) return;

        switch (homeRoute) {
          case 'kiosk':
            context.goNamed('kiosk');

            break;

          case 'admin':
            context.goNamed('admin');

            break;

          case 'employees':
            context.goNamed('employees');

            break;

          default:
            context.goNamed('dashboard');
        }
      } else {
        throw Exception(data['message'] ?? "Identifiants incorrects");
      }
    } catch (e, stackTrace) {
      debugPrint("LOGIN ERROR : $e");

      debugPrint(stackTrace.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception:", "").trim()),
          ),
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

  @override
  void dispose() {
    loginController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final mobile = width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      body: SafeArea(child: mobile ? _mobileLayout() : _desktopLayout()),

      floatingActionButton: showKioskButton
          ? FloatingActionButton.extended(
              onPressed: () {
                context.goNamed('kiosk-login');
              },

              backgroundColor: const Color(0xFF0F172A),

              foregroundColor: Colors.white,

              icon: const Icon(Icons.point_of_sale),

              label: const Text(
                'Connexion Kiosk',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 6,

          child: Container(
            color: const Color(0xFF0F172A),

            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Image.asset('assets/images/logo_Splash.jpg', height: 120),

                  const SizedBox(height: 30),

                  const Text(
                    "Système de Gestion de Présence",

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 34,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Pointage employés en temps réel\nGestion RH centralisée",

                    textAlign: TextAlign.center,

                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          flex: 4,

          child: Center(child: SizedBox(width: 450, child: _loginForm())),
        ),
      ],
    );
  }

  Widget _mobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),

      child: Column(
        children: [
          const SizedBox(height: 40),

          Image.asset('assets/images/logo_Splash.jpg', height: 90),

          const SizedBox(height: 30),

          const Icon(Icons.fingerprint, size: 90, color: Color(0xFF0F172A)),

          const SizedBox(height: 30),

          _loginForm(),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Card(
      elevation: 8,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Text(
              "Connexion",

              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: loginController,

              decoration: const InputDecoration(
                labelText: "Email/N° Telephone)",

                prefixIcon: Icon(Icons.email),

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,

              obscureText: obscurePassword,

              decoration: InputDecoration(
                labelText: "Mot de passe",

                prefixIcon: const Icon(Icons.lock),

                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),

                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),

                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              height: 55,

              child: ElevatedButton(
                onPressed: loading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),

                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Se connecter"),
              ),
            ),

            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: () {
                context.goNamed('setup-admin');
              },

              icon: const Icon(Icons.settings),

              label: const Text("Paramètres / Première configuration"),
            ),
          ],
        ),
      ),
    );
  }
}
