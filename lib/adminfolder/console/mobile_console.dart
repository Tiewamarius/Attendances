import 'package:attendance/adminfolder/pages/home_page.dart';
import 'package:attendance/adminfolder/pages/settings_page.dart';
import 'package:attendance/adminfolder/pages/validate_pages.dart';
import 'package:attendance/adminfolder/employees/employes_page.dart';
import 'package:flutter/material.dart';

class MobileConsole extends StatefulWidget {
  const MobileConsole({super.key});

  @override
  State<MobileConsole> createState() => _MobileConsoleState();
}

class _MobileConsoleState extends State<MobileConsole> {
  int selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: AdminPage()),
    Center(child: EmployeesPage()),
    Center(child: ValidationPage()),
    Center(child: AdminSettingsPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(             
      body: _pages[selectedIndex],
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFF1F5F9))),
        ),
        child: BottomNavigationBar(
          onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
          selectedItemColor: const Color(0xFF0F172A),
          unselectedItemColor: const Color(0xFF94A3B8),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          currentIndex: selectedIndex,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Tableau de bord'),
            BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Équipe'),
            BottomNavigationBarItem(icon: Icon(Icons.fact_check_rounded), label: 'Validations'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Paramètres'),
          ],
        ),
      ),
    );
  }
}