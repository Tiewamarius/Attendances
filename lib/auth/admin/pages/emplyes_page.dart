import 'package:flutter/material.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final List<Map<String, dynamic>> employees = [
    {
      'employee_code': 'EMP001',
      'first_name': 'Herman',
      'last_name': 'Koffi',
      'position': 'Administrateur Système Cloud',
      'phone': '+225 0102030405',
      'message': 'Présent - Arrivé à 08:02',
      'time': '08:02',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      'status': 'Present',
      'unread': false,
    },
    {
      'employee_code': 'EMP002',
      'first_name': 'Marius',
      'last_name': 'Yoboue',
      'position': 'Développeur Supp. Technique',
      'phone': '+225 0708091011',
      'message': 'En retard - Arrivé à 09:15',
      'time': '09:15',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'status': 'Late',
      'unread': true,
    },
    {
      'employee_code': 'EMP003',
      'first_name': 'Ange Marie',
      'last_name': 'Kouadio',
      'position': 'Assistante',
      'phone': '+225 0504030201',
      'message': 'Absent (Congé validé)',
      'time': 'Hier',
      'avatar': null,
      'initial': 'AM',
      'status': 'Leave',
      'unread': false,
    },
  ];

  String selectedFilter = 'Toutes';
  int? selectedIndex;

  // Contrôleurs pour correspondre aux champs de la table employees Laravel
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _showAddEmployeeModal() {
    _codeController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _positionController.clear();
    _phoneController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un employé', style: TextStyle(color: Color(0xFF201F1E), fontSize: 18)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Matricule RH (employee_code)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom (first_name)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom (last_name)',
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
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF605E5C))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0078D4)),
              onPressed: () {
                if (_firstNameController.text.isNotEmpty && _lastNameController.text.isNotEmpty) {
                  setState(() {
                    String fName = _firstNameController.text;
                    String lName = _lastNameController.text;
                    employees.add({
                      'employee_code': _codeController.text.isNotEmpty ? _codeController.text : 'EMP${employees.length + 1}',
                      'first_name': fName,
                      'last_name': lName,
                      'position': _positionController.text,
                      'phone': _phoneController.text,
                      'message': 'En attente de pointage',
                      'time': 'Aujourd\'hui',
                      'avatar': null,
                      'initial': '${fName.isNotEmpty ? fName[0] : ""}${lName.isNotEmpty ? lName[0] : ""}'.toUpperCase(),
                      'status': 'Pending',
                      'unread': true,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgLight = Color(0xFFF3F2F1);      
    const Color panelLight = Color(0xFFFFFFFF);   
    const Color textDark = Color(0xFF201F1E);     
    const Color textGrey = Color(0xFF605E5C);     
    const Color accentBlue = Color(0xFF0078D4);   
    const Color hoverColor = Color(0xFFEDEBE9);   

    return Row(
      children: [
        // --- COLONNE DE GAUCHE : LISTE DES EMPLOYÉS ---
        Container(
          width: 380,
          decoration: const BoxDecoration(
            color: panelLight,
            border: Border(right: BorderSide(color: Color(0xFFEDEBE9), width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Présences Employés',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_add_outlined, color: textGrey),
                          tooltip: 'Ajouter un employé',
                          onPressed: _showAddEmployeeModal,
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: textGrey),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Barre de recherche
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF8A8886)),
                  ),
                  child: TextField(
                    style: const TextStyle(color: textDark, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un employé...',
                      hintStyle: const TextStyle(color: textGrey, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: textGrey, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),

              // Filtres
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('Toutes', accentBlue, Colors.white),
                    const SizedBox(width: 8),
                    _buildFilterChip('Présents', bgLight, textGrey),
                    const SizedBox(width: 8),
                    _buildFilterChip('Absents', bgLight, textGrey),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Liste
              Expanded(
                child: ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final emp = employees[index];
                    final isSelected = selectedIndex == index;
                    final fullName = "${emp['first_name']} ${emp['last_name']}";

                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: Container(
                        color: isSelected ? hoverColor : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: accentBlue.withOpacity(0.2),
                              backgroundImage: emp['avatar'] != null ? NetworkImage(emp['avatar']) : null,
                              child: emp['avatar'] == null
                                  ? Text(
                                      emp['initial'] ?? '?',
                                      style: const TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          fullName,
                                          style: const TextStyle(
                                            color: textDark,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        emp['time'],
                                        style: TextStyle(
                                          color: emp['unread'] ? accentBlue : textGrey,
                                          fontSize: 12,
                                          fontWeight: emp['unread'] ? FontWeight.bold : FontWeight.normal,
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

        // --- PANNEAU DE DROITE : DETAILS DE L'EMPLOYÉ SÉLECTIONNÉ ---
        Expanded(
          child: Container(
            color: bgLight,
            padding: const EdgeInsets.all(32),
            child: selectedIndex == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.touch_app_outlined, size: 48, color: textGrey),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: accentBlue.withOpacity(0.2),
                                backgroundImage: employees[selectedIndex!]['avatar'] != null 
                                    ? NetworkImage(employees[selectedIndex!]['avatar']) 
                                    : null,
                                child: employees[selectedIndex!]['avatar'] == null
                                    ? Text(
                                        employees[selectedIndex!]['initial'] ?? '?',
                                        style: const TextStyle(color: accentBlue, fontSize: 20, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${employees[selectedIndex!]['first_name']} ${employees[selectedIndex!]['last_name']}",
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Matricule : ${employees[selectedIndex!]['employee_code']} | Poste : ${employees[selectedIndex!]['position']}',
                                    style: TextStyle(
                                      color: textGrey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 40, color: Color(0xFFEDEBE9)),
                          const Text(
                            'Informations de pointage récent',
                            style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.access_time, color: accentBlue),
                            title: const Text('Détail / Message'),
                            subtitle: Text(employees[selectedIndex!]['message']),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.phone, color: accentBlue),
                            title: const Text('Téléphone'),
                            subtitle: Text(employees[selectedIndex!]['phone'] ?? 'Non renseigné'),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end, // Corrigé ici
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  // Action de modification
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Modifier le statut'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3), 
        border: Border.all(color: const Color(0xFFC8C6C4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}