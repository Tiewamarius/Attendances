import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // ============================================================
  // MODE
  // ============================================================

  int _selectedMode = 0;

  // ============================================================
  // PIN
  // ============================================================

  String _pinCode = '';

  // ============================================================
  // SCANNERS
  // ============================================================

  late final MobileScannerController _backScannerController;
  late final MobileScannerController _frontScannerController;

  // ============================================================
  // ÉTAT
  // ============================================================

  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();

    _backScannerController = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    _frontScannerController = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.front,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCurrentScanner();
    });
  }

  @override
  void dispose() {
    _backScannerController.dispose();
    _frontScannerController.dispose();

    super.dispose();
  }

  // ============================================================
  // CHANGER DE MODE
  // ============================================================

  Future<void> _changeMode(int mode) async {
    if (_selectedMode == mode) return;

    await _stopScanners();

    if (!mounted) return;

    setState(() {
      _selectedMode = mode;
      _pinCode = '';
      _isProcessing = false;
      _isSuccess = false;
    });

    if (mode == 0 || mode == 1) {
      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;

      await _startCurrentScanner();
    }
  }

  // ============================================================
  // START SCANNER
  // ============================================================

  Future<void> _startCurrentScanner() async {
    try {
      if (_selectedMode == 0) {
        await _backScannerController.start();
      } else if (_selectedMode == 1) {
        await _frontScannerController.start();
      }
    } catch (e) {
      debugPrint('Erreur démarrage scanner : $e');
    }
  }

  // ============================================================
  // STOP SCANNERS
  // ============================================================

  Future<void> _stopScanners() async {
    try {
      await _backScannerController.stop();
    } catch (_) {}

    try {
      await _frontScannerController.stop();
    } catch (_) {}
  }

  // ============================================================
  // QR DÉTECTÉ
  // ============================================================

  Future<void> _onDetectQr(
    BarcodeCapture capture,
    String mode,
  ) async {
    if (_isProcessing) return;

    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;

    final value = barcode.rawValue?.trim();

    if (value == null || value.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    await _stopScanners();

    debugPrint('================================');
    debugPrint('QR DÉTECTÉ');
    debugPrint('MODE : $mode');
    debugPrint('VALUE : $value');
    debugPrint('================================');

    // ==========================================================
    // TODO :
    // APPEL API LARAVEL
    // ==========================================================

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    await _showAttendanceResult(
      success: true,
      employeeName: 'Employé',
      message: 'Pointage enregistré avec succès.',
    );
  }

  // ============================================================
  // PIN
  // ============================================================

  Future<void> _submitPin() async {
    if (_pinCode.length < 4) {
      _showMessage(
        'Veuillez entrer un code PIN valide.',
        Colors.orange,
      );
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // ==========================================================
    // TODO :
    // APPEL API LARAVEL
    // ==========================================================

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

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
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
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
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 26),

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

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isSuccess = false;
    });

    await _startCurrentScanner();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isTablet),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40 : 16,
                  vertical: 12,
                ),
                child: IndexedStack(
                  index: _selectedMode,
                  children: [
                    _buildQrMode(
                      controller: _backScannerController,
                      title: 'Présentez votre téléphone',
                      description:
                          'Placez le QR Code de votre carte devant le lecteur.',
                      modeName: 'QR téléphone',
                    ),
                    _buildQrMode(
                      controller: _frontScannerController,
                      title: 'Présentez votre badge',
                      description:
                          'Placez votre badge QR devant la caméra.',
                      modeName: 'Badge QR',
                    ),
                    _buildPinMode(isTablet),
                  ],
                ),
              ),
            ),

            _buildModeSelector(isTablet),

            SizedBox(
              height: isTablet ? 30 : 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isTablet) {
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Color(0xFF20C4F4),
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Présentez votre QR ou saisissez votre PIN',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

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
  // QR MODE
  // ============================================================

  Widget _buildQrMode({
    required MobileScannerController controller,
    required String title,
    required String description,
    required String modeName,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxWidth < 420
            ? constraints.maxWidth * .72
            : 320.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
              ),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: scanSize,
              height: scanSize,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      _onDetectQr(
                        capture,
                        modeName,
                      );
                    },
                  ),

                  IgnorePointer(
                    child: CustomPaint(
                      painter: _QrScannerOverlayPainter(),
                    ),
                  ),

                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: scanSize * .72,
                          height: scanSize * .72,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF20C4F4),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 19,
                  color: Color(0xFF20C4F4),
                ),
                SizedBox(width: 8),
                Text(
                  'Lecture automatique',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PIN
  // ============================================================

  Widget _buildPinMode(bool isTablet) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 430,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.pin_rounded,
                size: 48,
                color: Color(0xFF20C4F4),
              ),

              const SizedBox(height: 14),

              const Text(
                'Code PIN personnel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Entrez votre code PIN pour effectuer le pointage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
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
                    color: Color(0xFF111827),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isTablet ? 1.7 : 1.45,
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
                    color: const Color(0xFF16A34A),
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
  // KEYPAD
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
                if (_pinCode.length >= 6) return;

                setState(() {
                  _pinCode += text;
                });
              },
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.white,
        foregroundColor: textColor ?? const Color(0xFF111827),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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

  void _deletePin() {
    if (_pinCode.isEmpty) return;

    setState(() {
      _pinCode =
          _pinCode.substring(0, _pinCode.length - 1);
    });
  }

  // ============================================================
  // SELECTEUR
  // ============================================================

  Widget _buildModeSelector(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 16,
      ),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              index: 0,
              icon: Icons.phone_iphone_rounded,
              label: 'Téléphone',
            ),
          ),
          Expanded(
            child: _buildModeButton(
              index: 1,
              icon: Icons.badge_outlined,
              label: 'Badge',
            ),
          ),
          Expanded(
            child: _buildModeButton(
              index: 2,
              icon: Icons.pin_rounded,
              label: 'PIN',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _selectedMode == index;

    return GestureDetector(
      onTap: () => _changeMode(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              style: TextStyle(
                fontSize: 12,
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
// OVERLAY QR
// ================================================================

class _QrScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: .45);

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