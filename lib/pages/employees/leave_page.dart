import 'package:flutter/material.dart';

class LeavePage extends StatelessWidget {
  const LeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes congés"),
      ),

      body: const Center(
        child: Text(
          "Aucun congé en cours",
        ),
      ),
    );
  }
}