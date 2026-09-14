import 'dart:async';
import 'package:attendance/models/kiosk_model.dart';
import 'package:attendance/services/admin/kiosks/kiosk_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // ============================================================
  // MODES
  // ============================================================

  /// Le kiosk affiche son QR de pointage.
  static const int modeKioskQr = 0;

  /// Le kiosk ouvre sa caméra et lit le QR de l'employé.
  static const int modeEmployeeQr = 1;

  /// L'employé saisit son code + PIN.
  static const int modePin = 2;

  int _selectedMode = modeKioskQr;

  // ============================================================
  // SERVICE
  // ============================================================

  final KioskService _kioskService = KioskService();

  // ============================================================
  // KIOSK
  // ============================================================

  KioskModel? _kiosk;

  bool _loadingKiosk = true;

  // ============================================================
  // QR KIOSK
  // ============================================================

  /// IMPORTANT :
  /// Ce n'est PAS le token Sanctum du kiosk.
  ///
  /// Cette valeur est un token temporaire généré par Laravel
  /// via /kiosk/attendance-qr.
  String _kioskQrValue = '';

  /// Timer permettant de renouveler automatiquement
  /// le QR avant son expiration.
  Timer? _qrRefreshTimer;

  // ============================================================
  // CODE EMPLOYE
  // ============================================================

  final TextEditingController _employeeCodeController =
      TextEditingController();

  // ============================================================
  // PIN
  // ============================================================

  String _pinCode = '';

  static const int _maxPinLength = 6;

  // ============================================================
  // CAMERA
  // ============================================================

  late final MobileScannerController _employeeQrController;

  // ============================================================
  // ETAT
  // ============================================================

  bool _isProcessing = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _employeeQrController = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.front,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadKiosk();

      if (!mounted) {
        return;
      }

      _startQrRefreshTimer();

      await _startCurrentScanner();
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _qrRefreshTimer?.cancel();

    _employeeQrController.dispose();
    _employeeCodeController.dispose();

    super.dispose();
  }

  // ============================================================
  // CHARGER KIOSK
  // ============================================================

  Future<void> _loadKiosk() async {
  try {
    final token = await _kioskService.getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingKiosk = false;
        _kioskQrValue = '';
      });

      _showMessage(
        'Aucun kiosque connecté.',
        Colors.red,
      );

      return;
    }

    // ------------------------------------------------------------
    // INFORMATIONS DU KIOSK
    // ------------------------------------------------------------

    final kiosk = await _kioskService.me();

    // ------------------------------------------------------------
    // QR DE POINTAGE
    // ------------------------------------------------------------

    String qrValue = '';

    try {
      qrValue =
          await _kioskService.getAttendanceQr();
    } catch (e) {
      debugPrint(
        'Erreur récupération QR Kiosk : $e',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _kiosk = kiosk;
      _loadingKiosk = false;
      _kioskQrValue = qrValue;
    });

    // ------------------------------------------------------------
    // HEARTBEAT
    // ------------------------------------------------------------

    try {
      await _kioskService.heartbeat();
    } catch (e) {
      debugPrint(
        'Heartbeat kiosk impossible : $e',
      );
    }
  } catch (e) {
    debugPrint(
      'Erreur chargement kiosk : $e',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingKiosk = false;
      _kioskQrValue = '';
    });

    _showMessage(
      _cleanError(e),
      Colors.red,
    );
  }
}
  // ============================================================
  // TIMER QR KIOSK
  // ============================================================

  void _startQrRefreshTimer() {
  _qrRefreshTimer?.cancel();

  _qrRefreshTimer = Timer.periodic(
    const Duration(seconds: 45),
    (_) async {
      if (!mounted) return;
      if (_selectedMode != modeKioskQr) return;
      if (_isProcessing) return;

      await _refreshAttendanceQr();
    },
  );
}

  // ============================================================
  // RAFRAICHIR QR KIOSK
  // ============================================================

  Future<void> _refreshAttendanceQr() async {
  try {
    final qrValue = await _kioskService.getAttendanceQr();

    if (qrValue.isEmpty) {
      debugPrint('Token QR Kiosk vide.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _kioskQrValue = qrValue;
    });

    debugPrint('QR Kiosk renouvelé.');
  } catch (e) {
    debugPrint('Erreur renouvellement QR Kiosk : $e');
  }
}

  // ============================================================
  // CHANGEMENT DE MODE
  // ============================================================

  Future<void> _changeMode(int mode) async {
    if (_selectedMode == mode) {
      return;
    }

    await _stopScanner();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedMode = mode;
      _pinCode = '';
      _employeeCodeController.clear();
      _isProcessing = false;
    });

    // ----------------------------------------------------------
    // MODE QR KIOSK
    // ----------------------------------------------------------

    if (mode == modeKioskQr) {
      await _refreshAttendanceQr();
    }

    // ----------------------------------------------------------
    // MODE QR EMPLOYE
    // ----------------------------------------------------------

    if (mode == modeEmployeeQr) {
      await Future.delayed(
        const Duration(milliseconds: 150),
      );

      if (!mounted) {
        return;
      }

      await _startCurrentScanner();
    }
  }

  // ============================================================
  // START CAMERA
  // ============================================================

  Future<void> _startCurrentScanner() async {
    if (_selectedMode != modeEmployeeQr) {
      return;
    }

    try {
      await _employeeQrController.start();
    } catch (e) {
      debugPrint(
        'Erreur démarrage caméra : $e',
      );
    }
  }

  // ============================================================
  // STOP CAMERA
  // ============================================================

  Future<void> _stopScanner() async {
    try {
      await _employeeQrController.stop();
    } catch (e) {
      debugPrint(
        'Erreur arrêt caméra : $e',
      );
    }
  }

  // ============================================================
  // QR EMPLOYE DETECTE
  // ============================================================

  Future<void> _onDetectEmployeeQr(
    BarcodeCapture capture,
  ) async {
    if (_isProcessing) {
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

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await _stopScanner();

    debugPrint(
      'QR EMPLOYE DETECTE',
    );

    try {
      final result = await _kioskService.scanQr(value);

      final employeeName =
          _extractEmployeeName(result);

      final message = _extractMessage(
        result,
        fallback: 'Pointage enregistré avec succès.',
      );

      if (!mounted) {
        return;
      }

      await _showAttendanceResult(
        success: true,
        employeeName: employeeName,
        message: message,
      );
    } catch (e) {
      debugPrint(
        'Erreur pointage QR : $e',
      );

      if (!mounted) {
        return;
      }

      await _showAttendanceResult(
        success: false,
        employeeName: 'Pointage',
        message: _cleanError(e),
      );
    }
  }

  // ============================================================
  // SUBMIT PIN
  // ============================================================

  Future<void> _submitPin() async {
    final employeeCode =
        _employeeCodeController.text.trim();

    if (employeeCode.isEmpty) {
      _showMessage(
        'Veuillez entrer votre code employé.',
        Colors.orange,
      );

      return;
    }

    if (_pinCode.length < 4) {
      _showMessage(
        'Veuillez entrer un code PIN valide.',
        Colors.orange,
      );

      return;
    }

    if (_isProcessing) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result =
          await _kioskService.checkPin(
        employeeCode: employeeCode,
        pin: _pinCode,
      );

      final employeeName =
          _extractEmployeeName(result);

      final message = _extractMessage(
        result,
        fallback: 'Pointage enregistré avec succès.',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pinCode = '';
        _employeeCodeController.clear();
      });

      await _showAttendanceResult(
        success: true,
        employeeName: employeeName,
        message: message,
      );
    } catch (e) {
      debugPrint(
        'Erreur pointage PIN : $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pinCode = '';
      });

      await _showAttendanceResult(
        success: false,
        employeeName: 'Pointage',
        message: _cleanError(e),
      );
    }
  }

  // ============================================================
  // EXTRAIRE NOM EMPLOYE
  // ============================================================

  String _extractEmployeeName(
    Map<String, dynamic> result,
  ) {
    dynamic data = result['data'];

    if (data is Map<String, dynamic>) {
      final employee = data['employee'];

      if (employee is Map<String, dynamic>) {
        final firstName =
            employee['first_name'] ??
                employee['firstname'] ??
                employee['prenom'] ??
                '';

        final lastName =
            employee['last_name'] ??
                employee['lastname'] ??
                employee['nom'] ??
                '';

        final fullName =
            '$firstName $lastName'.trim();

        if (fullName.isNotEmpty) {
          return fullName;
        }

        final name = employee['name'];

        if (name != null &&
            name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      }

      final name = data['employee_name'];

      if (name != null &&
          name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }
    }

    final directName = result['employee_name'];

    if (directName != null &&
        directName.toString().trim().isNotEmpty) {
      return directName.toString().trim();
    }

    return 'Employé';
  }

  // ============================================================
  // EXTRAIRE MESSAGE
  // ============================================================

  String _extractMessage(
    Map<String, dynamic> result, {
    required String fallback,
  }) {
    final message = result['message'];

    if (message != null &&
        message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    final data = result['data'];

    if (data is Map<String, dynamic>) {
      final dataMessage = data['message'];

      if (dataMessage != null &&
          dataMessage.toString().trim().isNotEmpty) {
        return dataMessage.toString();
      }
    }

    return fallback;
  }

  // ============================================================
  // NETTOYER ERREUR
  // ============================================================

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(
        'Exception: '.length,
      );
    }

    return text;
  }

  // ============================================================
  // RESULTAT POINTAGE
  // ============================================================

  Future<void> _showAttendanceResult({
    required bool success,
    required String employeeName,
    required String message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: success
                        ? const Color(0xFFE8FFF1)
                        : const Color(0xFFFFEEEE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    size: 48,
                    color: success
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  success
                      ? 'Pointage réussi'
                      : 'Pointage refusé',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  employeeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 15,
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

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
    });

    if (_selectedMode == modeEmployeeQr) {
      await _startCurrentScanner();
    }

    if (_selectedMode == modeKioskQr &&
        _kioskQrValue.isEmpty) {
      await _refreshAttendanceQr();
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final isTablet =
        size.shortestSide >= 600;

    final isLargeScreen =
        size.width >= 900;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              isTablet: isTablet,
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen
                      ? 80
                      : isTablet
                          ? 40
                          : 16,
                  vertical: 10,
                ),
                child: IndexedStack(
                  index: _selectedMode,
                  children: [
                    _buildKioskQrMode(
                      isTablet: isTablet,
                    ),
                    _buildEmployeeQrMode(
                      isTablet: isTablet,
                    ),
                    _buildPinMode(
                      isTablet: isTablet,
                    ),
                  ],
                ),
              ),
            ),

            _buildModeSelector(
              isTablet: isTablet,
            ),

            SizedBox(
              height: isTablet ? 28 : 18,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required bool isTablet,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 40 : 20,
        18,
        isTablet ? 40 : 20,
        8,
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 58 : 48,
            height: isTablet ? 58 : 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8FF),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Color(0xFF20C4F4),
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pointage',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _kiosk == null
                      ? 'QR Code ou code PIN'
                      : _kiosk!.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _loadingKiosk
                  ? const Color(0xFFFFF7ED)
                  : const Color(0xFFE8FFF1),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _loadingKiosk
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF16A34A),
                ),

                const SizedBox(width: 6),

                Text(
                  _loadingKiosk
                      ? 'Connexion'
                      : 'En ligne',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _loadingKiosk
                        ? const Color(0xFFB45309)
                        : const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODE QR KIOSK
  // ============================================================

  Widget _buildKioskQrMode({
    required bool isTablet,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth;

        final qrSize = isTablet
            ? availableWidth.clamp(
                260.0,
                360.0,
              )
            : availableWidth.clamp(
                220.0,
                300.0,
              );

        return Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 550,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: isTablet ? 76 : 68,
                    height: isTablet ? 76 : 68,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFE8F8FF),
                      borderRadius:
                          BorderRadius.circular(22),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: isTablet ? 44 : 40,
                      color:
                          const Color(0xFF20C4F4),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Scannez le QR Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:
                          isTablet ? 28 : 24,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 9),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Text(
                      'Scannez ce QR Code avec votre téléphone pour effectuer votre pointage.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color:
                            Color(0xFF64748B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Container(
                    width: qrSize,
                    height: qrSize,
                    padding:
                        const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(28),
                      border: Border.all(
                        color:
                            const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: .07,
                          ),
                          blurRadius: 24,
                          offset:
                              const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _kioskQrValue.isEmpty
                        ? Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              const Icon(
                                Icons
                                    .qr_code_rounded,
                                size: 64,
                                color:
                                    Color(0xFFCBD5E1),
                              ),

                              const SizedBox(
                                height: 16,
                              ),

                              const Text(
                                'QR de pointage',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  color:
                                      Color(
                                    0xFF475569,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Padding(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 20,
                                ),
                                child: Text(
                                  _loadingKiosk
                                      ? 'Chargement du kiosque...'
                                      : 'Génération du QR de pointage...',
                                  textAlign:
                                      TextAlign.center,
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    color:
                                        Color(
                                      0xFF94A3B8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : QrImageView(
                            data: _kioskQrValue,
                            version:
                                QrVersions.auto,
                            size: qrSize - 40,
                            backgroundColor:
                                Colors.white,
                            eyeStyle:
                                const QrEyeStyle(
                              eyeShape:
                                  QrEyeShape.square,
                              color:
                                  Color(0xFF111827),
                            ),
                            dataModuleStyle:
                                const QrDataModuleStyle(
                              dataModuleShape:
                                  QrDataModuleShape
                                      .square,
                              color:
                                  Color(0xFF111827),
                            ),
                          ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFE8FFF1),
                      borderRadius:
                          BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .phone_iphone_rounded,
                          size: 18,
                          color:
                              Color(0xFF16A34A),
                        ),

                        SizedBox(width: 8),

                        Flexible(
                          child: Text(
                            'Scannez avec votre téléphone',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  Color(0xFF15803D),
                            ),
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
      },
    );
  }

  // ============================================================
  // MODE QR EMPLOYE
  // ============================================================

  Widget _buildEmployeeQrMode({
    required bool isTablet,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth;

        final scanSize = isTablet
            ? availableWidth.clamp(
                280.0,
                380.0,
              )
            : availableWidth.clamp(
                240.0,
                340.0,
              );

        return Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 600,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: isTablet ? 68 : 60,
                    height: isTablet ? 68 : 60,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFE8F8FF),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 34,
                      color:
                          Color(0xFF20C4F4),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Présentez votre QR Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:
                          isTablet ? 27 : 23,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 9),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 25,
                    ),
                    child: Text(
                      'Présentez le QR Code de votre carte ou de votre téléphone devant la caméra.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color:
                            Color(0xFF64748B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Container(
                    width: scanSize,
                    height: scanSize,
                    clipBehavior:
                        Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius:
                          BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: .12,
                          ),
                          blurRadius: 24,
                          offset:
                              const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller:
                              _employeeQrController,
                          onDetect:
                              _onDetectEmployeeQr,
                        ),

                        IgnorePointer(
                          child: CustomPaint(
                            painter:
                                _QrScannerOverlayPainter(),
                          ),
                        ),

                        Center(
                          child: IgnorePointer(
                            child: SizedBox(
                              width:
                                  scanSize * .70,
                              height:
                                  scanSize * .70,
                              child: CustomPaint(
                                painter:
                                    _QrCornersPainter(),
                              ),
                            ),
                          ),
                        ),

                        if (_isProcessing)
                          Container(
                            color: Colors.black
                                .withValues(
                              alpha: .60,
                            ),
                            child:
                                const Center(
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Color(
                                  0xFF20C4F4,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(30),
                      border: Border.all(
                        color:
                            const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .qr_code_scanner_rounded,
                          size: 19,
                          color:
                              Color(0xFF20C4F4),
                        ),

                        SizedBox(width: 8),

                        Text(
                          'Lecture automatique',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Color(0xFF64748B),
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
      },
    );
  }

  // ============================================================
  // MODE PIN
  // ============================================================

  Widget _buildPinMode({
    required bool isTablet,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(
          vertical: 20,
        ),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 430,
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE8F8FF),
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.pin_rounded,
                  size: 38,
                  color:
                      Color(0xFF20C4F4),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Code PIN personnel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:
                      isTablet ? 26 : 23,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      const Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Entrez votre code employé et votre PIN pour effectuer le pointage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color:
                      Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // CODE EMPLOYE
              // ------------------------------------------------

              TextField(
                controller:
                    _employeeCodeController,
                enabled: !_isProcessing,
                textInputAction:
                    TextInputAction.done,
                textCapitalization:
                    TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText:
                      'Code employé',
                  prefixIcon:
                      const Icon(
                    Icons.badge_outlined,
                    color:
                        Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFF20C4F4),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // PIN DISPLAY
              // ------------------------------------------------

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  _pinCode.isEmpty
                      ? '• • • •'
                      : List.generate(
                          _pinCode.length,
                          (_) => '•',
                        ).join(' '),
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 28,
                    letterSpacing: 6,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF111827),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // KEYPAD
              // ------------------------------------------------

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio:
                    isTablet ? 1.7 : 1.45,
                children: [
                  for (var i = 1; i <= 9; i++)
                    _buildKeypadButton(
                      i.toString(),
                    ),

                  _buildKeypadButton(
                    '⌫',
                    onTap: _deletePin,
                  ),

                  _buildKeypadButton(
                    '0',
                  ),

                  _buildKeypadButton(
                    '✓',
                    color:
                        const Color(0xFF16A34A),
                    textColor: Colors.white,
                    onTap: _submitPin,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // KEYPAD BUTTON
  // ============================================================

  Widget _buildKeypadButton(
    String text, {
    Color? color,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ElevatedButton(
      onPressed: _isProcessing
          ? null
          : onTap ??
              () {
                if (_pinCode.length >=
                    _maxPinLength) {
                  return;
                }

                setState(() {
                  _pinCode += text;
                });
              },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            color ?? Colors.white,
        foregroundColor:
            textColor ??
                const Color(0xFF111827),
        disabledBackgroundColor:
            color?.withValues(
                  alpha: .5,
                ) ??
                Colors.white.withValues(
                  alpha: .6,
                ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
          side: BorderSide(
            color: color == null
                ? const Color(0xFFE2E8F0)
                : Colors.transparent,
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // DELETE PIN
  // ============================================================

  void _deletePin() {
    if (_pinCode.isEmpty) {
      return;
    }

    setState(() {
      _pinCode = _pinCode.substring(
        0,
        _pinCode.length - 1,
      );
    });
  }

  // ============================================================
  // MODE SELECTOR
  // ============================================================

  Widget _buildModeSelector({
    required bool isTablet,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 16,
      ),
      padding:
          const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color:
            const Color(0xFF111827),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              index: modeKioskQr,
              icon:
                  Icons.qr_code_2_rounded,
              label: 'QR Kiosk',
            ),
          ),

          Expanded(
            child: _buildModeButton(
              index: modeEmployeeQr,
              icon:
                  Icons.camera_alt_rounded,
              label: 'Mon QR',
            ),
          ),

          Expanded(
            child: _buildModeButton(
              index: modePin,
              icon:
                  Icons.pin_rounded,
              label: 'PIN',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODE BUTTON
  // ============================================================

  Widget _buildModeButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected =
        _selectedMode == index;

    return GestureDetector(
      behavior:
          HitTestBehavior.opaque,
      onTap: () =>
          _changeMode(index),
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 220,
        ),
        padding:
            const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(17),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? const Color(
                      0xFF111827,
                    )
                  : Colors.white,
            ),

            const SizedBox(height: 5),

            Text(
              label,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? const Color(
                        0xFF111827,
                      )
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// OVERLAY CAMERA
// ================================================================

class _QrScannerOverlayPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = Colors.black.withValues(
        alpha: .45,
      );

    canvas.drawRect(
      Offset.zero & size,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ================================================================
// COINS DU CADRE QR
// ================================================================

class _QrCornersPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const color =
        Color(0xFF20C4F4);

    const strokeWidth = 4.0;
    const radius = 20.0;
    const cornerLength = 35.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // ----------------------------------------------------------
    // HAUT GAUCHE
    // ----------------------------------------------------------

    path.moveTo(
      0,
      cornerLength,
    );

    path.lineTo(
      0,
      radius,
    );

    path.quadraticBezierTo(
      0,
      0,
      radius,
      0,
    );

    path.lineTo(
      cornerLength,
      0,
    );

    // ----------------------------------------------------------
    // HAUT DROIT
    // ----------------------------------------------------------

    path.moveTo(
      size.width - cornerLength,
      0,
    );

    path.lineTo(
      size.width - radius,
      0,
    );

    path.quadraticBezierTo(
      size.width,
      0,
      size.width,
      radius,
    );

    path.lineTo(
      size.width,
      cornerLength,
    );

    // ----------------------------------------------------------
    // BAS GAUCHE
    // ----------------------------------------------------------

    path.moveTo(
      0,
      size.height - cornerLength,
    );

    path.lineTo(
      0,
      size.height - radius,
    );

    path.quadraticBezierTo(
      0,
      size.height,
      radius,
      size.height,
    );

    path.lineTo(
      cornerLength,
      size.height,
    );

    // ----------------------------------------------------------
    // BAS DROIT
    // ----------------------------------------------------------

    path.moveTo(
      size.width - cornerLength,
      size.height,
    );

    path.lineTo(
      size.width - radius,
      size.height,
    );

    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height - radius,
    );

    path.lineTo(
      size.width,
      size.height - cornerLength,
    );

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}