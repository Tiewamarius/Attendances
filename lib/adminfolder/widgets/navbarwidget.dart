import 'package:flutter/material.dart';

class ResponsiveNavbar extends StatelessWidget implements PreferredSizeWidget {
  const ResponsiveNavbar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Définition des breakpoints
    bool isDesktop = screenWidth >= 1024;
    bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    bool isMobile = screenWidth < 600;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 70,
      automaticallyImplyLeading: isMobile || isTablet, // Affiche le menu Burger sur mobile/tablette si nécessaire
      title: Row(
        children: [
          // Logo ou Titre (Optionnel)
          if (isDesktop) ...[
            const Text(
              'MonApp',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 24),
          ],

          // Barre de recherche (s'adapte en largeur)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Actions masquées ou réduites sur mobile si l'espace manque
        if (!isMobile) ...[
          _buildIconButton(
            icon: Icons.dark_mode_outlined,
            onPressed: () {},
            badge: false,
          ),
          const SizedBox(width: 8),
          _buildCartButton(),
          const SizedBox(width: 8),
          _buildNotificationButton(),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.grid_view_rounded,
            onPressed: () {},
            badge: false,
          ),
          const SizedBox(width: 16),
        ] else ...[
          // Sur mobile, on garde le panier ou un menu déroulant par exemple
          _buildCartButton(),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
              // Ouvrir un Drawer ou un BottomSheet sur mobile
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ],

        // Avatar utilisateur (toujours visible)
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            // Remplacez par NetworkImage pour une vraie image
            backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'),
          ),
        ),
      ],
    );
  }

  // Bouton icône standard
  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed, required bool badge}) {
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

  // Bouton Panier avec Badge橘 (1)
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
            onPressed: () {},
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
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: const Text(
              '1',
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

  // Bouton Notification avec point bleu
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
            onPressed: () {},
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