import 'package:attendance/adminfolder/pages/home_page.dart';
import 'package:attendance/adminfolder/employees/presences_employees_page.dart';
import 'package:attendance/adminfolder/employees/employee_leaves_page.dart';
import 'package:attendance/adminfolder/pages/settings_page.dart';
import 'package:attendance/adminfolder/employees/employes_page.dart';
import 'package:attendance/adminfolder/widgets/navbar_widget.dart';
import 'package:attendance/adminfolder/widgets/sidebar.dart';
import 'package:flutter/material.dart';


class DesktopConsole extends StatefulWidget {
  const DesktopConsole({super.key});

  @override
  State<DesktopConsole> createState() => _DesktopConsoleState();
}

class _DesktopConsoleState extends State<DesktopConsole> {
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
        return const AdminPage();

      case '/admins/settings':
        return const AdminSettingsPage();

      case '/employees':
        return const EmployeesPage();

      case '/attendance':
        return const PresencesEmployeesPage();

      case '/leaves':
        return const EmployeeLeavesPage();

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


