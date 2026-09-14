import 'package:flutter/material.dart';

import 'package:attendance/controllers/admin/settings/settings_controller.dart';

import 'package:attendance/models/department_model.dart';
import 'package:attendance/models/kiosk_model.dart';
import 'package:attendance/models/user_model.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({
    super.key,
  });

  @override
  State<AdminSettingsPage> createState() =>
      _AdminSettingsPageState();
}

class _AdminSettingsPageState
    extends State<AdminSettingsPage> {
  late final SettingsController controller;

  static const Color backgroundColor =
      Color(0xFFF8FAFC);

  static const Color panelColor =
      Colors.white;

  static const Color textColor =
      Color(0xFF172033);

  static const Color secondaryTextColor =
      Color(0xFF667085);

  static const Color primaryColor =
      Color(0xFF060606);

  static const Color borderColor =
      Color(0xFFE4E7EC);

  static const Color dangerColor =
      Color(0xFFD13438);

  static const Color successColor =
      Color(0xFF107C10);

  static const Color warningColor =
      Color(0xFFD83B01);

  @override
  void initState() {
    super.initState();

    controller = SettingsController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.initialize();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          color: backgroundColor,
          width: double.infinity,
          height: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 850;

              if (isMobile) {
                return _buildMobileLayout();
              }

              return _buildDesktopLayout();
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 250,
          child: _buildNavigation(),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: borderColor,
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileNavigation(),
        const Divider(
          height: 1,
          color: borderColor,
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildNavigation() {
    return Container(
      color: panelColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Paramètres',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gérez votre organisation',
            style: TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 28),
          _buildNavigationItem(
            icon: Icons.person_outline,
            label: 'Profil',
            section: SettingsSection.profile,
          ),
          const SizedBox(height: 6),
          _buildNavigationItem(
            icon: Icons.apartment_outlined,
            label: 'Départements',
            section: SettingsSection.departments,
          ),
          const SizedBox(height: 6),
          _buildNavigationItem(
            icon: Icons.devices_outlined,
            label: 'Kiosques',
            section: SettingsSection.kiosks,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String label,
    required SettingsSection section,
  }) {
    final selected = controller.section == section;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => controller.selectSection(section),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF0F0F0)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? primaryColor
                  : secondaryTextColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: selected
                      ? textColor
                      : secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavigation() {
    return Container(
      width: double.infinity,
      color: panelColor,
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        14,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMobileTab(
              icon: Icons.person_outline,
              label: 'Profil',
              section: SettingsSection.profile,
            ),
            const SizedBox(width: 8),
            _buildMobileTab(
              icon: Icons.apartment_outlined,
              label: 'Départements',
              section: SettingsSection.departments,
            ),
            const SizedBox(width: 8),
            _buildMobileTab(
              icon: Icons.devices_outlined,
              label: 'Kiosques',
              section: SettingsSection.kiosks,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTab({
    required IconData icon,
    required String label,
    required SettingsSection section,
  }) {
    final selected = controller.section == section;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => controller.selectSection(section),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor
              : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? Colors.white
                  : secondaryTextColor,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (controller.isInitializing) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    switch (controller.section) {
      case SettingsSection.profile:
        return _buildProfileSection();

      case SettingsSection.departments:
        return _buildDepartmentsSection();

      case SettingsSection.kiosks:
        return _buildKiosksSection();
    }
  }

  Widget _buildProfileSection() {
    final profile = controller.profileController;

    if (profile.isLoading && profile.user == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (profile.user == null) {
      return _buildErrorState(
        message:
            profile.errorMessage ??
            'Impossible de charger votre profil.',
        onRetry: profile.loadprofile,
      );
    }

    final user = profile.user!;

    return _buildScrollableContent(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            title: 'Profil',
            subtitle:
                'Gérez vos informations personnelles et votre sécurité.',
          ),
          const SizedBox(height: 24),
          _buildProfileCard(user),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return _buildPanel(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(user),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color:
                            secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Divider(
            height: 1,
            color: borderColor,
          ),
          const SizedBox(height: 22),
          _buildInfoGrid([
            _InfoItem(
              label: 'Nom',
              value: user.name,
              icon: Icons.person_outline,
            ),
            _InfoItem(
              label: 'Email',
              value: user.email,
              icon: Icons.email_outlined,
            ),
            _InfoItem(
              label: 'Rôle',
              value: user.role ?? 'Non défini',
              icon: Icons.badge_outlined,
            ),
            _InfoItem(
              label: 'Identifiant',
              value: '#${user.id}',
              icon: Icons.tag,
            ),
          ]),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    _showEditProfileDialog(user),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                ),
                label: const Text('Modifier le profil'),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _showChangePasswordDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.lock_outline,
                  size: 18,
                ),
                label: const Text(
                  'Changer le mot de passe',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentsSection() {
    final departmentController =
        controller.departmentController;

    return _buildScrollableContent(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            title: 'Départements',
            subtitle:
                'Organisez vos employés par département.',
            action: ElevatedButton.icon(
              onPressed: () =>
                  _showDepartmentDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(
                Icons.add,
                size: 18,
              ),
              label: const Text('Ajouter'),
            ),
          ),
          const SizedBox(height: 24),
          if (departmentController.isLoading &&
              departmentController.departments.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (departmentController.errorMessage !=
                  null &&
              departmentController.departments.isEmpty)
            _buildErrorState(
              message:
                  departmentController.errorMessage!,
              onRetry:
                  departmentController.loaddepartments,
            )
          else if (departmentController.departments.isEmpty)
            _buildEmptyState(
              icon: Icons.apartment_outlined,
              title: 'Aucun département',
              message:
                  'Commencez par créer votre premier département.',
              action: ElevatedButton.icon(
                onPressed: () =>
                    _showDepartmentDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Créer un département'),
              ),
            )
          else
            _buildDepartmentGrid(
              departmentController.departments,
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentGrid(
    List<DepartmentModel> departments,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1200
            ? 3
            : width >= 700
                ? 2
                : 1;

        final spacing = 16.0;

        final itemWidth =
            (width - ((columns - 1) * spacing)) /
                columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: departments.map((department) {
            return SizedBox(
              width: itemWidth,
              child: _buildDepartmentCard(
                department,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDepartmentCard(
    DepartmentModel department,
  ) {
    return _buildPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.apartment_outlined,
                  color: textColor,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'Actions',
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showDepartmentDialog(
                      department: department,
                    );
                  }

                  if (value == 'delete') {
                    await _confirmDeleteDepartment(
                      department,
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.edit_outlined,
                      ),
                      title: Text('Modifier'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline,
                        color: dangerColor,
                      ),
                      title: Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            department.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            department.description.isEmpty
                ? 'Aucune description'
                : department.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKiosksSection() {
    final kioskController =
        controller.kioskController;
    final kioskList = kioskController.kiosks;

    return _buildScrollableContent(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            title: 'Kiosques',
            subtitle:
                'Gérez les terminaux utilisés pour les présences.',
            action: ElevatedButton.icon(
              onPressed: () => _showKioskDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(
                Icons.add,
                size: 18,
              ),
              label: const Text('Ajouter'),
            ),
          ),
          const SizedBox(height: 24),
          if (kioskController.isLoading &&
              kioskList.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (kioskController.errorMessage != null &&
              kioskList.isEmpty)
            _buildErrorState(
              message: kioskController.errorMessage!,
              onRetry: () async {},
            )
          else if (kioskList.isEmpty)
            _buildEmptyState(
              icon: Icons.devices_outlined,
              title: 'Aucun kiosque',
              message:
                  'Ajoutez un kiosque pour permettre les pointages.',
              action: ElevatedButton.icon(
                onPressed: () =>
                    _showKioskDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Créer un kiosque'),
              ),
            )
          else
            _buildKioskGrid(kioskList),
        ],
      ),
    );
  }

  Widget _buildKioskGrid(List<KioskModel> kiosks) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1300
            ? 3
            : width >= 750
                ? 2
                : 1;

        final spacing = 16.0;

        final itemWidth =
            (width - ((columns - 1) * spacing)) /
                columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: kiosks.map((kiosk) {
            return SizedBox(
              width: itemWidth,
              child: _buildKioskCard(kiosk),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildKioskCard(KioskModel kiosk) {
    return _buildPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kiosk.active
                      ? const Color(0xFFEFF8F0)
                      : const Color(0xFFF2F4F7),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.devices_outlined,
                  color: kiosk.active
                      ? successColor
                      : secondaryTextColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  kiosk.name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Actions',
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      _showKioskDialog(
                        kiosk: kiosk,
                      );
                      break;

                    case 'toggle':
                      await _toggleKiosk(kiosk);
                      break;

                    case 'delete':
                      await _confirmDeleteKiosk(kiosk);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.edit_outlined,
                      ),
                      title: Text('Modifier'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        kiosk.active
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                      ),
                      title: Text(
                        kiosk.active
                            ? 'Désactiver'
                            : 'Activer',
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline,
                        color: dangerColor,
                      ),
                      title: Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildKioskInfo(
            Icons.key_outlined,
            'Code',
            kiosk.code,
          ),
          _buildKioskInfo(
            Icons.settings_outlined,
            'Mode',
            _modeLabel(kiosk.mode),
          ),
          _buildKioskInfo(
            Icons.location_on_outlined,
            'Emplacement',
            _displayValue(kiosk.location),
          ),
          _buildKioskInfo(
            Icons.lan_outlined,
            'Adresse IP',
            _displayValue(kiosk.ipAddress),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: kiosk.active
                      ? successColor
                      : dangerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                kiosk.active
                    ? 'Actif'
                    : 'Inactif',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kiosk.active
                      ? successColor
                      : dangerColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKioskInfo(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: secondaryTextColor,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader({
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

        if (compact) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 14),
                action,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) action,
          ],
        );
      },
    );
  }

  Widget _buildScrollableContent({
    required Widget child,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 500,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPanel({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(24),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: child,
    );
  }

  Widget _buildAvatar(UserModel user) {
    final initials = user.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .take(2)
        .map((item) => item[0].toUpperCase())
        .join();

    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoGrid(List<_InfoItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 700 ? 2 : 1;

        final spacing = 14.0;

        final itemWidth = columns == 2
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding:
                    const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 19,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color:
                                  secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.value,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildErrorState({
    required String message,
    required Future<void> Function() onRetry,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
        ),
        child: _buildPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: dangerColor,
              ),
              const SizedBox(height: 14),
              const Text(
                'Une erreur est survenue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.refresh,
                  size: 18,
                ),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        child: _buildPanel(
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: secondaryTextColor,
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 18),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(
    UserModel user,
  ) async {
    final nameController =
        TextEditingController(text: user.name);

    final emailController =
        TextEditingController(text: user.email);

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              context,
              setStateDialog,
            ) {
              final profileController =
                  controller.profileController;

              return AlertDialog(
                title: const Text(
                  'Modifier le profil',
                ),
                content: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        textInputAction:
                            TextInputAction.next,
                        decoration:
                            const InputDecoration(
                          labelText: 'Nom',
                          prefixIcon: Icon(
                            Icons.person_outline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        decoration:
                            const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                          ),
                        ),
                      ),
                      if (profileController.errorMessage !=
                          null) ...[
                        const SizedBox(height: 14),
                        _dialogError(
                          profileController.errorMessage!,
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: profileController.isSaving
                        ? null
                        : () =>
                            Navigator.pop(dialogContext),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: profileController.isSaving
                        ? null
                        : () async {
                            final success =
                                await profileController
                                    .updateProfile(
                              name:
                                  nameController.text,
                              email:
                                  emailController.text,
                            );

                            if (!mounted) {
                              return;
                            }

                            if (success) {
                              Navigator.pop(
                                dialogContext,
                              );

                              _showSnackBar(
                                'Profil mis à jour.',
                              );
                            } else {
                              setStateDialog(() {});
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: profileController.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentController =
        TextEditingController();

    final newController =
        TextEditingController();

    final confirmationController =
        TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              context,
              setStateDialog,
            ) {
              final profileController =
                  controller.profileController;

              return AlertDialog(
                title: const Text(
                  'Changer le mot de passe',
                ),
                content: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: currentController,
                        obscureText: true,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Mot de passe actuel',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: newController,
                        obscureText: true,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Nouveau mot de passe',
                          prefixIcon: Icon(
                            Icons.lock_reset_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller:
                            confirmationController,
                        obscureText: true,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Confirmer le mot de passe',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                          ),
                        ),
                      ),
                      if (profileController.errorMessage !=
                          null) ...[
                        const SizedBox(height: 14),
                        _dialogError(
                          profileController.errorMessage!,
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: profileController.isSaving
                        ? null
                        : () =>
                            Navigator.pop(dialogContext),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: profileController.isSaving
                        ? null
                        : () async {
                            final success =
                                await profileController
                                    .changePassword(
                              currentPassword:
                                  currentController.text,
                              newPassword:
                                  newController.text,
                              confirmation:
                                  confirmationController
                                      .text,
                            );

                            if (!mounted) {
                              return;
                            }

                            if (success) {
                              Navigator.pop(
                                dialogContext,
                              );

                              _showSnackBar(
                                'Mot de passe modifié.',
                              );
                            } else {
                              setStateDialog(() {});
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: profileController.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Modifier'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      currentController.dispose();
      newController.dispose();
      confirmationController.dispose();
    }
  }

  Future<void> _showDepartmentDialog({
    DepartmentModel? department,
  }) async {
    final isEditing = department != null;

    final nameController = TextEditingController(
      text: department?.name ?? '',
    );

    final descriptionController =
        TextEditingController(
      text: department?.description ?? '',
    );

    final departmentController =
        controller.departmentController;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              context,
              setStateDialog,
            ) {
              return AlertDialog(
                title: Text(
                  isEditing
                      ? 'Modifier le département'
                      : 'Nouveau département',
                ),
                content: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Nom',
                          prefixIcon: Icon(
                            Icons.apartment_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller:
                            descriptionController,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(
                            Icons.description_outlined,
                          ),
                        ),
                      ),
                      if (departmentController
                              .errorMessage !=
                          null) ...[
                        const SizedBox(height: 14),
                        _dialogError(
                          departmentController
                              .errorMessage!,
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        departmentController.isSaving
                            ? null
                            : () => Navigator.pop(
                                  dialogContext,
                                ),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed:
                        departmentController.isSaving
                            ? null
                            : () async {
                                bool success;

                                if (isEditing) {
                                  final dynamic departmentService =
                                      departmentController;

                                  try {
                                    success = await departmentService
                                        .update(
                                      department!.id,
                                      name:
                                          nameController.text,
                                      description:
                                          descriptionController
                                              .text,
                                    ) as bool;
                                  } catch (_) {
                                    success = await departmentService
                                        .updateDepartment(
                                      department.id,
                                      name:
                                          nameController.text,
                                      description:
                                          descriptionController
                                              .text,
                                    ) as bool;
                                  }
                                } else {
                                  success =
                                      await departmentController
                                          .create(
                                    name:
                                        nameController.text,
                                    description:
                                        descriptionController
                                            .text,
                                  );
                                }

                                if (!mounted) {
                                  return;
                                }

                                if (success) {
                                  Navigator.pop(
                                    dialogContext,
                                  );

                                  _showSnackBar(
                                    isEditing
                                        ? 'Département modifié.'
                                        : 'Département créé.',
                                  );
                                } else {
                                  setStateDialog(() {});
                                }
                              },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        departmentController.isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditing
                                    ? 'Enregistrer'
                                    : 'Créer',
                              ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _showKioskDialog({
    KioskModel? kiosk,
  }) async {
    final isEditing = kiosk != null;

    final nameController = TextEditingController(
      text: kiosk?.name ?? '',
    );

    final codeController = TextEditingController(
      text: kiosk?.code ?? '',
    );

    final locationController =
        TextEditingController(
      text: kiosk?.location ?? '',
    );

    final ipController = TextEditingController(
      text: kiosk?.ipAddress ?? '',
    );

    String selectedMode =
        kiosk?.mode ?? 'KIOSK_QR';

    final kioskController =
        controller.kioskController;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              context,
              setStateDialog,
            ) {
              return AlertDialog(
                title: Text(
                  isEditing
                      ? 'Modifier le kiosque'
                      : 'Nouveau kiosque',
                ),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration:
                              const InputDecoration(
                            labelText: 'Nom',
                            prefixIcon: Icon(
                              Icons.devices_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: codeController,
                          decoration:
                              const InputDecoration(
                            labelText: 'Code',
                            prefixIcon: Icon(
                              Icons.key_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedMode,
                          decoration:
                              const InputDecoration(
                            labelText: 'Mode',
                            prefixIcon: Icon(
                              Icons.settings_outlined,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'KIOSK_QR',
                              child: Text(
                                'Kiosque QR',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'KIOSK_PIN',
                              child: Text(
                                'Kiosque PIN',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'MOBILE',
                              child: Text(
                                'Mobile',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'MANUAL',
                              child: Text(
                                'Manuel',
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setStateDialog(() {
                              selectedMode = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller:
                              locationController,
                          decoration:
                              const InputDecoration(
                            labelText: 'Emplacement',
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: ipController,
                          keyboardType:
                              TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration:
                              const InputDecoration(
                            labelText: 'Adresse IP',
                            prefixIcon: Icon(
                              Icons.lan_outlined,
                            ),
                          ),
                        ),
                        if (kioskController
                                .errorMessage !=
                            null) ...[
                          const SizedBox(height: 14),
                          _dialogError(
                            kioskController
                                .errorMessage!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        kioskController.isLoading
                            ? null
                            : () => Navigator.pop(
                                  dialogContext,
                                ),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed:
                        kioskController.isLoading
                            ? null
                            : () async {
                                bool success;

                                if (isEditing) {
                                  final dynamic kioskService =
                                      kioskController;

                                  try {
                                    success = await kioskService
                                        .update(
                                      kiosk!.id,
                                      name:
                                          nameController.text,
                                      code:
                                          codeController.text,
                                      location:
                                          locationController
                                              .text,
                                      mode: selectedMode,
                                      ipAddress:
                                          ipController.text,
                                    ) as bool;
                                  } catch (_) {
                                    try {
                                      success = await kioskService
                                          .updateKiosk(
                                        kiosk.id,
                                        name:
                                            nameController.text,
                                        code:
                                            codeController.text,
                                        location:
                                            locationController
                                                .text,
                                        mode: selectedMode,
                                        ipAddress:
                                            ipController.text,
                                      ) as bool;
                                    } catch (_) {
                                      success = await kioskService
                                          .save(
                                        kiosk.id,
                                        name:
                                            nameController.text,
                                        code:
                                            codeController.text,
                                        location:
                                            locationController
                                                .text,
                                        mode: selectedMode,
                                        ipAddress:
                                            ipController.text,
                                      ) as bool;
                                    }
                                  }
                                } else {
                                  success =
                                    await (kioskController as dynamic)
                                      .createKiosk(
                                    name:
                                        nameController.text,
                                    code:
                                        codeController.text,
                                    location:
                                        locationController
                                            .text,
                                    mode: selectedMode,
                                    ipAddress:
                                        ipController.text,
                                  );
                                }

                                if (!mounted) {
                                  return;
                                }

                                if (success) {
                                  Navigator.pop(
                                    dialogContext,
                                  );

                                  _showSnackBar(
                                    isEditing
                                        ? 'Kiosque modifié.'
                                        : 'Kiosque créé.',
                                  );
                                } else {
                                  setStateDialog(() {});
                                }
                              },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: kioskController.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditing
                                ? 'Enregistrer'
                                : 'Créer',
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      codeController.dispose();
      locationController.dispose();
      ipController.dispose();
    }
  }

  Future<void> _confirmDeleteDepartment(
    DepartmentModel department,
  ) async {
    final confirmed = await _confirmDialog(
      title: 'Supprimer le département',
      message:
          'Voulez-vous vraiment supprimer « ${department.name} » ?',
    );

    if (!confirmed || !mounted) {
      return;
    }

    final success = await controller
        .departmentController
        .delete(department.id);

    if (!mounted) {
      return;
    }

    _showSnackBar(
      success
          ? 'Département supprimé.'
          : controller.departmentController.errorMessage ??
              'Suppression impossible.',
      error: !success,
    );
  }

  Future<void> _confirmDeleteKiosk(
    KioskModel kiosk,
  ) async {
    final confirmed = await _confirmDialog(
      title: 'Supprimer le kiosque',
      message:
          'Voulez-vous vraiment supprimer « ${kiosk.name} » ?',
    );

    if (!confirmed || !mounted) {
      return;
    }

    final kioskService = controller.kioskController;
    bool success;

    try {
      success = await (kioskService as dynamic)
          .delete(kiosk.id) as bool;
    } catch (_) {
      success = await (kioskService as dynamic)
          .deleteKiosk(kiosk.id) as bool;
    }

    if (!mounted) {
      return;
    }

    _showSnackBar(
      success
          ? 'Kiosque supprimé.'
          : controller.kioskController.errorMessage ??
              'Suppression impossible.',
      error: !success,
    );
  }

  Future<void> _toggleKiosk(
    KioskModel kiosk,
  ) async {
    final kioskService = controller.kioskController;
    final nextActive = !kiosk.active;
    bool success;

    try {
      success = await (kioskService as dynamic)
          .toggle(kiosk) as bool;
    } catch (_) {
      try {
        success = await (kioskService as dynamic)
            .toggleKiosk(kiosk.id) as bool;
      } catch (_) {
        try {
          success = await (kioskService as dynamic)
              .updateStatus(
            kiosk.id,
            active: nextActive,
          ) as bool;
        } catch (_) {
          success = false;
        }
      }
    }

    if (!mounted) {
      return;
    }

    _showSnackBar(
      success
          ? nextActive
              ? 'Kiosque activé.'
              : 'Kiosque désactivé.'
          : controller.kioskController.errorMessage ??
              'Modification impossible.',
      error: !success,
    );
  }

  Future<bool> _confirmDialog({
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
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _dialogError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF5C2C7),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          color: dangerColor,
        ),
      ),
    );
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'KIOSK_QR':
        return 'Kiosque QR';

      case 'KIOSK_PIN':
        return 'Kiosque PIN';

      case 'MOBILE':
        return 'Mobile';

      case 'MANUAL':
        return 'Manuel';

      default:
        return mode;
    }
  }

  String _displayValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Non renseigné';
    }

    return value.trim();
  }

  void _showSnackBar(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              error ? dangerColor : primaryColor,
        ),
      );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}