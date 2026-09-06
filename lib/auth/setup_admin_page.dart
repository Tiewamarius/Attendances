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
  // ========================================================================
  // CONTROLLERS
  // ========================================================================

  final organizationNameController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmationController = TextEditingController();

  // ========================================================================
  // STATE
  // ========================================================================

  bool loading = false;
  bool obscurePassword = true;
bool obscureConfirmPassword = true;

  // ========================================================================
  // DISPOSE
  // ========================================================================

  @override
void dispose() {
  organizationNameController.dispose();
  nameController.dispose();
  emailController.dispose();
  phoneController.dispose();
  passwordController.dispose();
  passwordConfirmationController.dispose();
  super.dispose();
}

  // ========================================================================
  // CREATE ORGANIZATION
  // ========================================================================

  Future<void> createOrganization() async {
    FocusScope.of(context).unfocus();

    final organizationName =
        organizationNameController.text.trim();

    final name =
        nameController.text.trim();

    final email =
        emailController.text.trim();

    final phone =
        phoneController.text.trim();

    final password =
        passwordController.text;
        final passwordConfirmation =
    passwordConfirmationController.text;

    if (password.length < 8) {
  _showError(
    'Le mot de passe doit contenir au moins 8 caractères.',
  );
  return;
}

    if (password != passwordConfirmation) {
      _showError(
        'Les mots de passe ne correspondent pas.',
      );
      return;
    }

    // ----------------------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------------------

    if (organizationName.isEmpty) {
      _showError(
        'Veuillez saisir le nom de votre organisation.',
      );
      return;
    }

    if (name.isEmpty) {
      _showError(
        'Veuillez saisir le nom de l’administrateur.',
      );
      return;
    }

    if (email.isEmpty || !_isValidEmail(email)) {
      _showError(
        'Veuillez saisir une adresse email valide.',
      );
      return;
    }

    if (phone.isEmpty) {
      _showError(
        'Veuillez saisir le numéro de téléphone.',
      );
      return;
    }

    if (password.length < 8) {
      _showError(
        'Le mot de passe doit contenir au moins 8 caractères.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // --------------------------------------------------------------------
      // API
      // --------------------------------------------------------------------

      final url = ApiConfig.setupOrganization;

      debugPrint(
        '========== SETUP ORGANIZATION ==========',
      );

      debugPrint('URL : $url');

      final response = await http.post(
        Uri.parse(url),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'organization_name': organizationName,
          'admin_name': name,
          'admin_email': email,
          'admin_phone': phone,
          'admin_password': password,
          'admin_password_confirmation': passwordConfirmation,
        }),
      );

      debugPrint(
        'STATUS : ${response.statusCode}',
      );

      debugPrint(
        'BODY : ${response.body}',
      );

      // --------------------------------------------------------------------
      // PARSE RESPONSE
      // --------------------------------------------------------------------

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(
            response.body,
          );

          if (decoded is Map) {
            data = Map<String, dynamic>.from(
              decoded,
            );
          }
        } catch (_) {
          // Réponse non JSON.
        }
      }

      // --------------------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------------------

      if (response.statusCode == 201 ||
          response.statusCode == 200) {
        if (!mounted) return;

        await _showSuccessDialog();

        if (!mounted) return;

        context.goNamed('login');

        return;
      }

      // --------------------------------------------------------------------
      // VALIDATION LARAVEL
      // --------------------------------------------------------------------

      if (response.statusCode == 422) {
        final errors = data['errors'];

        if (errors is Map) {
          final messages = <String>[];

          errors.forEach((key, value) {
            if (value is List) {
              messages.addAll(
                value.map(
                  (e) => e.toString(),
                ),
              );
            } else {
              messages.add(
                value.toString(),
              );
            }
          });

          if (messages.isNotEmpty) {
            _showError(
              messages.join('\n'),
            );
            return;
          }
        }
      }

      // --------------------------------------------------------------------
      // AUTRE ERREUR
      // --------------------------------------------------------------------

      final message =
          data['message']?.toString() ??
          'Impossible de terminer la configuration.';

      _showError(message);
    } catch (e, stack) {
      debugPrint(
        'ERREUR SETUP ORGANIZATION : $e',
      );

      debugPrint(
        stack.toString(),
      );

      if (mounted) {
        _showError(
          'Impossible de contacter le serveur.\n'
          'Vérifiez votre connexion internet.',
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
  // EMAIL VALIDATION
  // ========================================================================

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  // ========================================================================
  // ERROR
  // ========================================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFDC2626),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ========================================================================
  // SUCCESS DIALOG
  // ========================================================================

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 42,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configuration terminée',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Votre organisation et votre compte administrateur ont été créés avec succès.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================================================================
  // BUILD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final isMobile = width < 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isMobile
            ? _mobileLayout()
            : _desktopLayout(),
      ),
    );
  }

  // ========================================================================
  // DESKTOP
  // ========================================================================

  Widget _desktopLayout() {
    return Row(
      children: [
        // ================================================================
        // LEFT PANEL
        // ================================================================

        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -120,
                  right: -100,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
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
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _brand(),

                      const SizedBox(height: 70),

                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white
                                .withOpacity(0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Bienvenue sur\nAttendance.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Configurez votre organisation en quelques étapes '
                        'et commencez à gérer vos équipes, les présences '
                        'et les horaires.',
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.65),
                          fontSize: 17,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 45),

                      _feature(
                        Icons.business_rounded,
                        'Votre organisation',
                      ),

                      const SizedBox(height: 18),

                      _feature(
                        Icons.admin_panel_settings_rounded,
                        'Votre compte administrateur',
                      ),

                      const SizedBox(height: 18),

                      _feature(
                        Icons.security_rounded,
                        'Un espace sécurisé',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ================================================================
        // RIGHT PANEL
        // ================================================================

        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 50,
              vertical: 40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                ),
                child: _setupForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================================
  // MOBILE
  // ========================================================================

  Widget _mobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 15),

          _mobileBrand(),

          const SizedBox(height: 30),

          _setupForm(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ========================================================================
  // BRAND
  // ========================================================================

  Widget _brand() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            color: Color(0xFF0F172A),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Text(
          'ATTENDANCE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _mobileBrand() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'ATTENDANCE',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  // ========================================================================
  // FEATURE
  // ========================================================================

  Widget _feature(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white70,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ========================================================================
  // SETUP FORM
  // ========================================================================

  Widget _setupForm() {
    return Container(
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ==============================================================
          // TITLE
          // ==============================================================

          const Text(
            'Créer votre espace',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Configurez votre organisation et créez '
            'le premier compte administrateur.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 30),

          // ==============================================================
          // STEP 1
          // ==============================================================

          _sectionTitle(
            number: '01',
            title: 'Votre organisation',
          ),

          const SizedBox(height: 18),

          _input(
            controller: organizationNameController,
            label: 'Nom de l’organisation',
            hint: 'Ex. ODEDIS',
            icon: Icons.business_rounded,
          ),

          const SizedBox(height: 30),

          // ==============================================================
          // STEP 2
          // ==============================================================

          _sectionTitle(
            number: '02',
            title: 'Administrateur',
          ),

          const SizedBox(height: 18),

          _input(
            controller: nameController,
            label: 'Nom complet',
            hint: 'Ex. Jean Kouassi',
            icon: Icons.person_outline_rounded,
            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 15),

          _input(
            controller: phoneController,
            label: 'Téléphone',
            hint: 'Ex. 0700000000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 15),

          _input(
            controller: emailController,
            label: 'Adresse email',
            hint: 'administrateur@entreprise.com',
            icon: Icons.email_outlined,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.next,
          ),

          const SizedBox(height: 15),

          _passwordInput(),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le mot de passe doit contenir au moins '
                  '8 caractères.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ==============================================================
          // BUTTON
          // ==============================================================

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  loading ? null : createOrganization,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF0F172A),
                disabledBackgroundColor:
                    const Color(0xFF94A3B8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
              child: AnimatedSwitcher(
                duration:
                    const Duration(milliseconds: 200),
                child: loading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 23,
                        height: 23,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        key: ValueKey('button'),
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          // Icon(
                          //   Icons.rocket_launch_rounded,
                          //   size: 20,
                          // ),
                          SizedBox(width: 10),
                          Text(
                            'Créer mon organisation',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ==============================================================
          // LOGIN
          // ==============================================================

          Center(
            child: TextButton(
              onPressed: loading
                  ? null
                  : () {
                      context.goNamed('login');
                    },
              child: const Text(
                'J’ai déjà un compte',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // SECTION TITLE
  // ========================================================================

  Widget _sectionTitle({
    required String number,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  // ========================================================================
  // INPUT
  // ========================================================================

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      enabled: !loading,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 21,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 13.5,
        ),
        prefixIconColor:
            const Color(0xFF64748B),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF0F172A),
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // PASSWORD INPUT
  // ========================================================================

  Widget _passwordInput() {
  return Column(
    children: [
      TextField(
        controller: passwordController,
        obscureText: obscurePassword,
        enabled: !loading,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          hintText: 'Minimum 8 caractères',
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            size: 21,
          ),
          suffixIcon: IconButton(
            tooltip: obscurePassword
                ? 'Afficher le mot de passe'
                : 'Masquer le mot de passe',
            onPressed: loading
                ? null
                : () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13.5,
          ),
          prefixIconColor: const Color(0xFF64748B),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF0F172A),
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
        ),
      ),

      const SizedBox(height: 15),

      TextField(
        controller: passwordConfirmationController,
        obscureText: obscureConfirmPassword,
        enabled: !loading,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          if (!loading) {
            createOrganization();
          }
        },
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          labelText: 'Confirmer le mot de passe',
          hintText: 'Saisissez à nouveau votre mot de passe',
          prefixIcon: const Icon(
            Icons.lock_reset_outlined,
            size: 21,
          ),
          suffixIcon: IconButton(
            tooltip: obscureConfirmPassword
                ? 'Afficher le mot de passe'
                : 'Masquer le mot de passe',
            onPressed: loading
                ? null
                : () {
                    setState(() {
                      obscureConfirmPassword =
                          !obscureConfirmPassword;
                    });
                  },
            icon: Icon(
              obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13.5,
          ),
          prefixIconColor: const Color(0xFF64748B),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF0F172A),
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
        ),
      ),
    ],
  );
}
}