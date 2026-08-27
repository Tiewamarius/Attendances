import 'package:attendance/models/employees/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EmployeeAttendancePage extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeAttendancePage({super.key, required this.employee});

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  // ============================================================
  // CONTROLLER CAMERA
  // ============================================================

  late final MobileScannerController _scannerController;

  // ============================================================
  // ÉTAT
  // ============================================================

  bool _showCard = true;
  bool _isScanning = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _scannerController = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ====================================================
            // CONTENU PRINCIPAL
            // ====================================================
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _showCard ? _buildMyCard(employee) : _buildScanner(),
              ),
            ),

            // ====================================================
            // SWITCHER
            // ====================================================
            _buildBottomSwitcher(),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MA CARTE
  // ============================================================

  Widget _buildMyCard(EmployeeModel employee) {
  final qrData = employee.qrToken;

  return SingleChildScrollView(
    key: const ValueKey('card'),
    physics: const BouncingScrollPhysics(),
    child: Column(
      children: [
        _buildCardHeader(),

        const SizedBox(height: 15),

        Container(
          width: 346,
          height: 600,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFB112F5),
                Color.fromARGB(255, 24, 217, 231),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(51, 76, 233, 238),
                blurRadius: 30,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: CustomPaint(
                    painter: _CardPatternPainter(),
                  ),
                ),
              ),

              Column(
                children: [
                  const SizedBox(height: 165),

                  // ==================================================
                  // QR
                  // ==================================================

                  Container(
                    width: 270,
                    height: 270,
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
                        ? const Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 70,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'QR indisponible',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 230,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle:
                                const QrDataModuleStyle(
                              dataModuleShape:
                                  QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                  ),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(
                      left: 28,
                      bottom: 25,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      // child: _buildCardLogo(),
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
  // ============================================================
  // HEADER DE LA CARTE
  // ============================================================

  Widget _buildCardHeader() {
    return SizedBox(
      height: 55,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 22),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
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

  // ============================================================
  // LOGO DE LA CARTE
  // ============================================================

  Widget _buildCardLogo() {
    return SizedBox(
      width: 90,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corps noir
          Container(
            width: 62,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(22),
            ),
          ),

          // Tête blanche
          Container(
            width: 42,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
          ),

          // Yeux
          Positioned(
            right: 13,
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7A00),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // Aile gauche
          Positioned(
            left: 0,
            child: Container(
              width: 14,
              height: 27,
              decoration: const BoxDecoration(
                color: Color(0xFFFF7A00),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
          ),

          // Aile droite
          Positioned(
            right: 0,
            child: Container(
              width: 12,
              height: 23,
              decoration: const BoxDecoration(
                color: Color(0xFFFF7A00),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCANNER
  // ============================================================

  Widget _buildScanner() {
    return Stack(
      key: const ValueKey('scanner'),
      fit: StackFit.expand,
      children: [
        // ========================================================
        // CAMERA
        // ========================================================
        MobileScanner(controller: _scannerController, onDetect: _onDetect),

        // ========================================================
        // ASSOMBRISSEMENT
        // ========================================================
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ScannerOverlayPainter()),
          ),
        ),

        // ========================================================
        // INTERFACE DU SCANNER
        // ========================================================
        SafeArea(
          child: Column(
            children: [
              // ==================================================
              // HEADER CAMERA
              // ==================================================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Fermer
                    _buildScannerButton(
                      icon: Icons.close_rounded,
                      onTap: () {
                        _showCardView();
                      },
                    ),

                    const Spacer(),

                    // Flash
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

              // ==================================================
              // ESPACE
              // ==================================================
              const Spacer(),

              // ==================================================
              // CADRE DE SCAN
              // ==================================================
              SizedBox(
                width: 320,
                height: 320,
                child: Stack(
                  children: [
                    // Cadre
                    Positioned.fill(
                      child: CustomPaint(painter: _ScannerFramePainter()),
                    ),

                    // Ligne de scan
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

              // ==================================================
              // TITRE
              // ==================================================
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

              // ==================================================
              // DESCRIPTION
              // ==================================================
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

              // ==================================================
              // ESPACE
              // ==================================================
              const Spacer(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOUTON CAMERA
  // ============================================================

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

  // ============================================================
  // DÉTECTION QR
  // ============================================================

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;

    if (value == null || value.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    debugPrint('================================');
    debugPrint('QR CODE SCANNÉ');
    debugPrint(value);
    debugPrint('================================');

    try {
      await _scannerController.stop();
    } catch (e) {
      debugPrint('Erreur arrêt scanner : $e');
    }

    if (!mounted) return;

    await _showScanResult(value);
  }

  // ============================================================
  // RESULTAT SCAN
  // ============================================================

  Future<void> _showScanResult(String value) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Color(0xFF0EA5E9),
                  size: 35,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'QR Code détecté',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    if (!mounted) return;

                    setState(() {
                      _isProcessing = false;
                    });

                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!mounted || _showCard) return;

                      try {
                        await _scannerController.start();
                      } catch (e) {
                        debugPrint('Erreur redémarrage caméra : $e');
                      }
                    });
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // AFFICHER LA CARTE
  // ============================================================

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
    });
  }

  // ============================================================
  // AFFICHER LE SCANNER
  // ============================================================

  void _showScannerView() {
    if (_showCard == false) return;

    setState(() {
      _showCard = false;
      _isScanning = true;
      _isProcessing = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _showCard) return;

      try {
        await _scannerController.start();
        debugPrint('📷 Scanner démarré');
      } catch (e) {
        debugPrint('❌ Erreur démarrage caméra : $e');
      }
    });
  }

  // ============================================================
  // SWITCHER
  // ============================================================

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
          // ======================================================
          // SCANNER
          // ======================================================
          Expanded(
            child: _buildSwitchItem(
              title: 'Scanner un code',
              icon: Icons.qr_code_scanner_rounded,
              selected: !_showCard,
              onTap: _showScannerView,
            ),
          ),

          // ======================================================
          // CARTE
          // ======================================================
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

  // ============================================================
  // ITEM SWITCH
  // ============================================================

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

// ================================================================
// MOTIF DE LA CARTE
// ================================================================

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

// ================================================================
// OVERLAY CAMERA
// ================================================================

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.38);

    final rect = Offset.zero & size;

    canvas.drawRect(rect, overlayPaint);

    // Zone transparente
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

    final clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas.saveLayer(rect, Paint());

    canvas.drawRect(rect, overlayPaint);

    canvas.drawRRect(scanRect, clearPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ================================================================
// CADRE DE SCAN
// ================================================================

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

    // ============================================================
    // HAUT GAUCHE
    // ============================================================

    final topLeft = Path();

    topLeft.moveTo(10, cornerLength);
    topLeft.lineTo(10, radius);
    topLeft.quadraticBezierTo(10, 10, radius, 10);
    topLeft.lineTo(cornerLength, 10);

    canvas.drawPath(topLeft, paint);

    // ============================================================
    // HAUT DROIT
    // ============================================================

    final topRight = Path();

    topRight.moveTo(size.width - cornerLength, 10);

    topRight.lineTo(size.width - radius, 10);

    topRight.quadraticBezierTo(size.width - 10, 10, size.width - 10, radius);

    topRight.lineTo(size.width - 10, cornerLength);

    canvas.drawPath(topRight, paint);

    // ============================================================
    // BAS GAUCHE
    // ============================================================

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

    // ============================================================
    // BAS DROIT
    // ============================================================

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

// ================================================================
// LIGNE DE SCAN ANIMÉE
// ================================================================

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
