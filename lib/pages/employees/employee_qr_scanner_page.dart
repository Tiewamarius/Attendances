import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EmployeeQrScannerPage extends StatefulWidget {
  const EmployeeQrScannerPage({super.key});

  @override
  State<EmployeeQrScannerPage> createState() =>
      _EmployeeQrScannerPageState();
}

class _EmployeeQrScannerPageState
    extends State<EmployeeQrScannerPage>
    with WidgetsBindingObserver {

  late final MobileScannerController _controller;

  bool _isProcessing = false;
  bool _cameraStarted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      autoStart: true,
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_cameraStarted && !_isProcessing) {
          _startCamera();
        }
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopCamera();
        break;
    }
  }

  Future<void> _startCamera() async {
    if (_cameraStarted || _isProcessing) return;

    try {
      await _controller.start();

      if (mounted) {
        setState(() {
          _cameraStarted = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur démarrage caméra : $e');
    }
  }

  Future<void> _stopCamera() async {
    if (!_cameraStarted) return;

    try {
      await _controller.stop();
    } catch (e) {
      debugPrint('Erreur arrêt caméra : $e');
    }

    _cameraStarted = false;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    if (capture.barcodes.isEmpty) return;

    final String? value = capture.barcodes.first.rawValue;

    if (value == null || value.trim().isEmpty) return;

    _isProcessing = true;

    debugPrint('====================================');
    debugPrint('QR CODE DETECTE');
    debugPrint('VALUE: $value');
    debugPrint('====================================');

    await _stopCamera();

    if (!mounted) return;

    Navigator.pop(context, value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [

          // =====================================================
          // CAMERA
          // =====================================================

          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // =====================================================
          // OVERLAY
          // =====================================================

          SafeArea(
            child: Column(
              children: [

                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),

                  child: Row(
                    children: [

                      GestureDetector(
                        onTap: () async {
                          await _stopCamera();

                          if (!mounted) return;

                          Navigator.pop(context);
                        },

                        child: Container(
                          width: 45,
                          height: 45,

                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.45,
                            ),
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),

                      const Expanded(
                        child: Center(
                          child: Text(
                            'Scanner un code',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 45),
                    ],
                  ),
                ),

                const Spacer(),

                // =================================================
                // CADRE
                // =================================================

                Container(
                  width: 280,
                  height: 280,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),

                  child: Stack(
                    children: [

                      Positioned(
                        top: -3,
                        left: -3,
                        child: _corner(),
                      ),

                      Positioned(
                        top: -3,
                        right: -3,
                        child: Transform.rotate(
                          angle: 1.5708,
                          child: _corner(),
                        ),
                      ),

                      Positioned(
                        bottom: -3,
                        left: -3,
                        child: Transform.rotate(
                          angle: -1.5708,
                          child: _corner(),
                        ),
                      ),

                      Positioned(
                        bottom: -3,
                        right: -3,
                        child: Transform.rotate(
                          angle: 3.14159,
                          child: _corner(),
                        ),
                      ),

                      Center(
                        child: Container(
                          height: 2,
                          width: 230,
                          color: const Color(0xFF20C4F4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                const Text(
                  'Placez le QR Code dans le cadre',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Le scan se fera automatiquement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const Spacer(),

                // FLASH
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),

                  child: GestureDetector(
                    onTap: () {
                      _controller.toggleTorch();
                    },

                    child: Container(
                      width: 58,
                      height: 58,

                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.flashlight_on_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner() {
    return Container(
      width: 30,
      height: 30,

      decoration: const BoxDecoration(
        color: Color(0xFF20C4F4),

        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomRight: Radius.circular(10),
        ),
      ),
    );
  }
}