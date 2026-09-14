import 'package:attendance/pages/admin/pages/settings_page.dart';
import 'package:flutter/material.dart';

import 'package:attendance/pages/admin/pages/admin_home_page.dart';
import 'package:attendance/pages/admin/pages/employes_page.dart';
import 'package:attendance/pages/admin/pages/presences_employees_page.dart';
import 'package:attendance/pages/admin/widgets/navbar_widget.dart';
import 'package:attendance/pages/admin/widgets/sidebar.dart';

class DesktopConsole extends StatefulWidget {
  const DesktopConsole({super.key});

  @override
  State<DesktopConsole> createState() => _DesktopConsoleState();
}

class _DesktopConsoleState extends State<DesktopConsole> {
  String selectedPage = '/admin';

  void _onSelectPage(String page) {
    if (selectedPage == page) return;

    setState(() {
      selectedPage = page;
    });
  }

  Widget _buildSelectedPageContent() {
    switch (selectedPage) {
      case '/admin':
        return const AdminHomePage();

      case '/employees':
        return const EmployeesPage();

      case '/attendance':
        return const PresencesEmployeesPage();

      case '/settings':
        return const AdminSettingsPage();

      case '/leaves':
        return const Center(
          child: Text('Congés'),
        );

      case '/reports':
        return const Center(
          child: Text('Rapports'),
        );

      default:
        return Center(
          child: Text(
            'Page active : $selectedPage',
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ================================================================
          // SIDEBAR
          // ================================================================
          SideBar(
            selectedPage: selectedPage,
            onSelectPage: _onSelectPage,
          ),

          // ================================================================
          // CONTENU PRINCIPAL
          // ================================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------------------
                // NAVBAR
                // ------------------------------------------------------------
                NavbarWidget(
                  selectedPage: selectedPage,
                  onSelectPage: _onSelectPage,
                ),

                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE2E8F0),
                ),

                // ------------------------------------------------------------
                // PAGE ACTIVE
                // ------------------------------------------------------------
                Expanded(
                  child: _buildSelectedPageContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}