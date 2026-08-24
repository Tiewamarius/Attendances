import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EmployeeQrScannerPage extends StatefulWidget {
  const EmployeeQrScannerPage({
    super.key,
  });

  @override
  State<EmployeeQrScannerPage> createState() =>
      _EmployeeQrScannerPageState();
}

class _EmployeeQrScannerPageState
    extends State<EmployeeQrScannerPage> {
  final MobileScannerController _controller =
      MobileScannerController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isEmpty) return;

    final String? value = barcodes.first.rawValue;

    if (value == null || value.isEmpty) return;

    _isProcessing = true;

    // Arrête la caméra
    _controller.stop();

    // Retourne le code scanné à la page précédente
    Navigator.pop(context, value);
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
                        onTap: () {
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

                // CADRE DE SCAN
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
                      // Coins
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

                      // Ligne centrale
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

                // BOUTON FLASH
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 40,
                  ),
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
      width: 35,
      height: 35,
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