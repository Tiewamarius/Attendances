import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/core/res/responsive.dart';
import 'package:flutter/material.dart';

class NavbarWidget extends StatefulWidget implements PreferredSizeWidget {
  final Function(String) onSelectPage;
  final String selectedPage;
  final VoidCallback? onMenuPressed;

  const NavbarWidget({
    super.key,
    required this.selectedPage,
    required this.onSelectPage,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  Map<String, dynamic>? user;

  Map<String, dynamic>? organization;

  List<Map<String, dynamic>> organizations = [];

  List<String> roles = [];

  List<String> permissions = [];

  bool loading = true;
  bool switchingOrganization = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  // ===========================================================================
  // CHARGEMENT DE LA SESSION
  // ===========================================================================

  Future<void> _loadSession() async {
    try {
      // -----------------------------------------------------------------------
      // 1. Charger immédiatement les données locales
      // -----------------------------------------------------------------------

      final savedUser = await AuthService.getSavedUser();
      final savedOrganization =
          await AuthService.getSavedOrganization();

      final savedOrganizations =
          await AuthService.getSavedOrganizations();

      final savedRoles =
          await AuthService.getSavedRoles();

      final savedPermissions =
          await AuthService.getSavedPermissions();

      if (mounted) {
        setState(() {
          user = savedUser;
          organization = savedOrganization;
          organizations = savedOrganizations;
          roles = savedRoles;
          permissions = savedPermissions;
          loading = false;
        });
      }

      // -----------------------------------------------------------------------
      // 2. Ensuite récupérer les informations réelles du backend
      // -----------------------------------------------------------------------

      final data = await AuthService.getCurrentUser();

      if (data != null && mounted) {
        final backendUser = data['user'];

        final backendOrganization = data['organization'];

        final backendRoles = data['roles'];

        final backendPermissions = data['permissions'];

        setState(() {
          if (backendUser is Map) {
            user = Map<String, dynamic>.from(backendUser);
          }

          if (backendOrganization is Map) {
            organization =
                Map<String, dynamic>.from(backendOrganization);
          }

          if (backendRoles is List) {
            roles = List<String>.from(backendRoles);
          }

          if (backendPermissions is List) {
            permissions = List<String>.from(backendPermissions);
          }
        });

        // ---------------------------------------------------------------------
        // Sauvegarder les informations fraîches
        // ---------------------------------------------------------------------

        if (backendOrganization is Map) {
          await AuthService.saveActiveOrganization(
            Map<String, dynamic>.from(backendOrganization),
          );
        }

        await AuthService.saveRoles(roles);
        await AuthService.savePermissions(permissions);
      }
    } catch (e) {
      debugPrint(
        '[NAVBAR] Erreur chargement session : $e',
      );

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ===========================================================================
  // UTILISATEUR
  // ===========================================================================

  String get userName {
    return user?['name']?.toString() ?? 'Utilisateur';
  }

  String get userEmail {
    return user?['email']?.toString() ?? '';
  }

  // ===========================================================================
  // ORGANISATION ACTIVE
  // ===========================================================================

  String get organizationName {
    return organization?['name']?.toString() ??
        'Organisation';
  }

  String get organizationSlug {
    return organization?['slug']?.toString() ?? '';
  }

  // ===========================================================================
  // ROLE
  // ===========================================================================

  String get role {
    if (roles.contains('super_admin')) {
      return 'SUPER ADMIN';
    }

    if (roles.contains('organization_admin')) {
      return 'ADMIN';
    }

    if (roles.contains('admin_rh')) {
      return 'RH';
    }

    if (roles.contains('manager')) {
      return 'MANAGER';
    }

    if (roles.contains('kiosk')) {
      return 'KIOSK';
    }

    if (roles.contains('employee')) {
      return 'EMPLOYÉ';
    }

    return 'UTILISATEUR';
  }

  // ===========================================================================
  // COULEUR DU ROLE
  // ===========================================================================

  Color get roleColor {
    if (roles.contains('super_admin')) {
      return Colors.indigo;
    }

    if (roles.contains('organization_admin')) {
      return Colors.blue;
    }

    if (roles.contains('admin_rh')) {
      return Colors.green;
    }

    if (roles.contains('manager')) {
      return Colors.orange;
    }

    if (roles.contains('kiosk')) {
      return Colors.purple;
    }

    if (roles.contains('employee')) {
      return Colors.teal;
    }

    return Colors.blueGrey;
  }

  // ===========================================================================
  // INITIALES
  // ===========================================================================

  String get initials {
    final name = userName.trim();

    if (name.isEmpty) {
      return 'U';
    }

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  // ===========================================================================
  // PERMISSION
  // ===========================================================================

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  // ===========================================================================
  // SWITCH ORGANISATION
  // ===========================================================================

  Future<void> _switchOrganization(
    Map<String, dynamic> selectedOrganization,
  ) async {
    final organizationId = selectedOrganization['id'];

    if (organizationId == null) {
      return;
    }

    // Déjà sur cette organisation
    if (organization?['id'] == organizationId) {
      return;
    }

    setState(() {
      switchingOrganization = true;
    });

    try {
      debugPrint(
        '[ORGANIZATION] Changement vers : '
        '${selectedOrganization['name']}',
      );

      final result =
          await AuthService.switchOrganization(
        organizationId,
      );

      if (result == null) {
        throw Exception(
          'Impossible de changer d’organisation.',
        );
      }

      // -----------------------------------------------------------------------
      // Organisation retournée par Laravel
      // -----------------------------------------------------------------------

      final backendOrganization =
          result['organization'];

      final backendRoles =
          result['roles'];

      final backendPermissions =
          result['permissions'];

      if (backendOrganization is Map) {
        final newOrganization =
            Map<String, dynamic>.from(
          backendOrganization,
        );

        await AuthService.saveActiveOrganization(
          newOrganization,
        );

        if (mounted) {
          setState(() {
            organization = newOrganization;
          });
        }
      } else {
        // Sécurité : utiliser l'organisation sélectionnée
        await AuthService.saveActiveOrganization(
          selectedOrganization,
        );

        if (mounted) {
          setState(() {
            organization = selectedOrganization;
          });
        }
      }

      // -----------------------------------------------------------------------
      // Rôles
      // -----------------------------------------------------------------------

      if (backendRoles is List) {
        final newRoles =
            List<String>.from(backendRoles);

        await AuthService.saveRoles(newRoles);

        if (mounted) {
          setState(() {
            roles = newRoles;
          });
        }
      } else {
        await AuthService.saveRoles([]);

        if (mounted) {
          setState(() {
            roles = [];
          });
        }
      }

      // -----------------------------------------------------------------------
      // Permissions
      // -----------------------------------------------------------------------

      if (backendPermissions is List) {
        final newPermissions =
            List<String>.from(backendPermissions);

        await AuthService.savePermissions(
          newPermissions,
        );

        if (mounted) {
          setState(() {
            permissions = newPermissions;
          });
        }
      } else {
        await AuthService.savePermissions([]);

        if (mounted) {
          setState(() {
            permissions = [];
          });
        }
      }

      debugPrint(
        '[ORGANIZATION] Organisation active : '
        '$organizationName',
      );

      debugPrint(
        '[ORGANIZATION] Rôles : $roles',
      );

      debugPrint(
        '[ORGANIZATION] Permissions : $permissions',
      );

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Organisation "$organizationName" sélectionnée.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // ---------------------------------------------------------------------
        // On recharge la page courante pour appliquer les permissions
        // et les données de la nouvelle organisation.
        // ---------------------------------------------------------------------

        widget.onSelectPage(widget.selectedPage);
      }
    } catch (e) {
      debugPrint(
        '[ORGANIZATION] Erreur switch : $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du changement d’organisation : $e',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          switchingOrganization = false;
        });
      }
    }
  }

  // ===========================================================================
  // MODAL ORGANISATIONS
  // ===========================================================================

  void _showOrganizationSelector() {
    if (organizations.isEmpty) {
      _showCustomModal(
        context,
        'Organisation',
        'Aucune organisation disponible.',
      );

      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Changer d’organisation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                ...organizations.map(
                  (item) {
                    final itemId = item['id'];

                    final isActive =
                        organization?['id'] == itemId;

                    return InkWell(
                      borderRadius:
                          BorderRadius.circular(14),
                      onTap: switchingOrganization
                          ? null
                          : () {
                              _switchOrganization(
                                item,
                              );
                            },
                      child: Container(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        padding:
                            const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.blue.withValues(
                                  alpha: 0.08,
                                )
                              : Colors.grey[50],
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? Colors.blue
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  isActive
                                      ? Colors.blue
                                      : Colors.grey[200],
                              child: Text(
                                (item['name']
                                            ?.toString()
                                            .isNotEmpty ??
                                        false)
                                    ? item['name']
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : 'O',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey[700],
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name']
                                            ?.toString() ??
                                        'Organisation',
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 14,
                                      color:
                                          Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (item['slug'] != null)
                                    Text(
                                      item['slug']
                                          .toString(),
                                      style:
                                          const TextStyle(
                                        fontSize: 12,
                                        color:
                                            Color(0xFF64748B),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            if (isActive)
                              const Icon(
                                Icons
                                    .check_circle_rounded,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();

                      widget.onSelectPage(
                        '/organizations/create',
                      );
                    },
                    icon: const Icon(
                      Icons.add_business_rounded,
                    ),
                    label: const Text(
                      'Ajouter une organisation',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        Responsive.isMobile(context);

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
      ),
      color: Colors.white,
      child: Row(
        children: [
          // -------------------------------------------------------------------
          // ORGANISATION ACTIVE
          // -------------------------------------------------------------------

          if (!isMobile)
            InkWell(
              borderRadius:
                  BorderRadius.circular(12),
              onTap: _showOrganizationSelector,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.blue
                            .withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        size: 19,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Organisation active',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          loading
                              ? 'Chargement...'
                              : organizationName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 5),

                    const Icon(
                      Icons
                          .keyboard_arrow_down_rounded,
                      size: 18,
                      color:
                          Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---------------------------------------------------------------
              // ORGANISATION SUR MOBILE
              // ---------------------------------------------------------------

              if (isMobile) ...[
                _buildIconButton(
                  icon:
                      Icons.business_rounded,
                  onPressed:
                      _showOrganizationSelector,
                ),
                const SizedBox(width: 10),
              ],

              // ---------------------------------------------------------------
              // MODE SOMBRE
              // ---------------------------------------------------------------

              if (!isMobile) ...[
                _buildIconButton(
                  icon:
                      Icons.dark_mode_outlined,
                  onPressed: () {
                    _showCustomModal(
                      context,
                      'Mode sombre',
                      "Les options d'affichage et de thème seront disponibles ici.",
                    );
                  },
                ),
                const SizedBox(width: 12),
              ],

              // ---------------------------------------------------------------
              // NOTIFICATIONS
              // ---------------------------------------------------------------

              _buildNotificationButton(),

              const SizedBox(width: 16),

              // ---------------------------------------------------------------
              // PROFIL
              // ---------------------------------------------------------------

              InkWell(
                onTap: () {
                  widget.onSelectPage(
                    '/admins/settings',
                  );
                },
                borderRadius:
                    BorderRadius.circular(30),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor:
                          roleColor.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    if (!isMobile) ...[
                      const SizedBox(width: 10),

                      Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            loading
                                ? 'Chargement...'
                                : userName,
                            style:
                                const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF0F172A),
                            ),
                          ),

                          const SizedBox(height: 2),

                          Row(
                            children: [
                              Text(
                                role,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: roleColor,
                                ),
                              ),

                              if (organizationName
                                  .isNotEmpty) ...[
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  organizationName,
                                  style:
                                      const TextStyle(
                                    fontSize: 10,
                                    color:
                                        Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ICON BUTTON
  // ===========================================================================

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.grey[700],
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }

  // ===========================================================================
  // NOTIFICATIONS
  // ===========================================================================

  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () {
              _showCustomModal(
                context,
                'Notifications',
                'Aucune nouvelle notification.',
              );
            },
          ),
        ),

        const Positioned(
          right: 8,
          top: 8,
          child: CircleAvatar(
            radius: 4,
            backgroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MODAL SIMPLE
  // ===========================================================================

  void _showCustomModal(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Fermer',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}