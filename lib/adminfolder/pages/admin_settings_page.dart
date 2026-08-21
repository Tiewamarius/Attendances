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
  // ============================================================
  // CONSTANTES UI
  // ============================================================

  static const Color primaryColor = Color(0xFF0078D4);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textColor = Color(0xFF1E293B);
  static const Color mutedColor = Color(0xFF64748B);

  // ============================================================
  // TAB CONTROLLER
  // ============================================================

  late TabController _tabController;

  // ============================================================
  // PROFILE
  // ============================================================

  final TextEditingController _profileNameController = TextEditingController();

  final TextEditingController _profileEmailController = TextEditingController();

  // ============================================================
  // DEPARTMENTS
  // ============================================================

  final TextEditingController _deptNameController = TextEditingController();

  final TextEditingController _deptDescController = TextEditingController();

  // ============================================================
  // ROLES
  // ============================================================

  final TextEditingController _roleNameController = TextEditingController();

  // ============================================================
  // KIOSK
  // ============================================================

  final TextEditingController _kioskNameController = TextEditingController();

  final TextEditingController _kioskCodeController = TextEditingController();

  final TextEditingController _kioskLocationController =
      TextEditingController();

  final TextEditingController _kioskIpController = TextEditingController();

  String _kioskMethod = 'qr_pin';

  bool _kioskActive = true;

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

  bool profileLoading = false;

  bool departmentLoading = false;

  bool roleLoading = false;

  bool kioskLoading = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);

    _loadInitialData();
  }

  // ============================================================
  // INITIAL DATA
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

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> _fetchProfile() async {
    final result = await AdminService.getProfile();

    if (!mounted || result == null) return;

    setState(() {
      admin = result;

      _profileNameController.text = result.name;

      _profileEmailController.text = result.email;
    });
  }

  Future<void> _updateProfile() async {
    if (_profileNameController.text.trim().isEmpty ||
        _profileEmailController.text.trim().isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs.', Colors.orange);

      return;
    }

    setState(() {
      profileLoading = true;
    });

    if (!mounted) return;

    setState(() {
      profileLoading = false;
    });

    _showSnackBar(
      'La mise à jour du profil n’est pas encore disponible.',
      Colors.orange,
    );
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
      _showSnackBar('Le nom du département est obligatoire.', Colors.orange);

      return;
    }

    setState(() {
      departmentLoading = true;
    });

    final success = await AdminService.createDepartment(
      name: name,
      description: _deptDescController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      departmentLoading = false;
    });

    if (success == true) {
      _deptNameController.clear();
      _deptDescController.clear();

      await _fetchDepartments();

      _showSnackBar('Département ajouté avec succès.', Colors.green);
    } else {
      _showSnackBar('Impossible de créer le département.', Colors.red);
    }
  }

  Future<void> _deleteDepartment(int id) async {
    final confirm = await _confirmDelete(
      title: 'Supprimer le département ?',
      message: 'Cette action supprimera le département définitivement.',
    );

    if (!confirm) return;

    final success = await AdminService.deleteDepartment(id);

    if (!mounted) return;

    if (success == true) {
      await _fetchDepartments();

      _showSnackBar('Département supprimé.', Colors.orange);
    } else {
      _showSnackBar('Impossible de supprimer le département.', Colors.red);
    }
  }

  // ============================================================
  // ROLES
  // ============================================================

  Future<void> _fetchRoles() async {
    try {
      final result = <RoleModel>[];

      if (!mounted) return;

      setState(() {
        roles = result;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        roles = [];
      });
    }
  }

  Future<void> _createRole() async {
    final name = _roleNameController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Le nom du rôle est obligatoire.', Colors.orange);

      return;
    }

    setState(() {
      roleLoading = true;
    });

    const success = false;

    if (!mounted) return;

    setState(() {
      roleLoading = false;
    });

    if (success == true) {
      _roleNameController.clear();

      await _fetchRoles();

      _showSnackBar('Rôle créé avec succès.', Colors.green);
    } else {
      _showSnackBar('Impossible de créer le rôle.', Colors.red);
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
      _showSnackBar('Le nom du kiosk est obligatoire.', Colors.orange);

      return;
    }

    if (code.isEmpty) {
      _showSnackBar('Le code du kiosk est obligatoire.', Colors.orange);

      return;
    }

    setState(() {
      kioskLoading = true;
    });

    final success = await KioskService.createKiosk(
      name: name,
      code: code,
      location: _kioskLocationController.text.trim(),
      mode: _kioskMethod,
      ipAddress: _kioskIpController.text.trim().isEmpty
          ? null
          : _kioskIpController.text.trim(),
      active: _kioskActive,
    );

    if (!mounted) return;

    setState(() {
      kioskLoading = false;
    });

    // ignore: unrelated_type_equality_checks
    if (success == true) {
      _clearKioskForm();

      await _fetchKiosks();

      if (mounted) {
        Navigator.of(context).pop();
      }

      _showSnackBar('Kiosk créé avec succès.', Colors.green);
    } else {
      _showSnackBar('Impossible de créer le kiosk.', Colors.red);
    }
  }

  Future<void> _toggleKiosk(int id) async {
    await KioskService.toggleKiosk(id);

    if (!mounted) return;

    await _fetchKiosks();
    _showSnackBar('État du kiosk modifié.', Colors.green);
  }

  Future<void> _deleteKiosk(int id) async {
    final confirm = await _confirmDelete(
      title: 'Supprimer le kiosk ?',
      message: 'Cette action supprimera définitivement ce kiosk.',
    );

    if (!confirm) return;

    await KioskService.deleteKiosk(id);

    if (!mounted) return;

    await _fetchKiosks();
    _showSnackBar('Kiosk supprimé.', Colors.orange);
  }

  void _clearKioskForm() {
    _kioskNameController.clear();
    _kioskCodeController.clear();
    _kioskLocationController.clear();
    _kioskIpController.clear();

    _kioskMethod = 'qr_pin';

    _kioskActive = true;
  }

  // ============================================================
  // CONFIRM DELETE
  // ============================================================

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
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

    return result == true;
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabBar(),

                // IMPORTANT :
                // Le TabBarView prend exactement toute la place restante.
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileTab(),
                      _buildDepartmentsTab(),
                      _buildRolesTab(),
                      _buildKiosksTab(),
                      _buildAdministratorsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: textColor,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2),
          Text(
            'Administration du système',
            style: TextStyle(
              fontSize: 12,
              color: mutedColor,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB BAR
  // ============================================================

  Widget _buildTabBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: primaryColor,
        unselectedLabelColor: mutedColor,
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.person_outline), text: 'Profil'),
          Tab(icon: Icon(Icons.apartment_outlined), text: 'Départements'),
          Tab(icon: Icon(Icons.admin_panel_settings_outlined), text: 'Rôles'),
          Tab(icon: Icon(Icons.point_of_sale_outlined), text: 'Kiosks'),
          Tab(icon: Icon(Icons.people_outline), text: 'Administrateurs'),
        ],
      ),
    );
  }

  // ============================================================
  // GENERIC TAB CONTAINER
  // ============================================================

  Widget _tabContainer({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }

  // ============================================================
  // PROFILE TAB
  // ============================================================

  Widget _buildProfileTab() {
    return _tabContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              icon: Icons.person_outline,
              title: 'Mon profil',
              subtitle:
                  'Modifiez les informations du compte actuellement connecté.',
            ),

            const SizedBox(height: 30),

            _profileHeader(),

            const SizedBox(height: 30),

            _inputField(
              controller: _profileNameController,
              label: 'Nom complet',
              icon: Icons.badge_outlined,
            ),

            const SizedBox(height: 18),

            _inputField(
              controller: _profileEmailController,
              label: 'Adresse email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 25),

            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: profileLoading ? null : _updateProfile,
                icon: profileLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Enregistrer les modifications'),
                style: _primaryButtonStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: primaryColor.withValues(alpha: .12),
            child: const Icon(Icons.person, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin?.name ?? 'Administrateur',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  admin?.email ?? '',
                  style: const TextStyle(color: mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEPARTMENTS TAB
  // ============================================================

  Widget _buildDepartmentsTab() {
    return _tabContainer(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.apartment_outlined,
            title: 'Départements',
            subtitle: 'Organisez les employés par département.',
            action: ElevatedButton.icon(
              onPressed: _showCreateDepartmentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nouveau département'),
              style: _primaryButtonStyle(),
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: departments.isEmpty
                ? _buildEmptyState(
                    icon: Icons.apartment_outlined,
                    title: 'Aucun département',
                    message: 'Commencez par créer votre premier département.',
                    buttonText: 'Créer un département',
                    onPressed: _showCreateDepartmentDialog,
                  )
                : RefreshIndicator(
                    onRefresh: _fetchDepartments,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: departments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _departmentCard(departments[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _departmentCard(DepartmentModel department) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _iconBox(Icons.apartment_outlined, primaryColor),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  department.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  department.description,
                  style: const TextStyle(color: mutedColor, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: () => _deleteDepartment(department.id),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROLES TAB
  // ============================================================

  Widget _buildRolesTab() {
    return _tabContainer(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Rôles',
            subtitle: 'Gérez les rôles disponibles dans votre organisation.',
            action: ElevatedButton.icon(
              onPressed: _showCreateRoleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nouveau rôle'),
              style: _primaryButtonStyle(),
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: roles.isEmpty
                ? _buildEmptyState(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Aucun rôle',
                    message: 'Aucun rôle supplémentaire n’est configuré.',
                    buttonText: 'Créer un rôle',
                    onPressed: _showCreateRoleDialog,
                  )
                : ListView.separated(
                    itemCount: roles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final role = roles[index];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _iconBox(
                              Icons.security_outlined,
                              Colors.deepPurple,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                role.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: mutedColor),
                          ],
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
  // KIOSKS TAB
  // ============================================================

  Widget _buildKiosksTab() {
    return _tabContainer(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.point_of_sale_outlined,
            title: 'Kiosks de pointage',
            subtitle:
                'Gérez les appareils utilisés pour enregistrer les présences.',
            action: ElevatedButton.icon(
              onPressed: _showCreateKioskDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nouveau kiosk'),
              style: _primaryButtonStyle(),
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: kiosks.isEmpty
                ? _buildEmptyState(
                    icon: Icons.point_of_sale_outlined,
                    title: 'Aucun kiosk',
                    message: 'Aucun appareil de pointage n’est configuré.',
                    buttonText: 'Ajouter un kiosk',
                    onPressed: _showCreateKioskDialog,
                  )
                : RefreshIndicator(
                    onRefresh: _fetchKiosks,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: kiosks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildKioskCard(kiosks[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKioskCard(KioskModel kiosk) {
    final active = kiosk.active;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _iconBox(
            Icons.point_of_sale_outlined,
            active ? Colors.green : Colors.red,
          ),

          const SizedBox(width: 16),

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
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _statusBadge(active),
                  ],
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _infoItem(Icons.qr_code, 'Code', kiosk.code),
                    _infoItem(
                      Icons.location_on_outlined,
                      'Lieu',
                      kiosk.location ?? '',
                    ),
                    _infoItem(
                      Icons.lan_outlined,
                      'IP',
                      kiosk.ipAddress ?? '',
                    ),
                    _infoItem(
                      Icons.access_time,
                      'Connexion',
                      kiosk.lastConnection as String,
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
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      active ? Icons.block : Icons.check_circle,
                      color: active ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Text(active ? 'Désactiver' : 'Activer'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Supprimer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADMINISTRATORS TAB
  // ============================================================

  Widget _buildAdministratorsTab() {
    return _tabContainer(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.people_outline,
            title: 'Administrateurs',
            subtitle:
                'Gérez les comptes administratifs : Admin, HR et Manager.',
          ),

          const SizedBox(height: 24),

          Expanded(
            child: _buildEmptyState(
              icon: Icons.people_outline,
              title: 'Gestion des administrateurs',
              message:
                  'Cette section permettra de consulter et modifier les comptes Admin, HR et Manager.',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBox(icon, primaryColor),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(color: mutedColor, fontSize: 13),
              ),
            ],
          ),
        ),

        ?action,
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: const Color(0xFFCBD5E1)),

          const SizedBox(height: 18),

          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 8),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mutedColor),
          ),

          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
              style: _primaryButtonStyle(),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ICON BOX
  // ============================================================

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withValues(alpha: .10)
            : Colors.red.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Actif' : 'Inactif',
        style: TextStyle(
          color: active ? Colors.green : Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
        Icon(icon, size: 14, color: mutedColor),
        const SizedBox(width: 5),
        Text(
          '$label : ',
          style: const TextStyle(color: mutedColor, fontSize: 12),
        ),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON STYLE
  // ============================================================

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  // ============================================================
  // CREATE DEPARTMENT DIALOG
  // ============================================================

  void _showCreateDepartmentDialog() {
    _deptNameController.clear();
    _deptDescController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nouveau département'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _inputField(
                  controller: _deptNameController,
                  label: 'Nom du département',
                  icon: Icons.apartment_outlined,
                ),
                const SizedBox(height: 15),
                _inputField(
                  controller: _deptDescController,
                  label: 'Description',
                  icon: Icons.description_outlined,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: departmentLoading
                  ? null
                  : () async {
                      await _createDepartment();

                      if (mounted && !departmentLoading) {
                        Navigator.pop(dialogContext);
                      }
                    },
              icon: const Icon(Icons.add),
              label: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CREATE ROLE DIALOG
  // ============================================================

  void _showCreateRoleDialog() {
    _roleNameController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nouveau rôle'),
          content: SizedBox(
            width: 450,
            child: _inputField(
              controller: _roleNameController,
              label: 'Nom du rôle',
              icon: Icons.security_outlined,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: roleLoading
                  ? null
                  : () async {
                      await _createRole();

                      if (mounted && !roleLoading) {
                        Navigator.pop(dialogContext);
                      }
                    },
              icon: const Icon(Icons.add),
              label: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CREATE KIOSK DIALOG
  // ============================================================

  void _showCreateKioskDialog() {
    _clearKioskForm();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.point_of_sale_outlined, color: primaryColor),
                  SizedBox(width: 10),
                  Text('Nouveau kiosk'),
                ],
              ),

              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _inputField(
                        controller: _kioskNameController,
                        label: 'Nom du kiosk',
                        icon: Icons.devices_outlined,
                      ),

                      const SizedBox(height: 15),

                      _inputField(
                        controller: _kioskCodeController,
                        label: 'Code kiosk',
                        icon: Icons.qr_code,
                      ),

                      const SizedBox(height: 15),

                      _inputField(
                        controller: _kioskLocationController,
                        label: 'Emplacement',
                        icon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        initialValue: _kioskMethod,
                        decoration: InputDecoration(
                          labelText: 'Méthode de pointage',
                          prefixIcon: const Icon(Icons.fingerprint),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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

                      _inputField(
                        controller: _kioskIpController,
                        label: 'Adresse IP (optionnel)',
                        icon: Icons.lan_outlined,
                        keyboardType: TextInputType.text,
                      ),

                      const SizedBox(height: 10),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Kiosk actif'),
                        subtitle: const Text(
                          'Autoriser cet appareil à effectuer les pointages.',
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
                  onPressed: kioskLoading
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
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
                  style: _primaryButtonStyle(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
