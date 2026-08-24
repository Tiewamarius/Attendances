import 'package:attendance/models/admins/department_model.dart';
import 'package:attendance/models/admins/kiosk_model..dart';
import 'package:attendance/models/admins/model_roles.dart';
import 'package:attendance/models/user_model.dart';
import 'package:attendance/services/user_service.dart';
import 'package:attendance/services/admins/kiosk_service.dart';
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

  static const Color primaryColor = Color(0xFF060606);
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

  // final TextEditingController _kioskCodeController = TextEditingController();

  final TextEditingController _kioskLocationController =
      TextEditingController();

  final TextEditingController _kioskIpController = TextEditingController();

  String _kioskMethod = 'KIOSK_QR';

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
    final result = await UserService.getProfile();

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
    final result = await UserService.getDepartments();

    if (!mounted) return;

    setState(() {
      departments = result;
    });
  }

  Future<void> _createDepartment() async {
    final name = _deptNameController.text.trim();
    final description = _deptDescController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Le nom du département est obligatoire.', Colors.orange);
      return;
    }

    setState(() {
      departmentLoading = true;
    });

    final department = await UserService.createDepartment(
      name: name,
      description: description.isEmpty ? null : description,
    );

    if (!mounted) return;

    setState(() {
      departmentLoading = false;
    });

    if (department != null) {
      _deptNameController.clear();
      _deptDescController.clear();

      await _fetchDepartments();

      _showSnackBar('Département  créé avec succès.', Colors.green);
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

    final success = await UserService.deleteDepartment(id);

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
    if (mounted) {
      setState(() {
        roleLoading = true;
      });
    }

    try {
      final result = await UserService.getRoles();

      if (!mounted) return;

      setState(() {
        roles = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        roles = [];
      });

      debugPrint('AdminSettingsPage._fetchRoles: $e');
    } finally {
      if (mounted) {
        setState(() {
          roleLoading = false;
        });
      }
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
  final location = _kioskLocationController.text.trim();
  final ipAddress = _kioskIpController.text.trim();

  if (name.isEmpty) {
    _showSnackBar(
      'Le nom du kiosk est obligatoire.',
      Colors.orange,
    );
    return;
  }

  setState(() {
    kioskLoading = true;
  });

  try {
    final kiosk = await KioskService.createKiosk(
      name: name,
      location: location.isEmpty ? null : location,
      method: _kioskMethod,
      ipAddress: ipAddress.isEmpty ? null : ipAddress,
      active: _kioskActive,
    );

    debugPrint(
      'Kiosk créé : ${kiosk.name} - ${kiosk.code} - ID ${kiosk.id}',
    );

    if (!mounted) return;

    // Fermer le formulaire
    Navigator.of(context).pop();

    // Recharger la liste
    await _fetchKiosks();

    _clearKioskForm();

    _showSnackBar(
      'Kiosk "${kiosk.name}" créé avec succès.',
      Colors.green,
    );
  } catch (e, stackTrace) {
    debugPrint('Erreur création kiosk : $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    _showSnackBar(
      'Impossible de créer le kiosk}',
      Colors.red,
    );
  } finally {
    if (mounted) {
      setState(() {
        kioskLoading = false;
      });
    }
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
    // _kioskCodeController.clear();
    _kioskLocationController.clear();
    _kioskIpController.clear();

    _kioskMethod = 'KIOSK_QR';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: child,
      ),
    );
  }

  // ============================================================
  // PROFILE TAB
  // ============================================================

  Widget _buildProfileTab() {
    return _tabContainer(
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

          if (departments.isEmpty)
            _buildEmptyState(
              icon: Icons.apartment_outlined,
              title: 'Aucun département',
              message: 'Commencez par créer votre premier département.',
              buttonText: 'Créer un département',
              onPressed: _showCreateDepartmentDialog,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: departments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _departmentCard(departments[index]);
              },
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

  /// ============================================================
  // ROLES TAB
  // ============================================================

  Widget _buildRolesTab() {
    return _tabContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Rôles',
            subtitle: 'Rôles déjà définis dans votre organisation.',
          ),

          const SizedBox(height: 24),

          if (roleLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (roles.isEmpty)
            _buildEmptyState(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Aucun rôle',
              message: 'Aucun rôle n’a été retourné par le serveur.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: roles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _roleCard(roles[index]);
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ROLE CARD
  // ============================================================

  Widget _roleCard(RoleModel role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _iconBox(Icons.security_outlined, Colors.deepPurple),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Identifiant : ${role.id}',
                  style: const TextStyle(color: mutedColor, fontSize: 12),
                ),
              ],
            ),
          ),

          // Aucun bouton modifier/supprimer.
          // Les rôles sont uniquement consultables.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Disponible',
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

          if (kiosks.isEmpty)
            _buildEmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'Aucun kiosk',
              message: 'Aucun appareil de pointage n’est configuré.',
              buttonText: 'Ajouter un kiosk',
              onPressed: _showCreateKioskDialog,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kiosks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildKioskCard(kiosks[index]);
              },
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
                    _infoItem(Icons.qr_code, 'Code', kiosk.id.toString()),
                    _infoItem(
                      Icons.location_on_outlined,
                      'Lieu',
                      kiosk.location ?? '',
                    ),
                    _infoItem(Icons.lan_outlined, 'IP', kiosk.ipAddress ?? ''),
                    _infoItem(
                      Icons.access_time,
                      'Connexion',
                      kiosk.lastConnection?.toString() ?? '',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.people_outline,
            title: 'Administrateurs',
            subtitle:
                'Gérez les comptes administratifs : Admin, HR et Manager.',
          ),

          const SizedBox(height: 24),

          _buildEmptyState(
            icon: Icons.people_outline,
            title: 'Gestion des administrateurs',
            message:
                'Cette section permettra de consulter et modifier les comptes Admin, HR et Manager.',
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

        if (action != null) ...[
          const SizedBox(width: 16),

          Flexible(child: action),
        ],
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

                      // const SizedBox(height: 15),

                      // _inputField(
                      //   controller: _kioskCodeController,
                      //   label: 'Code kiosk',
                      //   icon: Icons.qr_code,
                      // ),
                      const SizedBox(height: 15),

                      _inputField(
                        controller: _kioskLocationController,
                        label: 'Emplacement',
                        icon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: _kioskMethod,
                        decoration: const InputDecoration(
                          labelText: 'Méthode de pointage',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'KIOSK_QR',
                            child: Text('Kiosk QR'),
                          ),
                          DropdownMenuItem(
                            value: 'KIOSK_PIN',
                            child: Text('Kiosk PIN'),
                          ),
                          DropdownMenuItem(
                            value: 'MOBILE',
                            child: Text('Mobile'),
                          ),
                          DropdownMenuItem(
                            value: 'MANUAL',
                            child: Text('Manuel'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _kioskMethod = value;
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
