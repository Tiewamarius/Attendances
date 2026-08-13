import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // URL de base de votre API Laravel (Modifiez l'IP selon votre environnement)
  final String baseUrl = 'http://127.0.0.1:8000/api';

  // Contrôleurs - Profil
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _profileEmailController = TextEditingController();

  // Contrôleurs - Département
  final TextEditingController _deptNameController = TextEditingController();
  final TextEditingController _deptDescController = TextEditingController();

  // Contrôleurs - Rôle
  final TextEditingController _roleNameController = TextEditingController();

  // Listes dynamiques connectées à la DB
  List<dynamic> departments = [];
  List<dynamic> roles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  // Récupérer le token d'authentification stocké lors du Login
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Assurez-vous d'avoir stocké le token sous la clé 'token'
  }

  // Charger toutes les données initiales depuis Laravel
  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchUserProfile(),
      _fetchDepartments(),
      _fetchRoles(),
    ]);
    setState(() => isLoading = false);
  }

  // --- 1. PROFIL ---
  Future<void> _fetchUserProfile() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl.me'), // Route protégée Laravel (ex: auth:sanctum)
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profileNameController.text = data['name'] ?? '';
          _profileEmailController.text = data['email'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Erreur profil: $e');
    }
  }

  Future<void> _updateProfile() async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/user/update'), // Votre route Laravel pour update le profil
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _profileNameController.text,
          'email': _profileEmailController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Profil mis à jour avec succès !', Colors.green);
      } else {
        _showSnackBar('Erreur lors de la mise à jour', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur réseau : $e', Colors.red);
    }
  }

  // --- 2. DÉPARTEMENTS ---
  Future<void> _fetchDepartments() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/departments'), // Route Laravel listant les départements
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          departments = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Erreur départements: $e');
    }
  }

  Future<void> _createDepartment() async {
    if (_deptNameController.text.isEmpty) return;

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/departments'), // Route Laravel d'insertion
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _deptNameController.text,
          'description': _deptDescController.text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _deptNameController.clear();
        _deptDescController.clear();
        _fetchDepartments(); // Recharger la liste
        _showSnackBar('Département ajouté avec succès !', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Erreur : $e', Colors.red);
    }
  }

  Future<void> _deleteDepartment(int id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/departments/$id'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        _fetchDepartments();
        _showSnackBar('Département supprimé', Colors.orange);
      }
    } catch (e) {
      debugPrint('Erreur suppression: $e');
    }
  }

  // --- 3. RÔLES (Spatie) ---
  Future<void> _fetchRoles() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/roles'), // Route Laravel pour récupérer les rôles Spatie
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          roles = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Erreur rôles: $e');
    }
  }

  Future<void> _createRole() async {
    if (_roleNameController.text.isEmpty) return;

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/roles'), // Route Laravel Spatie pour créer un rôle
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'name': _roleNameController.text}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _roleNameController.clear();
        _fetchRoles();
        _showSnackBar('Rôle Spatie créé avec succès !', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Erreur : $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _profileNameController.dispose();
    _profileEmailController.dispose();
    _deptNameController.dispose();
    _deptDescController.dispose();
    _roleNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0078D4);
    const Color bgLight = Color(0xFFF3F2F1);
    const Color textDark = Color(0xFF201F1E);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Paramètres d\'administration', style: TextStyle(color: textDark)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: textDark),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Éditer Profil'),
            Tab(icon: Icon(Icons.apartment), text: 'Gestion Départements'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Gestion Rôles'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // --- ONGLET 1 : PROFIL ---
                _buildSectionContainer(
                  title: 'Modifier les informations du profil',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _profileNameController,
                        decoration: InputDecoration(labelText: 'user[\'name\']', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.badge)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _profileEmailController,
                        decoration: const InputDecoration(labelText: 'user[\'email\']', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        onPressed: _updateProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer les modifications'),
                      ),
                    ],
                  ),
                ),

                // --- ONGLET 2 : DÉPARTEMENTS ---
                _buildSectionContainer(
                  title: 'Ajouter un nouveau département',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _deptNameController,
                        decoration: const InputDecoration(labelText: 'Nom du département', border: OutlineInputBorder(), prefixIcon: Icon(Icons.domain)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _deptDescController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Description (optionnel)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        onPressed: _createDepartment,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter le département'),
                      ),
                      const Divider(height: 40),
                      const Text('Départements existants :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: departments.length,
                          itemBuilder: (context, index) {
                            final dept = departments[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.apartment, color: primaryColor),
                                title: Text(dept['name'] ?? ''),
                                subtitle: Text(dept['description'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteDepartment(dept['id']),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // --- ONGLET 3 : RÔLES ---
                _buildSectionContainer(
                  title: 'Créer un nouveau rôle (Spatie)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _roleNameController,
                        decoration: const InputDecoration(labelText: 'Nom du rôle (ex: manager, comptable)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.security)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        onPressed: _createRole,
                        icon: const Icon(Icons.verified_user),
                        label: const Text('Créer le rôle'),
                      ),
                      const Divider(height: 40),
                      const Text('Rôles système disponibles :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: roles.length,
                          itemBuilder: (context, index) {
                            final role = roles[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.lock_outline, color: primaryColor),
                                title: Text(role['name'] ?? ''),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionContainer({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF201F1E))),
              const Divider(height: 24),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}