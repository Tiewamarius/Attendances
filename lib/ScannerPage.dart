import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class MyCardPage extends StatefulWidget {
  const MyCardPage({super.key});

  @override
  State<MyCardPage> createState() => _MyCardPageState();
}

class _MyCardPageState extends State<MyCardPage> {
  bool showCard = true;

  String? scannedValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Bouton fermer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 34, color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Carte
            Expanded(
              child: Center(
                child: Container(
                  width: 300,
                  height: 500,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 144, 147, 148),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      /// QR Code
                      Center(child: showCard ? _employeeCard() : _scanner()),

                      /// Logo
                      // Positioned(
                      //   left: 18,
                      //   bottom: 18,
                      //   child: Image.asset("assets/images/logo.png", width: 55),
                      // ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Sélecteur
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            showCard = false;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: !showCard
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: const Center(
                            child: Text(
                              "Scanner un code",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            showCard = true;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: showCard ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: const Center(
                            child: Text(
                              "Ma carte",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }


  
Widget _employeeCard() {
  return Container(
    width: 300,
    height: 500,
    decoration: BoxDecoration(
      color: const Color(0xFF909394),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(child: QrImageView(data: "EMPLOYE_001", size: 190)),
      ),
    ),
  );
}

Widget _scanner() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: SizedBox(
      width: 300,
      height: 500,
      child: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.first;

              if (barcode.rawValue != null) {
                setState(() {
                  scannedValue = barcode.rawValue!;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("QR : ${barcode.rawValue}")),
                );
              }
            },
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(12),
              child: Text(
                scannedValue ?? "Scannez un QR Code",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

}
