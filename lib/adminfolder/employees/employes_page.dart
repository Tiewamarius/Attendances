import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/network/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<Map<String, dynamic>> employees = [];
  bool isLoading = true;

  String selectedFilter = 'Toutes';
  int? selectedIndex;

  // Contrôleurs pour correspondre aux champs de la table employees
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- MÉTHODE POUR RÉCUPÉRER LES EMPLOYÉS DEPUIS LARAVEL ---
  Future<void> fetchEmployees() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse(ApiConfig.employees), // Remplacez par votre URL d'API
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> fetchedList = data is List
            ? data
            : (data['data'] ?? []);

        setState(() {
          employees = fetchedList.map((emp) {
            final fName = emp['first_name'] ?? '';
            final lName = emp['last_name'] ?? '';
            return {
              'employee_code': emp['employee_code'] ?? '',
              'first_name': fName,
              'last_name': lName,
              'position': emp['position'] ?? 'Non spécifié',
              'phone': emp['phone'] ?? '',
              'message': 'Connecté',
              'time': 'Aujourd\'hui',
              'avatar': emp['avatar'],
              'initial':
                  '${fName.isNotEmpty ? fName[0] : ""}${lName.isNotEmpty ? lName[0] : ""}'
                      .toUpperCase(),
              'status': 'Present',
              'unread': false,
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAddEmployeeModal() {
    _codeController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _positionController.clear();
    _phoneController.clear();
    _emailController.clear();
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Ajouter un employé',
            style: TextStyle(color: Color(0xFF201F1E), fontSize: 18),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Matricule RH (employee_code) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom (first_name) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom (last_name) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (requis pour le compte) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe (min. 8 caractères) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _positionController,
                    decoration: const InputDecoration(
                      labelText: 'Poste (position)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone (phone)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Color(0xFF605E5C)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0078D4),
              ),
              onPressed: () async {
                // Validation basique avant l'envoi
                if (_firstNameController.text.isNotEmpty &&
                    _lastNameController.text.isNotEmpty &&
                    _emailController.text.isNotEmpty &&
                    _passwordController.text.isNotEmpty &&
                    _codeController.text.isNotEmpty) {
                  try {
                    final token = await AuthService.getToken();

                    final response = await http.post(
                      Uri.parse(ApiConfig.employees),
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({
                        'employee_code': _codeController.text,
                        'first_name': _firstNameController.text,
                        'last_name': _lastNameController.text,
                        'email': _emailController.text,
                        'password': _passwordController.text,
                        'position': _positionController.text,
                        'phone': _phoneController.text,
                      }),
                    );

                    if (response.statusCode == 201 ||
                        response.statusCode == 200) {
                      final responseData = jsonDecode(response.body);
                      
                      // Récupération du PIN temporaire renvoyé par Laravel
                      final temporaryPin = responseData['data']?['temporary_pin'];

                      Navigator.pop(context); // Fermer le modal d'ajout
                      fetchEmployees(); // Rafraîchir la liste

                      // Afficher le code PIN temporaire généré par le serveur
                      if (temporaryPin != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Employé créé avec succès'),
                            content: Text(
                              'Le code PIN temporaire de l\'employé est : $temporaryPin\n\nNotez-le bien, il ne sera plus affiché.',
                              style: const TextStyle(fontSize: 16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    } else {
                      // Afficher une erreur si Laravel retourne un échec de validation (ex: email déjà pris)
                      final errorData = jsonDecode(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorData)),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur de connexion au serveur')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                  );
                }
              },
              child: const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onEmployeeTap(int index, bool isDesktop) {
    setState(() {
      selectedIndex = index;
    });

    if (!isDesktop) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(20),
          child: _buildEmployeeDetailsContent(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgLight = Color(0xFFF3F2F1);
    const Color panelLight = Color(0xFFFFFFFF);
    const Color textDark = Color(0xFF201F1E);
    const Color textGrey = Color(0xFF605E5C);
    const Color accentBlue = Color(0xFF0078D4);
    const Color hoverColor = Color(0xFFEDEBE9);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 850;

        return Row(
          children: [
            // --- COLONNE DE GAUCHE : LISTE DES EMPLOYÉS ---
            Container(
              width: isDesktop ? 300 : constraints.maxWidth,
              decoration: BoxDecoration(
                color: panelLight,
                border: isDesktop
                    ? const Border(
                        right: BorderSide(color: Color(0xFFEDEBE9), width: 1),
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Employés',
                              style: TextStyle(
                                color: textDark,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.person_add_outlined,
                                    color: textGrey,
                                  ),
                                  tooltip: 'Ajouter un employé',
                                  onPressed: _showAddEmployeeModal,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: textGrey,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Barre de recherche
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF8A8886)),
                        ),
                        child: const TextField(
                          style: TextStyle(color: textDark, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un employé...',
                            hintStyle: TextStyle(color: textGrey, fontSize: 13),
                            prefixIcon: Icon(
                              Icons.search,
                              color: textGrey,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Liste
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : employees.isEmpty
                          ? const Center(child: Text('Aucun employé trouvé'))
                          : ListView.builder(
                              itemCount: employees.length,
                              itemBuilder: (context, index) {
                                final emp = employees[index];
                                final isSelected = selectedIndex == index;
                                final fullName =
                                    "${emp['first_name']} ${emp['last_name']}";

                                return InkWell(
                                  onTap: () => _onEmployeeTap(index, isDesktop),
                                  child: Container(
                                    color: isSelected && isDesktop
                                        ? hoverColor
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: accentBlue
                                              .withOpacity(0.2),
                                          backgroundImage: emp['avatar'] != null
                                              ? NetworkImage(emp['avatar'])
                                              : null,
                                          child: emp['avatar'] == null
                                              ? Text(
                                                  emp['initial'] ?? '?',
                                                  style: const TextStyle(
                                                    color: accentBlue,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      fullName,
                                                      style: const TextStyle(
                                                        color: textDark,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    emp['time'],
                                                    style: TextStyle(
                                                      color: emp['unread']
                                                          ? accentBlue
                                                          : textGrey,
                                                      fontSize: 12,
                                                      fontWeight: emp['unread']
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                emp['message'],
                                                style: const TextStyle(
                                                  color: textGrey,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // --- PANNEAU DE DROITE : DETAILS (UNIQUEMENT SUR GRAND ÉCRAN) ---
            if (isDesktop)
              Expanded(
                child: Container(
                  color: bgLight,
                  padding: const EdgeInsets.all(9),
                  child: selectedIndex == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 48,
                                color: textGrey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Sélectionnez un employé pour voir ses détails de pointage',
                                style: TextStyle(color: textGrey, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          color: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: _buildEmployeeDetailsContent(),
                          ),
                        ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmployeeDetailsContent() {
    if (selectedIndex == null) return const SizedBox.shrink();

    const Color textDark = Color(0xFF201F1E);
    const Color textGrey = Color(0xFF605E5C);
    const Color accentBlue = Color(0xFF0078D4);

    final emp = employees[selectedIndex!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: accentBlue.withOpacity(0.2),
              backgroundImage: emp['avatar'] != null
                  ? NetworkImage(emp['avatar'])
                  : null,
              child: emp['avatar'] == null
                  ? Text(
                      emp['initial'] ?? '?',
                      style: const TextStyle(
                        color: accentBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${emp['first_name']} ${emp['last_name']}",
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Matricule : ${emp['employee_code']} | Poste : ${emp['position']}',
                    style: const TextStyle(color: textGrey, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 40, color: Color(0xFFEDEBE9)),
        const Text(
          'Informations de pointage récent',
          style: TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.access_time, color: accentBlue),
          title: const Text('Détail / Message'),
          subtitle: Text(emp['message']),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone, color: accentBlue),
          title: const Text('Téléphone'),
          subtitle: Text(emp['phone'] ?? 'Non renseigné'),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier le statut'),
            ),
          ],
        ),
      ],
    );
  }
}
