import 'package:attendance/models/model_department.dart';
import 'package:attendance/models/model_kiosk.dart';
import 'package:attendance/models/model_roles.dart';
import 'package:attendance/models/users/user_model.dart';
import 'package:attendance/services/admin_service.dart';
import 'package:attendance/services/kiosk_service.dart';
import 'package:flutter/material.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _profileNameController = TextEditingController();

  final TextEditingController _profileEmailController = TextEditingController();

  final TextEditingController _deptNameController = TextEditingController();

  final TextEditingController _deptDescController = TextEditingController();

  final TextEditingController _roleNameController = TextEditingController();

  final TextEditingController _kioskNameController = TextEditingController();

  final TextEditingController _kioskCodeController = TextEditingController();

  final TextEditingController _kioskLocationController =
      TextEditingController();

  final TextEditingController _kioskIpController = TextEditingController();

  // ============================================================
  // DATA
  // ============================================================

  UserModel? admin;

  List<DepartmentModel> departments = [];

  List<RoleModel> roles = [];

  List<KioskModel> kiosks = [];

  // ============================================================
  // STATES
  // ============================================================

  bool isLoading = true;

  bool kioskLoading = false;

  String _kioskMethod = 'qr_pin';

  bool _kioskActive = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    _loadInitialData();
  }

  // ============================================================
  // LOAD INITIAL DATA
  // ============================================================

  Future<void> _loadInitialData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    await Future.wait([
      _fetchProfile(),
      _fetchDepartments(),
      _fetchRoles(),
      _fetchKiosks(),
    ]);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> _fetchProfile() async {
    final result = await AdminService.getProfile();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      admin = result;

      _profileNameController.text = result.name;

      _profileEmailController.text = result.email;
    });
  }

  Future<void> _updateProfile() async {
    final success = await AdminService.updateProfile(
      name: _profileNameController.text.trim(),
      email: _profileEmailController.text.trim(),
    );

    if (!mounted) return;

    _showSnackBar(
      success
          ? 'Profil mis à jour avec succès'
          : 'Erreur lors de la mise à jour',
      success ? Colors.green : Colors.red,
    );

    if (success) {
      await _fetchProfile();
    }
  }

  // ============================================================
  // DEPARTMENTS
  // ============================================================

  Future<void> _fetchDepartments() async {
    final result = await AdminService.getDepartments();

    if (!mounted) return;

    setState(() {
      departments = result;
    });
  }

  Future<void> _createDepartment() async {
    final name = _deptNameController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Le nom du département est obligatoire', Colors.orange);
      return;
    }

    final success = await AdminService.createDepartment(
      name: name,
      description: _deptDescController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _deptNameController.clear();
      _deptDescController.clear();

      await _fetchDepartments();

      _showSnackBar('Département ajouté avec succès', Colors.green);
    } else {
      _showSnackBar('Impossible de créer le département', Colors.red);
    }
  }

  Future<void> _deleteDepartment(int id) async {
    final success = await AdminService.deleteDepartment(id);

    if (!mounted) return;

    if (success) {
      await _fetchDepartments();

      _showSnackBar('Département supprimé', Colors.orange);
    } else {
      _showSnackBar('Impossible de supprimer le département', Colors.red);
    }
  }

  // ============================================================
  // ROLES
  // ============================================================

  Future<void> _fetchRoles() async {
    final result = await AdminService.getRoles();

    if (!mounted) return;

    setState(() {
      roles = result;
    });
  }

  Future<void> _createRole() async {
    final name = _roleNameController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Le nom du rôle est obligatoire', Colors.orange);
      return;
    }

    final success = await AdminService.createRole(name: name);

    if (!mounted) return;

    if (success) {
      _roleNameController.clear();

      await _fetchRoles();

      _showSnackBar('Rôle créé avec succès', Colors.green);
    } else {
      _showSnackBar('Impossible de créer le rôle', Colors.red);
    }
  }

  // ============================================================
  // KIOSKS
  // ============================================================

  Future<void> _fetchKiosks() async {
    final result = await KioskService.getKiosks();

    if (!mounted) return;

    setState(() {
      kiosks = result;
    });
  }

  Future<void> _createKiosk() async {
    final name = _kioskNameController.text.trim();

    final code = _kioskCodeController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Le nom du kiosk est obligatoire', Colors.orange);
      return;
    }

    if (code.isEmpty) {
      _showSnackBar('Le code du kiosk est obligatoire', Colors.orange);
      return;
    }

    setState(() {
      kioskLoading = true;
    });

    final success = await KioskService.createKiosk(
      name: name,
      code: code,
      location: _kioskLocationController.text.trim(),
      method: _kioskMethod,
      ipAddress: _kioskIpController.text.trim().isEmpty
          ? null
          : _kioskIpController.text.trim(),
      active: _kioskActive,
    );

    if (!mounted) return;

    setState(() {
      kioskLoading = false;
    });

    if (success) {
      _clearKioskForm();

      await _fetchKiosks();

      if (mounted) {
        Navigator.pop(context);
      }

      _showSnackBar('Kiosk créé avec succès', Colors.green);
    } else {
      _showSnackBar('Impossible de créer le kiosk', Colors.red);
    }
  }

  Future<void> _toggleKiosk(int id) async {
    final success = await KioskService.toggleKiosk(id);

    if (!mounted) return;

    if (success) {
      await _fetchKiosks();

      _showSnackBar('État du kiosk modifié', Colors.green);
    } else {
      _showSnackBar('Impossible de modifier le kiosk', Colors.red);
    }
  }

  Future<void> _deleteKiosk(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le kiosk ?'),
          content: const Text('Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final success = await KioskService.deleteKiosk(id);

    if (!mounted) return;

    if (success) {
      await _fetchKiosks();

      _showSnackBar('Kiosk supprimé', Colors.orange);
    } else {
      _showSnackBar('Impossible de supprimer le kiosk', Colors.red);
    }
  }

  // ============================================================
  // CLEAR KIOSK
  // ============================================================

  void _clearKioskForm() {
    _kioskNameController.clear();
    _kioskCodeController.clear();
    _kioskLocationController.clear();
    _kioskIpController.clear();

    _kioskMethod = 'qr_pin';

    _kioskActive = true;
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _tabController.dispose();

    _profileNameController.dispose();
    _profileEmailController.dispose();

    _deptNameController.dispose();
    _deptDescController.dispose();

    _roleNameController.dispose();

    _kioskNameController.dispose();
    _kioskCodeController.dispose();
    _kioskLocationController.dispose();
    _kioskIpController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0078D4);
    const bgLight = Color(0xFFF3F2F1);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Paramètres d’administration'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profil'),
            Tab(icon: Icon(Icons.apartment), text: 'Départements'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Rôles'),
            Tab(icon: Icon(Icons.point_of_sale), text: 'Kiosks'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileSection(),
                _buildDepartmentSection(),
                _buildRoleSection(),
                _buildKioskSection(),
              ],
            ),
    );
  }

  // ============================================================
  // PROFILE SECTION
  // ============================================================

  Widget _buildProfileSection() {
    return _buildSectionContainer(
      title: 'Modifier les informations du profil',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _profileNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _profileEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _updateProfile,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DEPARTMENT SECTION
  // ============================================================

  Widget _buildDepartmentSection() {
    return _buildSectionContainer(
      title: 'Gestion des départements',
      child: Column(
        children: [
          TextField(
            controller: _deptNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du département',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.domain),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _deptDescController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _createDepartment,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ),
          const Divider(height: 40),
          Expanded(
            child: departments.isEmpty
                ? const Center(child: Text('Aucun département'))
                : ListView.builder(
                    itemCount: departments.length,
                    itemBuilder: (context, index) {
                      final department = departments[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.apartment),
                          title: Text(department.name),
                          subtitle: Text(department.description),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteDepartment(department.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROLE SECTION
  // ============================================================

  Widget _buildRoleSection() {
    return _buildSectionContainer(
      title: 'Gestion des rôles',
      child: Column(
        children: [
          TextField(
            controller: _roleNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du rôle',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.security),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _createRole,
              icon: const Icon(Icons.add),
              label: const Text('Créer le rôle'),
            ),
          ),
          const Divider(height: 40),
          Expanded(
            child: roles.isEmpty
                ? const Center(child: Text('Aucun rôle'))
                : ListView.builder(
                    itemCount: roles.length,
                    itemBuilder: (context, index) {
                      final role = roles[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: Text(role.name),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KIOSK SECTION
  // ============================================================

  Widget _buildKioskSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kiosks de pointage',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Gérez les appareils utilisés pour le pointage.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showCreateKioskDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const Divider(height: 35),
              Expanded(
                child: kiosks.isEmpty
                    ? _buildEmptyKiosk()
                    : RefreshIndicator(
                        onRefresh: _fetchKiosks,
                        child: ListView.builder(
                          itemCount: kiosks.length,
                          itemBuilder: (context, index) {
                            return _buildKioskCard(kiosks[index]);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // KIOSK CARD
  // ============================================================

  Widget _buildKioskCard(KioskModel kiosk) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: kiosk.active
                    ? Colors.green.withOpacity(.1)
                    : Colors.red.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.point_of_sale,
                color: kiosk.active ? Colors.green : Colors.red,
                size: 30,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          kiosk.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kiosk.active
                              ? Colors.green.withOpacity(.1)
                              : Colors.red.withOpacity(.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          kiosk.active ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            color: kiosk.active ? Colors.green : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 15,
                    runSpacing: 5,
                    children: [
                      _infoItem(Icons.qr_code, 'Code', kiosk.code),
                      _infoItem(
                        Icons.location_on_outlined,
                        'Lieu',
                        kiosk.location,
                      ),
                      _infoItem(Icons.fingerprint, 'Méthode', kiosk.method),
                      _infoItem(Icons.lan_outlined, 'IP', kiosk.ipAddress),
                      _infoItem(
                        Icons.access_time,
                        'Connexion',
                        kiosk.lastConnection,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle') {
                  _toggleKiosk(kiosk.id);
                }

                if (value == 'delete') {
                  _deleteKiosk(kiosk.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        kiosk.active ? Icons.block : Icons.check_circle,
                        color: kiosk.active ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Text(kiosk.active ? 'Désactiver' : 'Activer'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY KIOSK
  // ============================================================

  Widget _buildEmptyKiosk() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.point_of_sale_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 15),
          const Text(
            'Aucun kiosk configuré',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez votre premier appareil de pointage.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showCreateKioskDialog,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un kiosk'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CREATE KIOSK DIALOG
  // ============================================================

  void _showCreateKioskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.point_of_sale),
                  SizedBox(width: 10),
                  Text('Ajouter un Kiosk'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _kioskNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du kiosk',
                          hintText: 'Ex: Kiosk Entrée principale',
                          prefixIcon: Icon(Icons.devices),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _kioskCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Code kiosk',
                          hintText: 'Ex: KIOSK-001',
                          prefixIcon: Icon(Icons.qr_code),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _kioskLocationController,
                        decoration: const InputDecoration(
                          labelText: 'Emplacement',
                          hintText: 'Ex: Entrée principale',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _kioskMethod,
                        decoration: const InputDecoration(
                          labelText: 'Méthode de pointage',
                          prefixIcon: Icon(Icons.fingerprint),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'qr_pin',
                            child: Text('QR Code + PIN'),
                          ),
                          DropdownMenuItem(
                            value: 'qr',
                            child: Text('QR Code uniquement'),
                          ),
                          DropdownMenuItem(
                            value: 'pin',
                            child: Text('PIN uniquement'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _kioskMethod = value ?? 'qr_pin';
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _kioskIpController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse IP (optionnel)',
                          hintText: 'Ex: 192.168.1.20',
                          prefixIcon: Icon(Icons.lan_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Kiosk actif'),
                        subtitle: const Text(
                          'Autoriser ce kiosk à fonctionner',
                        ),
                        value: _kioskActive,
                        onChanged: (value) {
                          setDialogState(() {
                            _kioskActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: kioskLoading ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: kioskLoading ? null : _createKiosk,
                  icon: kioskLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Créer le kiosk'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SECTION CONTAINER
  // ============================================================

  Widget _buildSectionContainer({
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF201F1E),
                ),
              ),
              const Divider(height: 24),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
