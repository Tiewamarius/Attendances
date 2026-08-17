import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // 1. Déclaration de la variable au niveau de la classe (accessible partout)
  Map<String, dynamic>? _user;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user');

    if (data != null) {
      setState(() {
        // 2. On assigne la valeur décodée à la variable de classe
        _user = jsonDecode(data);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser(); // Optionnel : charger les données dès l'affichage du widget
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // 3. Vous pouvez maintenant utiliser _user ici !
        child: _user == null
            ? const Text("Aucun utilisateur chargé")
            : Text("Bienvenue ${_user!['name']}"), // Exemple d'affichage
      ),
    );
  }
}