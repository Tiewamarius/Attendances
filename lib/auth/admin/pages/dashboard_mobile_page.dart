import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DashBoardMobilePage extends StatefulWidget {
  const DashBoardMobilePage({super.key});

  @override
  State<DashBoardMobilePage> createState() => _DashBoardMobilePageState();
}

class _DashBoardMobilePageState extends State<DashBoardMobilePage> {
  int selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text('Homefghk')),
    Center(child: Text('employees')),
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
        selectedItemColor: Colors.black,
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
            icon: Icon(CupertinoIcons.search),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.cart),
            label: 'Présences',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Congés',
          ),
        ],
      ),
    );
  }
}