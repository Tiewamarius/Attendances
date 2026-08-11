import 'dart:convert'; // Nécessaire pour jsonDecode
import 'package:attendance/auth/admin/pages/admin_settings_page.dart';
import 'package:attendance/auth/admin/pages/employes_page.dart';
import 'package:attendance/auth/admin/widgets/navbar_widget.dart';
import 'package:attendance/auth/admin/widgets/sidebar.dart';
import 'package:attendance/constante/colors.dart' as colors;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Nécessaire pour context.goNamed
import 'package:shared_preferences/shared_preferences.dart'; // Nécessaire pour SharedPreferences

class DashBoardDesktopPage extends StatefulWidget {
  const DashBoardDesktopPage({super.key});

  @override
  State<DashBoardDesktopPage> createState() => _DashBoardDesktopPageState();
}

class _DashBoardDesktopPageState extends State<DashBoardDesktopPage> {
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user');

    if (data != null) {
      setState(() {
        user = jsonDecode(data);
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    context.goNamed('login');
  }

  String selectedPage = '/admin';

  void _onSelectPage(String page) {
    setState(() {
      selectedPage = page;
    });
  }

  Widget _buildSelectedPageContent() {
    switch (selectedPage) {
      case '/admin':
        return const Text('Tableau de bord principal');

      case '/admins/settings':
        return const AdminSettingsPage();
        
      case '/employees':
        return const EmployeesPage();

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
                NavbarWidget(selectedPage: '', onSelectPage:_onSelectPage,),
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