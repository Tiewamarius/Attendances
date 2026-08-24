import 'dart:convert';

import 'package:attendance/core/network/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class SetupAdminPage extends StatefulWidget {
  const SetupAdminPage({super.key});

  @override
  State<SetupAdminPage> createState() => _SetupAdminPageState();
}

class _SetupAdminPageState extends State<SetupAdminPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  Future<void> createAdmin() async {
    setState(() {
      loading = true;
    });

    try {
      final url = ApiConfig.setupAdmin;

      debugPrint("========== SETUP ADMIN ==========");
      debugPrint("URL : $url");

      final response = await http.post(
        Uri.parse(url),

        headers: {
          'Accept': 'application/json',

          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          "name": nameController.text.trim(),

          "email": emailController.text.trim(),

          "phone": phoneController.text.trim(),

          "password": passwordController.text.trim(),
        }),
      );

      debugPrint("STATUS : ${response.statusCode}");

      debugPrint("BODY : ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Administrateur créé avec succès")),
        );

        context.goNamed('login');
      } else {
        throw Exception(data['message'] ?? "Erreur création administrateur");
      }
    } catch (e, stack) {
      debugPrint("ERREUR SETUP ADMIN : $e");

      debugPrint(stack.toString());

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
                const Icon(
                  Icons.admin_panel_settings,

                  size: 120,

                  color: Colors.white,
                ),

                const SizedBox(height: 30),

                const Text(
                  "Première configuration",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 34,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Création du premier administrateur RH\nGestion sécurisée de votre plateforme",

                  textAlign: TextAlign.center,

                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          flex: 4,

          child: Container(
            color: Colors.white,

            child: Center(child: SizedBox(width: 450, child: _adminForm())),
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

          const Icon(
            Icons.admin_panel_settings,

            size: 90,

            color: Color(0xFF0F172A),
          ),

          const SizedBox(height: 30),

          _adminForm(),
        ],
      ),
    );
  }

  Widget _adminForm() {
    return Card(
      elevation: 8,

      shadowColor: Colors.black12,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Text(
              "Créer administrateur",

              style: TextStyle(
                fontSize: 28,

                fontWeight: FontWeight.bold,

                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: nameController,

              decoration: InputDecoration(
                labelText: "Nom complet",

                prefixIcon: const Icon(Icons.person),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.number, // Ouvre le clavier numérique
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter
                    .digitsOnly, // N'autorise que les chiffres (0-9)
              ],
              decoration: InputDecoration(
                labelText: "N° Telephone",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: emailController,

              decoration: InputDecoration(
                labelText: "Email",

                prefixIcon: const Icon(Icons.email),

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
                onPressed: loading ? null : createAdmin,

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
                        "Créer administrateur",

                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 15),

            TextButton.icon(
              onPressed: () {
                context.goNamed('login');
              },

              icon: const Icon(Icons.arrow_back),

              label: const Text("Retour connexion"),
            ),
          ],
        ),
      ),
    );
  }
}
