import 'package:flutter/material.dart';

class ActivityTile extends StatelessWidget {
  final String title;
  final String date;
  final String status;

  const ActivityTile({
    super.key,
    required this.title,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.access_time),
      ),

      title: Text(title),

      subtitle: Text(date),

      trailing: Text(
        status,
        style: TextStyle(
          color: status == "Présent"
              ? Colors.green
              : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}