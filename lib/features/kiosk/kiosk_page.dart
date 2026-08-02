import 'package:flutter/material.dart';

class KioskPage extends StatefulWidget {
  const KioskPage({super.key});

  @override
  State<KioskPage> createState() => _KioskPageState();
}

class _KioskPageState extends State<KioskPage> {
  int selectedMode = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isTablet = width >= 600;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showPinDialog();
        },

        icon: const Icon(Icons.pin),

        label: const Text("PIN"),
      ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 80 : 25,

            vertical: 25,
          ),

          child: Column(
            children: [
              _header(),

              const SizedBox(height: 40),

              ToggleButtons(
                borderRadius: BorderRadius.circular(15),

                isSelected: [selectedMode == 0, selectedMode == 1],

                onPressed: (index) {
                  setState(() {
                    selectedMode = index;
                  });
                },

                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25),

                    child: Row(
                      children: [
                        Icon(Icons.qr_code_scanner),

                        SizedBox(width: 10),

                        Text("Scanner Code"),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25),

                    child: Row(
                      children: [
                        Icon(Icons.qr_code),

                        SizedBox(width: 10),

                        Text("QR Code"),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              Expanded(child: _scannerZone(isTablet)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 45,

          child: Icon(Icons.fingerprint, size: 50),
        ),

        const SizedBox(height: 20),

        const Text(
          "ATTENDANCE",

          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Text(
          "Présentez votre badge ou QR Code",

          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _scannerZone(bool tablet) {
    return Container(
      width: tablet ? 500 : double.infinity,

      decoration: BoxDecoration(
        color: Colors.black12,

        borderRadius: BorderRadius.circular(30),

        border: Border.all(color: Colors.grey, width: 2),
      ),

      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(
              selectedMode == 0 ? Icons.qr_code_scanner : Icons.qr_code,

              size: 100,

              color: Colors.blue,
            ),

            const SizedBox(height: 25),

            Text(
              selectedMode == 0
                  ? "Scanner votre code"
                  : "Placez le QR devant la caméra",

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 15),

            const Text("Caméra active", style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }

  void _showPinDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Code PIN"),

          content: TextField(
            controller: controller,

            keyboardType: TextInputType.number,

            obscureText: true,

            decoration: const InputDecoration(
              hintText: "Entrer votre PIN",

              prefixIcon: Icon(Icons.lock),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Annuler"),
            ),

            ElevatedButton(
              onPressed: () {
                final pin = controller.text;

                // Appel API ici

                // /kiosk/check-pin

                Navigator.pop(context);
              },

              child: const Text("Valider"),
            ),
          ],
        );
      },
    );
  }
}
