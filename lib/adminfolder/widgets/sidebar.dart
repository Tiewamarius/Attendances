import 'package:attendance/core/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SideBar extends StatefulWidget {
  final Function(String) onSelectPage;
  final String selectedPage;

  const SideBar({
    super.key,
    required this.selectedPage,
    required this.onSelectPage,
  });

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: height,
      width: screenWidth > 1800
          ? 270
          : screenWidth < 1140
          ? 220
          : 270, // Adjust the width as needed
      color: Colors.white, // Adjust the color as needed
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/icons/logo.svg'),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ATTENDANCES',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Admin Panel',
                            style: GoogleFonts.inter(
                              color: Colors.black45,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                SideBarItem(
                  title: 'Dashboard',
                  icon:
                      'assets/icons/dashboard.svg', // Remplacez par vos icônes spécifiques
                  isSelected: widget.selectedPage == '/admin',
                  onTap: () {
                    widget.onSelectPage('/admin');
                  },
                ),

                SideBarItem(
                  title: 'Employés',
                  icon: 'assets/icons/employees.svg',
                  isSelected: widget.selectedPage == '/employees',
                  onTap: () {
                    widget.onSelectPage('/employees');
                  },
                ),

                SideBarItem(
                  title: 'Présences',
                  icon: 'assets/icons/attendance.svg',
                  isSelected: widget.selectedPage == '/attendance',
                  onTap: () {
                    widget.onSelectPage('/attendance');
                  },
                ),

                SideBarItem(
                  title: 'Congés',
                  icon: 'assets/icons/leaves.svg',
                  isSelected: widget.selectedPage == '/leaves',
                  onTap: () {
                    widget.onSelectPage('/leaves');
                  },
                ),

                SideBarItem(
                  title: 'Rapports',
                  icon: 'assets/icons/Rapports.svg',
                  isSelected: widget.selectedPage == '/reports',
                  onTap: () {
                    widget.onSelectPage('/reports');
                  },
                ),

                const Spacer(),

                SideBarItem(
  title: 'Déconnexion',
  icon: 'assets/icons/logout.svg',
  isSelected: false,
  onTap: () async {

    try {

      await AuthService.logout();


      context.go('/login');
      
    } catch (e) {
      debugPrint('ERREUR LOGOUT : $e');
    }

  },
),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SideBarItem extends StatelessWidget {
  final String title;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;
  const SideBarItem({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 18.0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Row(
                  children: [
                    SvgPicture.asset(
                      icon,
                      height: 20,
                      width: 20,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
