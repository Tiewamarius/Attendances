import 'package:flutter/material.dart';

class QrCard extends StatelessWidget {
  const QrCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF06B6D4),
          ],
        ),
      ),

      child: Column(
        children: [

          Image.network(
            'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=EMP001',
            height: 180,
          ),

          const SizedBox(height: 10),

          const Text(
            "Scanner pour pointer",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }
}