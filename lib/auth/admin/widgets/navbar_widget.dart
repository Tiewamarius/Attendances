import 'package:flutter/material.dart';

class NavbarWidget extends StatelessWidget implements PreferredSizeWidget {
  const NavbarWidget({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      color: Colors.white,
      child: Row(
        children: [
          // Barre de recherche
          
           Container(
              constraints: const BoxConstraints(maxWidth: 450),
              height: 42,
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
          
          const SizedBox(width: 16),

          // Actions de droite (Mode sombre, Panier, Notifications, Grille, Avatar)
          Row(
            children: [
              _buildIconButton(icon: Icons.dark_mode_outlined, onPressed: () {}),
              const SizedBox(width: 12),
              _buildCartButton(),
              const SizedBox(width: 12),
              _buildNotificationButton(),
              const SizedBox(width: 12),
              _buildIconButton(icon: Icons.grid_view_rounded, onPressed: () {}),
              const SizedBox(width: 20),
              
              // Avatar utilisateur
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget utilitaire pour les boutons icônes
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

  // Bouton Panier avec badge numérique
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
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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

  // Bouton Notifications avec point bleu
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