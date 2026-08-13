import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // 0: Mon QR Code (Scanner fixe), 1: Caméra Frontale (Badge), 2: Code PIN
  int _selectedMode = 0;

  // Contrôleur pour le code PIN
  String _pinCode = '';

  // Contrôleur pour le scanner (si besoin d'actions spécifiques)
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // Action lorsqu'un code PIN est complété
  void _onPinSubmit() {
    if (_pinCode.length < 4) {
      _showSnackBar("Veuillez entrer un code PIN valide.", Colors.orange);
      return;
    }
    
    // TODO: Envoyer _pinCode vers votre API Laravel
    _showSnackBar("Pointage réussi avec le PIN : $_pinCode", Colors.green);
    setState(() {
      _pinCode = '';
    });
  }

  // Action lorsqu'un QR Code est détecté par la caméra
  void _onDetectQr(BarcodeCapture capture, String modeName) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        // TODO: Envoyer `code` vers votre API Laravel selon le mode
        _showSnackBar("Pointage ($modeName) validé pour : $code", Colors.green);
        break; // Traiter un seul code pour éviter les doublons
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Borne de Pointage"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // --- TOGGLE / SÉLECTEUR DE MODE ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildToggleButton(0, "Mon QR", Icons.phone_iphone)),
                  Expanded(child: _buildToggleButton(1, "Badge QR", Icons.camera_front)),
                  Expanded(child: _buildToggleButton(2, "Code PIN", Icons.pin)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- CONTENU AFFICHÉ SELON LE MODE CHOISI ---
          Expanded(
            child: IndexedStack(
              index: _selectedMode,
              children: [
                _buildMobileQrScannerView(),
                _buildFrontCameraScannerView(),
                _buildPinCodeView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget personnalisé pour un bouton du Toggle
  Widget _buildToggleButton(int index, String label, IconData icon) {
    final bool isSelected = _selectedMode == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = index;
          _pinCode = ''; // Réinitialiser le PIN si on change d'onglet
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MODE 0 : Scanner le QR code de l'employé (Caméra arrière de la borne)
  Widget _buildMobileQrScannerView() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Présentez votre smartphone (QR Code personnel) devant le lecteur", 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                // cameraFacing: CameraFacing.back, // Par défaut arrière
                onDetect: (capture) => _onDetectQr(capture, "Mobile QR"),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // MODE 1 : Caméra Frontale pour badge QR physique
  Widget _buildFrontCameraScannerView() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Présentez votre badge physique face à la caméra frontale", 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                controller: MobileScannerController(facing: CameraFacing.front),
                onDetect: (capture) => _onDetectQr(capture, "Badge Frontal"),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // MODE 2 : Clavier Code PIN
  Widget _buildPinCodeView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Entrez votre Code PIN personnel", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Affichage des points masqués
          Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(255, 101, 103, 105), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _pinCode.isEmpty ? "----" : _pinCode.replaceAll(RegExp(r'.'), '•'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),
          // Pavé Numérique (Keypad)
          SizedBox(
            width: double.infinity,
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 1; i <= 9; i++) _buildKeypadButton(i.toString()),
                _buildKeypadButton("⌫", onTap: () {
                  if (_pinCode.isNotEmpty) {
                    setState(() {
                      _pinCode = _pinCode.substring(0, _pinCode.length - 1);
                    });
                  }
                }),
                _buildKeypadButton("0"),
                _buildKeypadButton("✔", color: Colors.green, textColor: Colors.white, onTap: _onPinSubmit),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bouton individuel du pavé numérique
  Widget _buildKeypadButton(String text, {Color? color, Color? textColor, VoidCallback? onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.grey[100],
        foregroundColor: textColor ?? Colors.black87,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap ?? () {
        if (_pinCode.length < 6) { // Limite maximale de sécurité par exemple
          setState(() {
            _pinCode += text;
          });
        }
      },
      child: Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }
}