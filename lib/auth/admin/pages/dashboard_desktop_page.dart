import 'package:attendance/auth/admin/pages/emplyes_page.dart';
import 'package:attendance/auth/admin/widgets/navbar_widget.dart';
import 'package:attendance/auth/admin/widgets/sidebar.dart';
import 'package:attendance/constante/colors.dart' as colors;
import 'package:flutter/material.dart';

class DashBoardDesktopPage extends StatefulWidget {
  const DashBoardDesktopPage({super.key});

  @override
  State<DashBoardDesktopPage> createState() => _DashBoardDesktopPageState();
}

class _DashBoardDesktopPageState extends State<DashBoardDesktopPage> {
  String selectedPage = '/admin';

  void _onSelectPage(String page) {
    setState(() {
      selectedPage = page;
    });
  }

  // La méthode est maintenant placée à l'intérieur de la classe d'état
  Widget _buildSelectedPageContent() {
    switch (selectedPage) {
      case '/admin':
        return const Text('Tableau de bord principal');
      case '/employees':
        return EmployeesPage();
      case '/attendance':
        return const Text('Gestion des présences');
      default:
        return Text('Page active : $selectedPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.bgColor,
      body: Row(
        children: [
          SideBar(
            selectedPage: selectedPage,
            onSelectPage: _onSelectPage,
          ),
          Expanded(
            child: Column(
              children: [
                const NavbarWidget(),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    child: _buildSelectedPageContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}