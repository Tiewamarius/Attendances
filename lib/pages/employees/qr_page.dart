import 'package:flutter/material.dart';

class QrPage extends StatelessWidget {
  const QrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon QR Code"),
      ),

      body: const Center(
        child: Icon(
          Icons.qr_code_2,
          size: 250,
        ),
      ),
    );
  }
}