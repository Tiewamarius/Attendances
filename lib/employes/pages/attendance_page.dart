import 'package:flutter/material.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique présence"),
      ),

      body: ListView.builder(
        itemCount: 30,

        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.calendar_month),

            title: Text("Jour ${index + 1}"),

            subtitle: const Text("08:00 - 17:30"),
          );
        },
      ),
    );
  }
}