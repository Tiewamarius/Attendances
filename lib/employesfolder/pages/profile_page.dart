import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon profil"),
      ),

      body: ListView(
        children: const [

          SizedBox(height: 30),

          CircleAvatar(
            radius: 50,
            child: Icon(
              Icons.person,
              size: 60,
            ),
          ),

          SizedBox(height: 20),

          ListTile(
            leading: Icon(Icons.badge),
            title: Text("EMP001"),
          ),

          ListTile(
            leading: Icon(Icons.email),
            title: Text("employee@test.com"),
          ),

          ListTile(
            leading: Icon(Icons.business),
            title: Text("Département IT"),
          ),
        ],
      ),
    );
  }
}