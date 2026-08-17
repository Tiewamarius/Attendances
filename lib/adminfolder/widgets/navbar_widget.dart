import 'package:flutter/material.dart';
import 'package:attendance/core/res/responsive.dart';

class NavbarWidget extends StatefulWidget implements PreferredSizeWidget {
  final Function(String) onSelectPage;
  final String selectedPage;
  final VoidCallback? onMenuPressed;
  final String userRole; // 'AD', 'RH', 'MG'
  final String? userAvatarUrl; // URL de la photo de profil (null ou vide si non définie)

  const NavbarWidget({
    super.key,
    required this.selectedPage,
    required this.onSelectPage,
    this.onMenuPressed,
    this.userRole = 'AD',
    this.userAvatarUrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  Map<String, dynamic> _getRoleDetails(String role) {
    switch (role.toUpperCase()) {
      case 'RH':
        return {'label': 'RH', 'color': Colors.green, 'title': 'Ressources Humaines'};
      case 'MG':
        return {'label': 'MG', 'color': Colors.orange, 'title': 'Manager'};
      case 'AD':
      default:
        return {'label': 'AD', 'color': Colors.indigo, 'title': 'Administrateur'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final roleInfo = _getRoleDetails(widget.userRole);

    final bool hasAvatar = widget.userAvatarUrl != null && widget.userAvatarUrl!.trim().isNotEmpty;

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 24.0),
      color: Colors.white,
      child: Row(
        children: [
          // Bouton Menu hamburger affiché SEULEMENT sur Tablette et Desktop
          if (!isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF605E5C)),
              onPressed: widget.onMenuPressed ?? () {
                Scaffold.of(context).openDrawer();
              },
            ),
            const SizedBox(width: 8),
          ],

          // Espaceur pour pousser les actions vers la droite
          const Spacer(),

          // Actions de droite adaptées
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile) ...[
                _buildIconButton(
                  icon: Icons.dark_mode_outlined, 
                  onPressed: () => _showCustomModal(context, "Paramètres du Mode Sombre", "Options d'affichage et de thème."),
                ),
                const SizedBox(width: 12),
              ],

              _buildCartButton(),
              const SizedBox(width: 12),
              _buildNotificationButton(),
              
              if (!isMobile) ...[
                const SizedBox(width: 12),
                _buildIconButton(
                  icon: Icons.grid_view_rounded, 
                  onPressed: () => _showCustomModal(context, "Applications Rapides", "Sélectionnez un module ou raccourci système."),
                ),
              ],

              const SizedBox(width: 16),
              
              // Badge de rôle avec l'avatar ou le texte du rôle
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (roleInfo['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: (roleInfo['color'] as Color).withOpacity(0.3)),
                    ),
                    child: Text(
                      roleInfo['label'],
                      style: TextStyle(
                        color: roleInfo['color'],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Avatar utilisateur cliquable (Affiche la photo si présente, sinon les initiales/rôle)
                  InkWell(
                    onTap: () {
                      widget.onSelectPage('/admins/settings');
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: roleInfo['color'].withOpacity(0.2),
                      backgroundImage: hasAvatar ? NetworkImage(widget.userAvatarUrl!) : null,
                      child: !hasAvatar
                          ? Text(
                              roleInfo['label'],
                              style: TextStyle(
                                color: roleInfo['color'],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: Text(
            content,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer', style: TextStyle(color: Color(0xFF4F46E5))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
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

  Widget _buildCartButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 20),
            onPressed: () => _showCustomModal(context, "Panier", "Vous avez 0 article dans votre panier de commandes."),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: const Text(
              '0',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
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
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.grey, size: 20),
            onPressed: () {
              _showCustomModal(context, "Notifications", "Aucune nouvelle notification pour le moment.");
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
}