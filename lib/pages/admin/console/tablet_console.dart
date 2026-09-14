import 'package:attendance/pages/admin/pages/admin_home_page.dart';
import 'package:attendance/pages/admin/pages/employes_page.dart';
import 'package:attendance/pages/admin/pages/presences_employees_page.dart';
import 'package:attendance/pages/admin/widgets/navbar_widget.dart';
import 'package:attendance/pages/admin/widgets/sidebar.dart';
import 'package:flutter/material.dart';

class TabletConsole extends StatefulWidget {
  const TabletConsole({super.key});

  @override
  State<TabletConsole> createState() => _TabletConsoleState();
}

class _TabletConsoleState extends State<TabletConsole> {
  String selectedPage = '/admin';

  void _onSelectPage(String page) {
    setState(() {
      selectedPage = page;
    });
  }
  // widget pour les page selectionn

  Widget _buildSelectedPageContent() {
    switch (selectedPage) {
      case '/admin':
        return const AdminHomePage();

      
      case '/employees':
        return const EmployeesPage();

      case '/attendance':
        return const PresencesEmployeesPage();
      default:
        return Text('Page active : $selectedPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          SideBar(selectedPage: selectedPage, onSelectPage: _onSelectPage),
          Expanded(
            child: Column(
              children: [
                NavbarWidget(selectedPage: '', onSelectPage: _onSelectPage),
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


