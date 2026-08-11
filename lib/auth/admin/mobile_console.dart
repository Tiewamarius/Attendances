import 'package:attendance/auth/admin/pages/employes_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MobileConsole extends StatefulWidget {
  const MobileConsole({super.key});

  @override
  State<MobileConsole> createState() => _MobileConsoleState();
}

class _MobileConsoleState extends State<MobileConsole> {
  int selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text('Homejfghk')),
    Center(child: EmployeesPage()),
    Center(child: Text('Présences')),
    Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[selectedIndex],
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color.fromARGB(255, 8, 252, 158),
        unselectedItemColor: Colors.black45,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_3_fill),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.time),
            label: 'Présences',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.leaf_arrow_circlepath),
            label: 'Congés',
          ),
        ],
      ),
    );
  }
}