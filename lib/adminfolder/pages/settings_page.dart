import 'package:attendance/models/department_model.dart';
import 'package:attendance/models/kiosk_model.dart';
import 'package:attendance/models/model_roles.dart';
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
  // UI
  // ============================================================

  static const Color primaryColor = Color(0xFF0F172A);
  static const Color secondaryColor = Color(0xFF334155);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF0F172A);
  static const Color mutedColor = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  // ============================================================
  // TAB CONTROLLER
  // ============================================================

  late TabController _tabController;

  // ============================================================
  // PROFILE
  // ============================================================

  final TextEditingController _profileNameController =
      TextEditingController();

  final TextEditingController _profileEmailController =
      TextEditingController();

  // ============================================================
  // DEPARTMENTS
  // ============================================================

  final TextEditingController _deptNameController =
      TextEditingController();

  final TextEditingController _deptDescController =
      TextEditingController();

  // ============================================================
  // KIOSK
  // ============================================================

  final TextEditingController _kioskNameController =
      TextEditingController();

  final TextEditingController _kioskLocationController =
      TextEditingController();

  final TextEditingController _kioskIpController =
      TextEditingController();

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

    _tabController = TabController(
      length: 5,
      vsync: this,
    );

    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

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

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _refreshAll() async {
    await _loadInitialData();
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> _fetchProfile() async {
    try {
      final result = await UserService.getProfile();

      if (!mounted || result == null) return;

      setState(() {
        admin = result;
        _profileNameController.text = result.name;
        _profileEmailController.text = result.email;
      });
    } catch (e) {
      debugPrint(
        'AdminSettingsPage._fetchProfile: $e',
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_profileNameController.text.trim().isEmpty ||
        _profileEmailController.text.trim().isEmpty) {
      _showSnackBar(
        'Veuillez remplir tous les champs.',
        Colors.orange,
      );
      return;
    }

    setState(() {
      profileLoading = true;
    });

    // ----------------------------------------------------------
    // Ton endpoint de mise à jour du profil n'étant pas encore
    // branché dans UserService, on conserve le comportement actuel.
    // ----------------------------------------------------------

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    setState(() {
      profileLoading = false;
    });

    _showSnackBar(
      'La mise à jour du profil sera disponible prochainement.',
      Colors.orange,
    );
  }

  // ============================================================
  // DEPARTMENTS
  // ============================================================

  Future<void> _fetchDepartments() async {
    try {
      final result = await UserService.getDepartments();

      if (!mounted) return;

      setState(() {
        departments = result;
      });
    } catch (e) {
      debugPrint(
        'AdminSettingsPage._fetchDepartments: $e',
      );
    }
  }

  Future<void> _createDepartment() async {
    final name = _deptNameController.text.trim();
    final description = _deptDescController.text.trim();

    if (name.isEmpty) {
      _showSnackBar(
        'Le nom du département est obligatoire.',
        Colors.orange,
      );
      return;
    }

    setState(() {
      departmentLoading = true;
    });

    try {
      final department = await UserService.createDepartment(
        name: name,
        description: description.isEmpty ? null : description,
      );

      if (!mounted) return;

      if (department != null) {
        _deptNameController.clear();
        _deptDescController.clear();

        await _fetchDepartments();

        if (!mounted) return;

        Navigator.of(context).pop();

        _showSnackBar(
          'Département créé avec succès.',
          Colors.green,
        );
      } else {
        _showSnackBar(
          'Impossible de créer le département.',
          Colors.red,
        );
      }
    } catch (e) {
      debugPrint(
        'AdminSettingsPage._createDepartment: $e',
      );

      if (mounted) {
        _showSnackBar(
          'Une erreur est survenue.',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          departmentLoading = false;
        });
      }
    }
  }

  Future<void> _deleteDepartment(int id) async {
    final confirm = await _confirmDelete(
      title: 'Supprimer le département ?',
      message:
          'Cette action supprimera définitivement le département.',
    );

    if (!confirm) return;

    try {
      final success = await UserService.deleteDepartment(id);

      if (!mounted) return;

      if (success == true) {
        await _fetchDepartments();

        _showSnackBar(
          'Département supprimé.',
          Colors.orange,
        );
      } else {
        _showSnackBar(
          'Impossible de supprimer le département.',
          Colors.red,
        );
      }
    } catch (e) {
      debugPrint(
        'AdminSettingsPage._deleteDepartment: $e',
      );

      if (mounted) {
        _showSnackBar(
          'Erreur lors de la suppression.',
          Colors.red,
        );
      }
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
      debugPrint(
        'AdminSettingsPage._fetchRoles: $e',
      );

      if (!mounted) return;

      setState(() {
        roles = [];
      });
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
    try {
      final result = await KioskService.getKiosks();

      if (!mounted) return;

      setState(() {
        kiosks = result;
      });
    } catch (e) {
      debugPrint(
        'AdminSettingsPage._fetchKiosks: $e',
      );
    }
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

      if (!mounted) return;

      debugPrint(
        'Kiosk créé : ${kiosk.name} - ${kiosk.code} - ID ${kiosk.id}',
      );

      await _fetchKiosks();

      if (!mounted) return;

      Navigator.of(context).pop();

      _clearKioskForm();

      _showSnackBar(
        'Kiosk "${kiosk.name}" créé avec succès.',
        Colors.green,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Erreur création kiosk : $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (mounted) {
        _showSnackBar(
          'Impossible de créer le kiosk.',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          kioskLoading = false;
        });
      }
    }
  }

  Future<void> _toggleKiosk(int id) async {
    try {
      await KioskService.toggleKiosk(id);

      if (!mounted) return;

      await _fetchKiosks();

      _showSnackBar(
        'État du kiosk modifié.',
        Colors.green,
      );
    } catch (e) {
      debugPrint(
        'AdminSettingsPage._toggleKiosk: $e',
      );

      if (mounted) {
        _showSnackBar(
          'Impossible de modifier le kiosk.',
          Colors.red,
        );
      }
    }
  }

  Future<void> _deleteKiosk(int id) async {
    final confirm = await _confirmDelete(
      title: 'Supprimer le kiosk ?',
      message:
          'Cette action supprimera définitivement ce kiosk.',
    );

    if (!confirm) return;

    try {
      await KioskService.deleteKiosk(id);

      if (!mounted) return;

      await _fetchKiosks();

      _showSnackBar(
        'Kiosk supprimé.',
        Colors.orange,
      );
    } catch (e) {
      debugPrint(
        'AdminSettingsPage._deleteKiosk: $e',
      );

      if (mounted) {
        _showSnackBar(
          'Impossible de supprimer le kiosk.',
          Colors.red,
        );
      }
    }
  }

  void _clearKioskForm() {
    _kioskNameController.clear();
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
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: mutedColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Annuler',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Supprimer',
              ),
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

  void _showSnackBar(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                color == Colors.green
                    ? Icons.check_circle_outline
                    : color == Colors.red
                        ? Icons.error_outline
                        : Icons.info_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
      body: SafeArea(
        child: isLoading
            ? _buildLoading()
            : Column(
                children: [
                  _buildHeader(),
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
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Chargement des paramètres...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        28,
        24,
        28,
        22,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paramètres',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configurez votre espace d’administration et votre organisation.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refreshAll,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              size: 21,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 850;

          return TabBar(
            controller: _tabController,
            isScrollable: isSmall,
            tabAlignment:
                isSmall ? TabAlignment.start : TabAlignment.fill,
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 12 : 24,
            ),
            labelColor: primaryColor,
            unselectedLabelColor: mutedColor,
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                icon: Icon(
                  Icons.person_outline,
                  size: 20,
                ),
                text: 'Profil',
              ),
              Tab(
                icon: Icon(
                  Icons.apartment_outlined,
                  size: 20,
                ),
                text: 'Départements',
              ),
              Tab(
                icon: Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 20,
                ),
                text: 'Rôles',
              ),
              Tab(
                icon: Icon(
                  Icons.point_of_sale_outlined,
                  size: 20,
                ),
                text: 'Kiosks',
              ),
              Tab(
                icon: Icon(
                  Icons.people_outline,
                  size: 20,
                ),
                text: 'Administrateurs',
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // GENERIC PAGE CONTAINER
  // ============================================================

  Widget _pageContainer({
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            constraints.maxWidth < 700 ? 16.0 : 28.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1250,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROFILE TAB
  // ============================================================

  Widget _buildProfileTab() {
    return _pageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrganizationSummary(),
          const SizedBox(height: 22),
          _buildProfileCard(),
        ],
      ),
    );
  }

  // ============================================================
  // ORGANIZATION SUMMARY
  // ============================================================

  Widget _buildOrganizationSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            const Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.12),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final identity = Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Organisation active',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Votre espace organisationnel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      admin?.email ?? 'Compte administrateur',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final statistics = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _summaryChip(
                Icons.apartment_outlined,
                '${departments.length}',
                'Départements',
              ),
              _summaryChip(
                Icons.security_outlined,
                '${roles.length}',
                'Rôles',
              ),
              _summaryChip(
                Icons.devices_outlined,
                '${kiosks.length}',
                'Kiosks',
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 22),
                statistics,
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: identity,
              ),
              const SizedBox(width: 30),
              Flexible(
                child: statistics,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryChip(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard() {
    return _settingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.person_outline,
            title: 'Mon profil',
            subtitle:
                'Gérez les informations du compte actuellement connecté.',
          ),
          const SizedBox(height: 28),
          _profileIdentity(),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 650;

              if (compact) {
                return Column(
                  children: [
                    _inputField(
                      controller: _profileNameController,
                      label: 'Nom complet',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    _inputField(
                      controller: _profileEmailController,
                      label: 'Adresse email',
                      icon: Icons.email_outlined,
                      keyboardType:
                          TextInputType.emailAddress,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _inputField(
                      controller: _profileNameController,
                      label: 'Nom complet',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _inputField(
                      controller: _profileEmailController,
                      label: 'Adresse email',
                      icon: Icons.email_outlined,
                      keyboardType:
                          TextInputType.emailAddress,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed:
                  profileLoading ? null : _updateProfile,
              icon: profileLoading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.save_outlined,
                      size: 18,
                    ),
              label: const Text(
                'Enregistrer',
              ),
              style: _primaryButtonStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileIdentity() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  admin?.name ?? 'Administrateur',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  admin?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          _badge(
            'Compte actif',
            Colors.green,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEPARTMENTS TAB
  // ============================================================

  Widget _buildDepartmentsTab() {
    return _pageContainer(
      child: _settingsCard(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              icon: Icons.apartment_outlined,
              title: 'Départements',
              subtitle:
                  'Organisez les employés au sein de votre organisation.',
              action: ElevatedButton.icon(
                onPressed:
                    _showCreateDepartmentDialog,
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text(
                  'Nouveau département',
                ),
                style: _primaryButtonStyle(),
              ),
            ),
            const SizedBox(height: 26),
            _buildCountHeader(
              icon: Icons.apartment_outlined,
              label: 'Départements configurés',
              count: departments.length,
            ),
            const SizedBox(height: 15),
            if (departments.isEmpty)
              _buildEmptyState(
                icon: Icons.apartment_outlined,
                title: 'Aucun département',
                message:
                    'Commencez par créer votre premier département.',
                buttonText:
                    'Créer un département',
                onPressed:
                    _showCreateDepartmentDialog,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: departments.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _departmentCard(
                    departments[index],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _departmentCard(
    DepartmentModel department,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          _iconBox(
            Icons.apartment_outlined,
            const Color(0xFF2563EB),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  department.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                if (department.description
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    department.description,
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: () =>
                _deleteDepartment(
              department.id,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  Colors.red.withValues(alpha: 0.06),
            ),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROLES TAB
  // ============================================================

  Widget _buildRolesTab() {
    return _pageContainer(
      child: _settingsCard(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Rôles',
              subtitle:
                  'Rôles disponibles dans l’organisation active.',
            ),
            const SizedBox(height: 26),
            _buildInfoBanner(
              icon: Icons.info_outline,
              title: 'Rôles organisationnels',
              message:
                  'Les rôles affichés ici appartiennent au contexte de l’organisation active. Les permissions associées déterminent les fonctionnalités accessibles.',
            ),
            const SizedBox(height: 20),
            _buildCountHeader(
              icon: Icons.security_outlined,
              label: 'Rôles disponibles',
              count: roles.length,
            ),
            const SizedBox(height: 15),
            if (roleLoading)
              const Padding(
                padding:
                    EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (roles.isEmpty)
              _buildEmptyState(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Aucun rôle',
                message:
                    'Aucun rôle n’a été retourné par le serveur.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: roles.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _roleCard(
                    roles[index],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(RoleModel role) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: borderColor,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _iconBox(
            Icons.security_outlined,
            const Color(0xFF7C3AED),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  role.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Identifiant : ${role.id}',
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _badge(
            'Disponible',
            const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KIOSKS TAB
  // ============================================================

  Widget _buildKiosksTab() {
    final activeKiosks =
        kiosks.where((kiosk) => kiosk.active).length;

    return _pageContainer(
      child: _settingsCard(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              icon: Icons.point_of_sale_outlined,
              title: 'Kiosks de pointage',
              subtitle:
                  'Gérez les appareils utilisés pour enregistrer les présences.',
              action: ElevatedButton.icon(
                onPressed: _showCreateKioskDialog,
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text(
                  'Nouveau kiosk',
                ),
                style: _primaryButtonStyle(),
              ),
            ),
            const SizedBox(height: 22),
            _buildKioskStatistics(
              activeKiosks,
            ),
            const SizedBox(height: 22),
            if (kiosks.isEmpty)
              _buildEmptyState(
                icon: Icons.point_of_sale_outlined,
                title: 'Aucun kiosk',
                message:
                    'Aucun appareil de pointage n’est configuré dans cette organisation.',
                buttonText: 'Ajouter un kiosk',
                onPressed:
                    _showCreateKioskDialog,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: kiosks.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildKioskCard(
                    kiosks[index],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKioskStatistics(
    int activeKiosks,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 650;

        final cards = [
          _statCard(
            icon: Icons.devices_outlined,
            value: '${kiosks.length}',
            label: 'Total kiosks',
            iconColor: const Color(0xFF2563EB),
          ),
          _statCard(
            icon: Icons.check_circle_outline,
            value: '$activeKiosks',
            label: 'Kiosks actifs',
            iconColor: Colors.green,
          ),
          _statCard(
            icon: Icons.block_outlined,
            value:
                '${kiosks.length - activeKiosks}',
            label: 'Kiosks inactifs',
            iconColor: Colors.orange,
          ),
        ];

        if (compact) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cards
                .map(
                  (card) => SizedBox(
                    width:
                        (constraints.maxWidth - 10) / 2,
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
            const SizedBox(width: 10),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          _iconBox(
            icon,
            iconColor,
            size: 43,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKioskCard(
    KioskModel kiosk,
  ) {
    final active = kiosk.active;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 650;

          final identity = Row(
            children: [
              _iconBox(
                Icons.point_of_sale_outlined,
                active
                    ? Colors.green
                    : Colors.red,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            kiosk.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w800,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _statusBadge(active),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Kiosk #${kiosk.id}',
                      style: const TextStyle(
                        color: mutedColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final information = Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _infoItem(
                Icons.qr_code_2_outlined,
                'Code',
                kiosk.code,
              ),
              _infoItem(
                Icons.location_on_outlined,
                'Lieu',
                kiosk.location,
              ),
              _infoItem(
                Icons.lan_outlined,
                'IP',
                kiosk.ipAddress,
              ),
              _infoItem(
                Icons.access_time_outlined,
                'Connexion',
                kiosk.lastConnection
                    ?.toString(),
              ),
            ],
          );

          final actions = PopupMenuButton<String>(
            tooltip: 'Actions',
            onSelected: (value) {
              if (value == 'toggle') {
                _toggleKiosk(kiosk.id);
              }

              if (value == 'delete') {
                _deleteKiosk(kiosk.id);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      active
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      color: active
                          ? Colors.orange
                          : Colors.green,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      active
                          ? 'Désactiver'
                          : 'Activer',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Supprimer',
                    ),
                  ],
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: identity,
                    ),
                    actions,
                  ],
                ),
                const SizedBox(height: 18),
                information,
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    identity,
                    const SizedBox(height: 16),
                    information,
                  ],
                ),
              ),
              actions,
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // ADMINISTRATORS
  // ============================================================

  Widget _buildAdministratorsTab() {
    return _pageContainer(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _settingsCard(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  icon: Icons.people_outline,
                  title: 'Administrateurs',
                  subtitle:
                      'Gérez les utilisateurs ayant accès à cette organisation.',
                ),
                const SizedBox(height: 24),
                _buildInfoBanner(
                  icon: Icons.admin_panel_settings_outlined,
                  title:
                      'Gestion des accès organisationnels',
                  message:
                      'Un même utilisateur peut appartenir à plusieurs organisations. Son rôle et ses permissions peuvent être différents selon l’organisation active.',
                ),
                const SizedBox(height: 22),
                _buildAdminPreview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPreview() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.people_outline,
              size: 30,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Gestion des administrateurs',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Cette section permettra de consulter les membres de l’organisation, leurs rôles et leurs permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _badge(
            'Gestion avancée à venir',
            primaryColor,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 700;

        final header = Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _iconBox(
              icon,
              primaryColor,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (action == null) {
          return header;
        }

        if (compact) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 15),
              action,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: header,
            ),
            const SizedBox(width: 18),
            action,
          ],
        );
      },
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

  Widget _settingsCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // COUNT HEADER
  // ============================================================

  Widget _buildCountHeader({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: mutedColor,
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: mutedColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: primaryColor.withValues(
              alpha: 0.06,
            ),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFO BANNER
  // ============================================================

  Widget _buildInfoBanner({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 55,
        horizontal: 25,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: 0.05,
              ),
              borderRadius:
                  BorderRadius.circular(22),
            ),
            child: Icon(
              icon,
              size: 34,
              color: const Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 480,
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedColor,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          if (buttonText != null &&
              onPressed != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(
                Icons.add,
                size: 18,
              ),
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

  Widget _iconBox(
    IconData icon,
    Color color, {
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.48,
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _badge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(bool active) {
    return _badge(
      active ? 'ACTIF' : 'INACTIF',
      active ? Colors.green : Colors.red,
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem(
    IconData icon,
    String label,
    dynamic value,
  ) {
    final text =
        value?.toString().trim() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: mutedColor,
          ),
          const SizedBox(width: 6),
          Text(
            '$label : ',
            style: const TextStyle(
              color: mutedColor,
              fontSize: 11,
            ),
          ),
          Text(
            text.isEmpty ? '-' : text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
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
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: mutedColor,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: mutedColor,
        ),
        filled: true,
        fillColor: const Color(0xFFFCFDFE),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
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
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(11),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
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
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  _iconBox(
                    Icons.apartment_outlined,
                    primaryColor,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nouveau département',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 470,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _inputField(
                      controller:
                          _deptNameController,
                      label:
                          'Nom du département',
                      icon:
                          Icons.apartment_outlined,
                    ),
                    const SizedBox(height: 15),
                    _inputField(
                      controller:
                          _deptDescController,
                      label: 'Description',
                      icon:
                          Icons.description_outlined,
                    ),
                  ],
                ),
              ),
              actionsPadding:
                  const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                18,
              ),
              actions: [
                TextButton(
                  onPressed: departmentLoading
                      ? null
                      : () =>
                          Navigator.pop(
                            dialogContext,
                          ),
                  child: const Text(
                    'Annuler',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: departmentLoading
                      ? null
                      : () async {
                          setDialogState(() {});
                          await _createDepartment();
                        },
                  icon: departmentLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.add,
                          size: 18,
                        ),
                  label: const Text(
                    'Créer',
                  ),
                  style:
                      _primaryButtonStyle(),
                ),
              ],
            );
          },
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
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  _iconBox(
                    Icons.point_of_sale_outlined,
                    primaryColor,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nouveau kiosk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _inputField(
                        controller:
                            _kioskNameController,
                        label: 'Nom du kiosk',
                        icon:
                            Icons.devices_outlined,
                      ),
                      const SizedBox(height: 15),
                      _inputField(
                        controller:
                            _kioskLocationController,
                        label: 'Emplacement',
                        icon: Icons
                            .location_on_outlined,
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            _kioskMethod,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Méthode de pointage',
                          prefixIcon:
                              const Icon(
                            Icons
                                .fingerprint_outlined,
                            size: 20,
                          ),
                          filled: true,
                          fillColor:
                              const Color(
                            0xFFFCFDFE,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  borderColor,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  borderColor,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'KIOSK_QR',
                            child:
                                Text('Kiosk QR'),
                          ),
                          DropdownMenuItem(
                            value: 'KIOSK_PIN',
                            child:
                                Text('Kiosk PIN'),
                          ),
                          DropdownMenuItem(
                            value: 'MOBILE',
                            child:
                                Text('Mobile'),
                          ),
                          DropdownMenuItem(
                            value: 'MANUAL',
                            child:
                                Text('Manuel'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            _kioskMethod = value;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      _inputField(
                        controller:
                            _kioskIpController,
                        label:
                            'Adresse IP (optionnel)',
                        icon:
                            Icons.lan_outlined,
                        keyboardType:
                            TextInputType.text,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF8FAFC,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 12,
                          ),
                          title: const Text(
                            'Kiosk actif',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          subtitle:
                              const Text(
                            'Autoriser cet appareil à effectuer les pointages.',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  mutedColor,
                            ),
                          ),
                          value: _kioskActive,
                          onChanged: (value) {
                            setDialogState(() {
                              _kioskActive = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding:
                  const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                18,
              ),
              actions: [
                TextButton(
                  onPressed: kioskLoading
                      ? null
                      : () =>
                          Navigator.pop(
                            dialogContext,
                          ),
                  child: const Text(
                    'Annuler',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: kioskLoading
                      ? null
                      : _createKiosk,
                  icon: kioskLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.add,
                          size: 18,
                        ),
                  label: const Text(
                    'Créer le kiosk',
                  ),
                  style:
                      _primaryButtonStyle(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}