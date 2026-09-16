import 'dart:convert';

import 'package:attendance/controllers/employee/employee_controller.dart';
import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:attendance/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EmployeeAttendancePage extends StatefulWidget {
  final EmployeeModel employee;
  final EmployeeController? employeeController;

  const EmployeeAttendancePage({
    super.key,
    required this.employee,
    this.employeeController,
  });

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  late final MobileScannerController _scannerController;

  bool _showCard = true;
  bool _showPin = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  bool _isSubmitting = false;

  String? _employeeQrCode;
  String? _scanMessage;
  String? _scanType;
  bool? _scanSuccess;

  @override
  void initState() {
    super.initState();

    _scannerController = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    _loadRealEmployeeQr();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // ========================================================================
  // CHARGEMENT DU VRAI QR DE L'EMPLOYÉ
  // ========================================================================

  Future<void> _loadRealEmployeeQr() async {
    try {
      final savedEmployee = await AuthService.getSavedEmployee();

      if (savedEmployee == null || savedEmployee.isEmpty) {
        return;
      }

      final qr = _extractQrCode(savedEmployee);

      if (!mounted) return;

      setState(() {
        _employeeQrCode = qr;
      });
    } catch (e) {
      debugPrint('EmployeeAttendancePage._loadRealEmployeeQr(): $e');
    }
  }

  String? _extractQrCode(Map<String, dynamic> data) {
    final candidates = [
      data['qr_code'],
      data['qrCode'],
      data['qr_token'],
      data['qrToken'],
      data['qr'],
      data['token'],
    ];

    for (final value in candidates) {
      final result = value?.toString().trim();

      if (result != null && result.isNotEmpty) {
        return result;
      }
    }

    return null;
  }

  // ========================================================================
  // BUILD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _showCard
                    ? _buildMyCard(widget.employee)
                    : _buildScanner(),
              ),
            ),

            _buildBottomSwitcher(),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // MA CARTE
  // ========================================================================

  Widget _buildMyCard(EmployeeModel employee) {
    final qrData = _employeeQrCode;

    return SingleChildScrollView(
      key: const ValueKey('card'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          _buildCardHeader(),

          const SizedBox(height: 15),

          Container(
            width: 340,
            height: 560,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB112F5), Color.fromARGB(255, 24, 217, 231)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(51, 76, 233, 238),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: CustomPaint(painter: _CardPatternPainter()),
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(height: 38),

                    // ================================================================
                    // PIN + OEIL — CENTRÉS AU-DESSUS DU QR
                    // ================================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.80),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          'PIN :',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          employee.pin != null && employee.pin!.isNotEmpty
                              ? (_showPin ? employee.pin! : '••••••')
                              : 'Non disponible',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),

                        if (employee.pin != null &&
                            employee.pin!.isNotEmpty) ...[
                          const SizedBox(width: 4),

                          InkWell(
                            onTap: () {
                              setState(() {
                                _showPin = !_showPin;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                _showPin
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 17,
                                color: Colors.white.withValues(alpha: 0.90),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 50),

                    // ================================================================
                    // QR CODE — PARFAITEMENT CENTRÉ
                    // ================================================================
                    Center(
                      child: Container(
                        width: 270,
                        height: 300,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: qrData == null || qrData.isEmpty
                            ? _buildQrUnavailable()
                            : QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 320,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),

                    // Espace flexible pour pousser les informations
                    // vers le bas de la carte.
                    const Spacer(),

                    // ================================================================
                    // INFORMATIONS BAS DE CARTE
                    // ================================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 25),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildCardInfo(
                              icon: Icons.business_outlined,
                              label: employee.departmentName,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: _buildCardInfo(
                              icon: Icons.person_outline_rounded,
                              label: employee.managerName,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildEmployeeAvatar(EmployeeModel employee) {
    final image = employee.profileImage?.trim();

    if (image != null && image.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          image,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _buildInitialAvatar(employee);
          },
        ),
      );
    }

    return _buildInitialAvatar(employee);
  }

  Widget _buildInitialAvatar(EmployeeModel employee) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      alignment: Alignment.center,
      child: Text(
        employee.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildQrUnavailable() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 70, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'QR indisponible',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Actualisez votre profil',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // HEADER
  // ========================================================================

  Widget _buildCardHeader() {
    return SizedBox(
      height: 55,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 22),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.close_rounded,
              size: 29,
              color: Color(0xFF111111),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // SCANNER
  // ========================================================================

  Widget _buildScanner() {
    return Stack(
      key: const ValueKey('scanner'),
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _scannerController, onDetect: _onDetect),

        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ScannerOverlayPainter()),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _buildScannerButton(
                      icon: Icons.close_rounded,
                      onTap: _showCardView,
                    ),

                    const Spacer(),

                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _scannerController,
                      builder: (context, state, child) {
                        final torchState = state.torchState;

                        return _buildScannerButton(
                          icon: torchState == TorchState.on
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          onTap: () {
                            _scannerController.toggleTorch();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: 320,
                height: 320,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _ScannerFramePainter()),
                    ),

                    const Positioned(
                      left: 35,
                      right: 35,
                      top: 159,
                      child: _ScannerLine(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Scanner un Code QR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 45),
                child: Text(
                  'Scannez le QR Code du kiosque '
                  'pour effectuer votre pointage.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),

              const Spacer(),

              const SizedBox(height: 20),
            ],
          ),
        ),

        if (_isSubmitting)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScannerButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 25),
      ),
    );
  }

  // ========================================================================
  // DÉTECTION DU QR
  // ========================================================================

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isSubmitting) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue?.trim();

    if (value == null || value.isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    debugPrint('========================================');
    debugPrint('QR CODE SCANNÉ');
    debugPrint(value);
    debugPrint('========================================');

    try {
      await _scannerController.stop();
    } catch (e) {
      debugPrint('Erreur arrêt scanner : $e');
    }

    if (!mounted) return;

    await _submitAttendance(value);
  }

  // ========================================================================
  // ENVOI RÉEL AU BACKEND
  // ========================================================================

  Future<void> _submitAttendance(String qrValue) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        await _showResult(
          success: false,
          title: 'Session expirée',
          message:
              'Votre session utilisateur est expirée. '
              'Veuillez vous reconnecter.',
        );
        return;
      }

      final headers = await AuthService.headers(
        contentType: true,
        includeOrganization: true,
      );

      final response = await http.post(
        Uri.parse(ApiConfig.kioskScanQr),
        headers: headers,
        body: jsonEncode({'qr_code': qrValue}),
      );

      debugPrint('SCAN QR HTTP ${response.statusCode}');

      debugPrint('SCAN QR RESPONSE ${response.body}');

      final body = _decodeJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _extractData(body);

        final message = _extractMessage(
          body,
          fallback: 'Pointage enregistré avec succès.',
        );

        final attendanceType = _extractAttendanceType(data);

        await _showResult(
          success: true,
          title: attendanceType == 'check_out'
              ? 'Départ enregistré'
              : 'Présence enregistrée',
          message: message,
          attendanceType: attendanceType,
        );

        return;
      }

      if (response.statusCode == 401) {
        await _showResult(
          success: false,
          title: 'Session expirée',
          message:
              'Votre session n’est plus valide. '
              'Veuillez vous reconnecter.',
        );
        return;
      }

      if (response.statusCode == 403) {
        await _showResult(
          success: false,
          title: 'Accès refusé',
          message: _extractMessage(
            body,
            fallback: 'Vous n’êtes pas autorisé à effectuer ce pointage.',
          ),
        );
        return;
      }

      if (response.statusCode == 404) {
        await _showResult(
          success: false,
          title: 'QR inconnu',
          message: _extractMessage(
            body,
            fallback: 'Ce QR Code ne correspond pas à un kiosque valide.',
          ),
        );
        return;
      }

      if (response.statusCode == 409) {
        await _showResult(
          success: false,
          title: 'Pointage impossible',
          message: _extractMessage(
            body,
            fallback: 'Le pointage ne peut pas être effectué maintenant.',
          ),
        );
        return;
      }

      await _showResult(
        success: false,
        title: 'Pointage impossible',
        message: _extractMessage(
          body,
          fallback: 'Une erreur est survenue lors du pointage.',
        ),
      );
    } catch (e) {
      debugPrint('EmployeeAttendancePage._submitAttendance(): $e');

      if (!mounted) return;

      await _showResult(
        success: false,
        title: 'Erreur réseau',
        message:
            'Impossible de contacter le serveur. '
            'Vérifiez votre connexion internet.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ========================================================================
  // EXTRACTION RÉPONSE API
  // ========================================================================

  dynamic _decodeJson(String source) {
    if (source.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(source);
    } catch (_) {
      return <String, dynamic>{'message': source};
    }
  }

  dynamic _extractData(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['data'] ?? body;
    }

    return body;
  }

  String _extractMessage(dynamic body, {required String fallback}) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }

      final error = body['error'];

      if (error != null && error.toString().trim().isNotEmpty) {
        return error.toString();
      }

      final errors = body['errors'];

      if (errors is Map) {
        final messages = <String>[];

        for (final value in errors.values) {
          if (value is List) {
            messages.addAll(value.map((e) => e.toString()));
          } else {
            messages.add(value.toString());
          }
        }

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    }

    return fallback;
  }

  String? _extractAttendanceType(dynamic data) {
    if (data is! Map) {
      return null;
    }

    final candidates = [
      data['type'],
      data['attendance_type'],
      data['action'],
      data['status'],
    ];

    for (final value in candidates) {
      final result = value?.toString().trim().toLowerCase();

      if (result == 'check_in' ||
          result == 'check-out' ||
          result == 'check_out' ||
          result == 'checkout') {
        if (result == 'check_out' ||
            result == 'check-out' ||
            result == 'checkout') {
          return 'check_out';
        }

        return 'check_in';
      }
    }

    return null;
  }

  // ========================================================================
  // RÉSULTAT
  // ========================================================================

  Future<void> _showResult({
    required bool success,
    required String title,
    required String message,
    String? attendanceType,
  }) async {
    if (!mounted) return;

    setState(() {
      _scanSuccess = success;
      _scanMessage = message;
      _scanType = attendanceType;
    });

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

        final iconColor = success
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);

        final background = success
            ? const Color(0xFFEAF8EF)
            : const Color(0xFFFFEEEE);

        return Padding(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: iconColor, size: 38),
              ),

              const SizedBox(height: 18),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),

              if (attendanceType != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: success
                        ? const Color(0xFFEAF8EF)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    attendanceType == 'check_out' ? 'Sortie' : 'Entrée',
                    style: TextStyle(
                      color: success
                          ? const Color(0xFF15803D)
                          : const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    success ? 'Terminer' : 'Réessayer',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isSubmitting = false;
      _scanMessage = null;
      _scanSuccess = null;
      _scanType = null;
    });

    if (!success && !_showCard) {
      try {
        await _scannerController.start();
      } catch (e) {
        debugPrint('Erreur redémarrage caméra : $e');
      }
    }
  }

  // ========================================================================
  // AFFICHER CARTE
  // ========================================================================

  Future<void> _showCardView() async {
    try {
      await _scannerController.stop();
    } catch (e) {
      debugPrint('Erreur arrêt caméra : $e');
    }

    if (!mounted) return;

    setState(() {
      _showCard = true;
      _isScanning = false;
      _isProcessing = false;
      _isSubmitting = false;
    });
  }

  // ========================================================================
  // AFFICHER SCANNER
  // ========================================================================

  void _showScannerView() {
    if (!_showCard) return;

    setState(() {
      _showCard = false;
      _isScanning = true;
      _isProcessing = false;
      _isSubmitting = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _showCard) return;

      try {
        await _scannerController.start();

        debugPrint('Scanner démarré');
      } catch (e) {
        debugPrint('Erreur démarrage caméra : $e');
      }
    });
  }

  // ========================================================================
  // SWITCHER
  // ========================================================================

  Widget _buildBottomSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 38),
      height: 62,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(35),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          Expanded(
            child: _buildSwitchItem(
              title: 'Scanner un code',
              icon: Icons.qr_code_scanner_rounded,
              selected: !_showCard,
              onTap: _showScannerView,
            ),
          ),
          Expanded(
            child: _buildSwitchItem(
              title: 'Ma carte',
              icon: Icons.badge_outlined,
              selected: _showCard,
              onTap: _showCardView,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!selected) Icon(icon, size: 17, color: Colors.white),

              if (!selected) const SizedBox(width: 6),

              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? const Color(0xFF111111) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MOTIF CARTE
// ============================================================================

class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const spacing = 70.0;

    for (double y = -100; y < size.height + 100; y += spacing) {
      for (double x = -100; x < size.width + 100; x += spacing) {
        final path = Path();

        path.moveTo(x, y + 30);
        path.lineTo(x + 15, y + 10);
        path.lineTo(x + 30, y + 30);
        path.lineTo(x + 45, y + 10);
        path.lineTo(x + 60, y + 30);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================================
// OVERLAY CAMERA
// ============================================================================

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final scanSize = size.width > 380 ? 320.0 : size.width - 55;

    final scanTop = (size.height - 320) / 2 - 25;

    final scanRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, scanTop + scanSize / 2),
        width: scanSize,
        height: scanSize,
      ),
      const Radius.circular(28),
    );

    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.38);

    canvas.saveLayer(rect, Paint());

    canvas.drawRect(rect, overlayPaint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas.drawRRect(scanRect, clearPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================================
// CADRE SCANNER
// ============================================================================

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF20C4F4)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const radius = 28.0;
    const cornerLength = 38.0;

    final topLeft = Path();

    topLeft.moveTo(10, cornerLength);

    topLeft.lineTo(10, radius);

    topLeft.quadraticBezierTo(10, 10, radius, 10);

    topLeft.lineTo(cornerLength, 10);

    canvas.drawPath(topLeft, paint);

    final topRight = Path();

    topRight.moveTo(size.width - cornerLength, 10);

    topRight.lineTo(size.width - radius, 10);

    topRight.quadraticBezierTo(size.width - 10, 10, size.width - 10, radius);

    topRight.lineTo(size.width - 10, cornerLength);

    canvas.drawPath(topRight, paint);

    final bottomLeft = Path();

    bottomLeft.moveTo(10, size.height - cornerLength);

    bottomLeft.lineTo(10, size.height - radius);

    bottomLeft.quadraticBezierTo(
      10,
      size.height - 10,
      radius,
      size.height - 10,
    );

    bottomLeft.lineTo(cornerLength, size.height - 10);

    canvas.drawPath(bottomLeft, paint);

    final bottomRight = Path();

    bottomRight.moveTo(size.width - cornerLength, size.height - 10);

    bottomRight.lineTo(size.width - radius, size.height - 10);

    bottomRight.quadraticBezierTo(
      size.width - 10,
      size.height - 10,
      size.width - 10,
      size.height - radius,
    );

    bottomRight.lineTo(size.width - 10, size.height - cornerLength);

    canvas.drawPath(bottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================================
// LIGNE SCANNER
// ============================================================================

class _ScannerLine extends StatefulWidget {
  const _ScannerLine();

  @override
  State<_ScannerLine> createState() => _ScannerLineState();
}

class _ScannerLineState extends State<_ScannerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (_controller.value - 0.5) * 240),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xFF20C4F4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF20C4F4).withValues(alpha: 0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
