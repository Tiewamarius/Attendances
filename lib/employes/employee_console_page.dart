import 'package:attendance/employes/pages/employee_history_page.dart';
import 'package:attendance/employes/pages/employee_home_page.dart.dart';
import 'package:attendance/employes/pages/planning_pages.dart';
import 'package:flutter/material.dart';

class EmployeeConsolePage extends StatefulWidget {
  const EmployeeConsolePage({super.key});

  @override
  State<EmployeeConsolePage> createState() => _EmployeeConsolePageState();
}

class _EmployeeConsolePageState extends State<EmployeeConsolePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: EmployeHome()),
    // Center(child: AttendanceScreen()),
    Center(child: EmployeeHistoryPage()),
    Center(child: EmployeePlanningPage()),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFF1F5F9))),
        ),
        child: BottomNavigationBar(
          onTap: (index) {
            setState(() {
              _selectedIndex=index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.date_range_rounded), label: 'Planning'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historique'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF4F46E5),
          unselectedItemColor: const Color(0xFF94A3B8),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          
        ),
      ),
    
      
    );
  }
}
