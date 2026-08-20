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

  List<String> roles = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      /*
      On récupère d'abord les données locales.
      */

      final savedUser = await AuthService.getSavedUser();
      final savedRoles = await AuthService.getSavedRoles();

      if (mounted) {
        setState(() {
          user = savedUser;
          roles = savedRoles;
          loading = false;
        });
      }

      /*
      Ensuite on demande les vraies données au backend.
      */

      final data = await AuthService.getCurrentUser();

      if (data != null && mounted) {
        setState(() {
          user = data['user'] != null
              ? Map<String, dynamic>.from(data['user'])
              : user;

          roles = data['roles'] != null
              ? List<String>.from(data['roles'])
              : roles;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement utilisateur : $e');

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String get userName {
    return user?['name']?.toString() ?? 'Utilisateur';
  }

  String get userEmail {
    return user?['email']?.toString() ?? '';
  }

  String get role {
    if (roles.contains('super_admin')) {
      return 'SUPER ADMIN';
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

  Color get roleColor {
    if (roles.contains('super_admin')) {
      return Colors.indigo;
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

    return Colors.blue;
  }

  String get initials {
    final name = userName.trim();

    if (name.isEmpty) {
      return 'U';
    }

    final parts = name.split(' ');

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      color: Colors.white,
      child: Row(
        children: [
          const Spacer(),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile) ...[
                _buildIconButton(
                  icon: Icons.dark_mode_outlined,
                  onPressed: () {
                    _showCustomModal(
                      context,
                      'Mode sombre',
                      "Options d'affichage et de thème.",
                    );
                  },
                ),

                const SizedBox(width: 12),
              ],

              _buildNotificationButton(),

              const SizedBox(width: 16),

              /*
              PROFIL
              */
              InkWell(
                onTap: () {
                  widget.onSelectPage('/admins/settings');
                },
                borderRadius: BorderRadius.circular(30),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: roleColor.withOpacity(0.15),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (!isMobile) ...[
                      const SizedBox(width: 10),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loading ? 'Chargement...' : userName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
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
        icon: Icon(icon, color: Colors.grey[700], size: 20),
        onPressed: onPressed,
      ),
    );
  }

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
          child: CircleAvatar(radius: 4, backgroundColor: Colors.blue),
        ),
      ],
    );
  }

  void _showCustomModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Fermer',
                style: TextStyle(color: Color(0xFF4F46E5)),
              ),
            ),
          ],
        );
      },
    );
  }
}
