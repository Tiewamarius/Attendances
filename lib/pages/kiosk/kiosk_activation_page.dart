import 'package:attendance/pages/kiosk/attendance_screen.dart';
import 'package:attendance/services/admin/kiosks/kiosk_service.dart';
import 'package:flutter/material.dart';

class KioskActivationPage extends StatefulWidget {
  const KioskActivationPage({super.key});

  @override
  State<KioskActivationPage> createState() =>
      _KioskActivationPageState();
}

class _KioskActivationPageState
    extends State<KioskActivationPage> {
  final _formKey = GlobalKey<FormState>();

  final _kioskNameController =
      TextEditingController();

  final _kioskCodeController =
      TextEditingController();

  final KioskService _kioskService =
      KioskService();

  bool _isLoading = false;

  @override
  void dispose() {
    _kioskNameController.dispose();
    _kioskCodeController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN KIOSK
  // ============================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final kiosk =
          await _kioskService.login(
        name: _kioskNameController.text.trim(),
        code: _kioskCodeController.text
            .trim()
            .toUpperCase(),
      );

      if (!mounted) {
        return;
      }

      debugPrint(
        '✅ Kiosk connecté : ${kiosk.name}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Borne "${kiosk.name}" connectée avec succès.',
          ),
          backgroundColor:
              const Color(0xFF16A34A),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AttendanceScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          )
          .trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Impossible de connecter la borne.'
                : message,
          ),
          backgroundColor:
              const Color(0xFFDC2626),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.sizeOf(context);

    final isTablet =
        size.shortestSide >= 600;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal:
                  isTablet ? 48 : 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 480,
              ),
              child:
                  _buildLoginCard(isTablet),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard(
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(
        isTablet ? 40 : 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.07),
            blurRadius: 30,
            offset:
                const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ==================================================
            // ICON
            // ==================================================

            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFE8F8FF),
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
              child: const Icon(
                Icons
                    .point_of_sale_rounded,
                size: 42,
                color:
                    Color(0xFF20C4F4),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // TITLE
            // ==================================================

            Text(
              'Connexion de la borne',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize:
                    isTablet ? 28 : 24,
                fontWeight:
                    FontWeight.w800,
                color:
                    const Color(0xFF111827),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Connectez cette borne pour commencer le pointage.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color:
                    Color(0xFF64748B),
              ),
            ),

            const SizedBox(
              height: 32,
            ),

            // ==================================================
            // NOM DE LA BORNE
            // ==================================================

            TextFormField(
              controller:
                  _kioskNameController,
              textInputAction:
                  TextInputAction.next,
              textCapitalization:
                  TextCapitalization.words,
              enabled: !_isLoading,
              decoration:
                  _inputDecoration(
                label:
                    'Nom de la borne',
                hint:
                    'Ex. Kiosk 1',
                icon:
                    Icons.devices_rounded,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Veuillez saisir le nom de la borne';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // CODE DE LA BORNE
            // ==================================================

            TextFormField(
              controller:
                  _kioskCodeController,
              textInputAction:
                  TextInputAction.done,
              textCapitalization:
                  TextCapitalization.characters,
              enabled: !_isLoading,
              onFieldSubmitted: (_) =>
                  _login(),
              decoration:
                  _inputDecoration(
                label:
                    'Code de la borne',
                hint:
                    'Ex. KSK-1234',
                icon:
                    Icons.key_rounded,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Veuillez saisir le code de la borne';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // LOGIN BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 56,
              child:
                  ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : _login,
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF111827,
                  ),
                  foregroundColor:
                      Colors.white,
                  disabledBackgroundColor:
                      const Color(
                    0xFFCBD5E1,
                  ),
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
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
                    : const Text(
                        'Connecter la borne',
                        style:
                            TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // SECURITY INFO
            // ==================================================

            const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons
                      .shield_outlined,
                  size: 16,
                  color:
                      Color(0xFF64748B),
                ),
                SizedBox(
                  width: 6,
                ),
                Text(
                  'Borne sécurisée',
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor:
          const Color(0xFFF8FAFC),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFE2E8F0),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color:
              Color(0xFF20C4F4),
          width: 2,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFFCA5A5),
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFDC2626),
          width: 2,
        ),
      ),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
    );
  }
}