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

  /// Le kiosk affiche son QR.
  static const int modeKioskQr = 0;

  /// Le kiosk ouvre sa caméra et lit le QR de l'employé.
  static const int modeEmployeeQr = 1;

  /// L'employé saisit son PIN.
  static const int modePin = 2;

  int _selectedMode = modeKioskQr;

  // ============================================================
  // QR KIOSK
  // ============================================================

  /// TODO:
  /// Cette valeur devra venir de Laravel.
  ///
  /// Exemple :
  /// https://api.example.com/attendance/kiosk?token=xxxxx
  String _kioskQrValue =
      'https://example.com/attendance/kiosk?token=KIOSK_TOKEN';

  // ============================================================
  // PIN
  // ============================================================

  String _pinCode = '';

  static const int _maxPinLength = 6;

  // ============================================================
  // CAMERA
  // ============================================================

  /// Une seule caméra est nécessaire.
  ///
  /// Elle sert uniquement au mode :
  /// "QR Employé".
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
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCurrentScanner();
    });
  }

  @override
  void dispose() {
    _employeeQrController.dispose();
    super.dispose();
  }

  // ============================================================
  // CHANGEMENT DE MODE
  // ============================================================

  Future<void> _changeMode(int mode) async {
    if (_selectedMode == mode) {
      return;
    }

    // Toujours arrêter la caméra avant de changer de mode.
    await _stopScanner();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedMode = mode;
      _pinCode = '';
      _isProcessing = false;
    });

    // Seul le mode QR Employé utilise la caméra.
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
    // QR Kiosk = pas de caméra.
    // PIN = pas de caméra.
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

    setState(() {
      _isProcessing = true;
    });

    await _stopScanner();

    debugPrint('========================================');
    debugPrint('QR EMPLOYE DETECTE');
    debugPrint('VALUE : $value');
    debugPrint('========================================');

    // ==========================================================
    // TODO : APPEL API LARAVEL
    // ==========================================================
    //
    // Exemple :
    //
    // final result = await attendanceService.checkInWithQr(
    //   employeeQr: value,
    // );
    //
    // Puis :
    //
    // await _showAttendanceResult(
    //   success: result.success,
    //   employeeName: result.employeeName,
    //   message: result.message,
    // );
    //
    // ==========================================================

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    await _showAttendanceResult(
      success: true,
      employeeName: 'Employé',
      message: 'Pointage enregistré avec succès.',
    );
  }

  // ============================================================
  // SUBMIT PIN
  // ============================================================

  Future<void> _submitPin() async {
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

    setState(() {
      _isProcessing = true;
    });

    // ==========================================================
    // TODO : APPEL API LARAVEL
    // ==========================================================
    //
    // Exemple :
    //
    // final result =
    //     await attendanceService.checkInWithPin(
    //   pin: _pinCode,
    // );
    //
    // ==========================================================

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _pinCode = '';
      _isProcessing = false;
    });

    await _showAttendanceResult(
      success: true,
      employeeName: 'Employé',
      message: 'Pointage enregistré avec succès.',
    );
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
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------------
                // ICON
                // ------------------------------------------------

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

                // ------------------------------------------------
                // TITRE
                // ------------------------------------------------

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

                // ------------------------------------------------
                // EMPLOYE
                // ------------------------------------------------

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

                // ------------------------------------------------
                // MESSAGE
                // ------------------------------------------------

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

                // ------------------------------------------------
                // BUTTON
                // ------------------------------------------------

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

    // Après le résultat :
    // la caméra redémarre uniquement en mode QR Employé.
    if (_selectedMode == modeEmployeeQr) {
      await _startCurrentScanner();
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
    Color color,
  ) {
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

    final isTablet = size.shortestSide >= 600;
    final isLargeScreen = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                    // ==========================================
                    // MODE 0
                    // QR DU KIOSK
                    // ==========================================

                    _buildKioskQrMode(
                      isTablet: isTablet,
                    ),

                    // ==========================================
                    // MODE 1
                    // QR EMPLOYE
                    // CAMERA
                    // ==========================================

                    _buildEmployeeQrMode(
                      isTablet: isTablet,
                    ),

                    // ==========================================
                    // MODE 2
                    // PIN
                    // ==========================================

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
          // ----------------------------------------------------
          // ICON
          // ----------------------------------------------------

          Container(
            width: isTablet ? 58 : 48,
            height: isTablet ? 58 : 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Color(0xFF20C4F4),
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          // ----------------------------------------------------
          // TITLE
          // ----------------------------------------------------

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Pointage',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'QR Code ou code PIN',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // ----------------------------------------------------
          // STATUS
          // ----------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FFF1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Color(0xFF16A34A),
                ),
                SizedBox(width: 6),
                Text(
                  'En ligne',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
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
            padding: const EdgeInsets.symmetric(
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 550,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  // ------------------------------------------------
                  // ICON
                  // ------------------------------------------------

                  Container(
                    width: isTablet ? 76 : 68,
                    height: isTablet ? 76 : 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8FF),
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

                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------

                  Text(
                    'Scannez le QR Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.w800,
                      color:
                          const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 9),

                  // ------------------------------------------------
                  // DESCRIPTION
                  // ------------------------------------------------

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Text(
                      'Scannez ce QR Code avec votre téléphone pour effectuer votre pointage.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ------------------------------------------------
                  // QR
                  // ------------------------------------------------

                  Container(
                    width: qrSize,
                    height: qrSize,
                    padding: const EdgeInsets.all(20),
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
                    child: QrImageView(
                      data: _kioskQrValue,
                      version: QrVersions.auto,
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

                  // ------------------------------------------------
                  // INSTRUCTION
                  // ------------------------------------------------

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
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  // ------------------------------------------------
                  // ICON
                  // ------------------------------------------------

                  Container(
                    width: isTablet ? 68 : 60,
                    height: isTablet ? 68 : 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8FF),
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

                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------

                  Text(
                    'Présentez votre QR Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 27 : 23,
                      fontWeight: FontWeight.w800,
                      color:
                          const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 9),

                  // ------------------------------------------------
                  // DESCRIPTION
                  // ------------------------------------------------

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 25,
                    ),
                    child: Text(
                      'Présentez le QR Code de votre carte ou de votre téléphone devant la caméra.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ------------------------------------------------
                  // CAMERA
                  // ------------------------------------------------

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

                        // Overlay sombre.
                        IgnorePointer(
                          child: CustomPaint(
                            painter:
                                _QrScannerOverlayPainter(),
                          ),
                        ),

                        // Cadre QR.
                        Center(
                          child: IgnorePointer(
                            child: SizedBox(
                              width:
                                  scanSize * .70,
                              height:
                                  scanSize * .70,
                              child:
                                  CustomPaint(
                                painter:
                                    _QrCornersPainter(),
                              ),
                            ),
                          ),
                        ),

                        // Loading.
                        if (_isProcessing)
                          Container(
                            color: Colors.black
                                .withValues(
                              alpha: .60,
                            ),
                            child: const Center(
                              child:
                                  CircularProgressIndicator(
                                color: Color(
                                  0xFF20C4F4,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // STATUS
                  // ------------------------------------------------

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
        padding: const EdgeInsets.symmetric(
          vertical: 20,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: Column(
            children: [
              // ------------------------------------------------
              // ICON
              // ------------------------------------------------

              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8FF),
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.pin_rounded,
                  size: 38,
                  color: Color(0xFF20C4F4),
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              Text(
                'Code PIN personnel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 26 : 23,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Entrez votre code PIN pour effectuer le pointage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 24),

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
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w800,
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
          fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
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
              icon: Icons.pin_rounded,
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
      behavior: HitTestBehavior.opaque,
      onTap: () => _changeMode(index),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 220),
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
                  ? const Color(0xFF111827)
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
                    ? const Color(0xFF111827)
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
      ..strokeCap =
          StrokeCap.round;

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
