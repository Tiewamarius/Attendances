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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool loading = false;

  Future<void> login() async {
    setState(() {
      loading = true;
    });

    try {
      final url = '${ApiConfig.baseUrl}/auth/login';

      debugPrint("========== LOGIN DEBUG ==========");
      debugPrint("URL : $url");
      debugPrint("EMAIL : ${emailController.text.trim()}");

      final response = await http.post(
        Uri.parse(url),

        headers: {
          'Accept': 'application/json',

          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          'email': emailController.text.trim(),

          'password': passwordController.text.trim(),
        }),
      );

      debugPrint("STATUS CODE : ${response.statusCode}");

      debugPrint("BODY RESPONSE : ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['data']['token'];

        debugPrint("TOKEN RECU : $token");

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', token);

        await prefs.setString('user', jsonEncode(data['data']['user']));

        debugPrint("Utilisateur sauvegardé");

        if (!mounted) return;

        final roles = data['data']['roles'];

        if (roles.contains('kiosk')) {
          context.goNamed('kiosk');
        } else if (roles.contains('super_admin') ||
            roles.contains('admin_rh')) {
          context.goNamed('kiosk');
        } else {
          context.goNamed('dashboard');
        }
      } else {
        debugPrint("ERREUR API : ${data['message']}");

        throw Exception(data['message'] ?? "Erreur inconnue");
      }
    } catch (e, stackTrace) {
      debugPrint("========== LOGIN ERROR ==========");

      debugPrint("Erreur : $e");

      debugPrint("STACK TRACE : $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(child: isMobile ? _mobileLayout() : _desktopLayout()),
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.all(50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo_Splash.jpg', height: 120),

                const SizedBox(height: 30),

                const Text(
                  'Système de Gestion de Présence',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Pointage des employés en temps réel\nGestion RH centralisée',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),

                const SizedBox(height: 40),

                Expanded(
                  child: Image.asset(
                    'assets/images/logo_Splash.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(child: SizedBox(width: 450, child: _loginForm())),
          ),
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
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Connexion',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Accédez à votre espace RH',
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Se connecter',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            TextButton.icon(
              onPressed: () {
                context.goNamed('setup-admin');
              },

              icon: const Icon(
                Icons.settings_outlined,
                color: Color(0xFF0F172A),
              ),

              label: const Text(
                "Paramètres / Première configuration",
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
