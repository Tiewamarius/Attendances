import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:attendance/models/employees/employee_model.dart';
import 'package:attendance/employesfolder/pages/employee_home_page.dart.dart';
import 'package:attendance/employesfolder/pages/employee_history_page.dart';
import 'package:attendance/employesfolder/pages/planning_pages.dart';

class EmployeeConsolePage extends StatefulWidget {
  const EmployeeConsolePage({
    super.key,
  });

  @override
  State<EmployeeConsolePage> createState() => _EmployeeConsolePageState();
}

class _EmployeeConsolePageState extends State<EmployeeConsolePage> {
  int _selectedIndex = 0;

  EmployeeModel? _employee;
  String? _token;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      // Adapte cette clé à celle utilisée dans ton login.
      final userJson = prefs.getString('user');

      if (token == null || token.isEmpty || userJson == null) {
        throw Exception('Session utilisateur introuvable');
      }

      final userMap = jsonDecode(userJson);

      final employee = EmployeeModel.fromJson(userMap);

      if (!mounted) return;

      setState(() {
        _token = token;
        _employee = employee;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Impossible de récupérer votre session.';
      });
    }
  }

  List<Widget> _buildPages() {
    return [
      EmployeHome(),
      EmployeePlanningPage(),
      EmployeeHistoryPage(
        employee: _employee!,
        token: _token!,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4F46E5),
          ),
        ),
      );
    }

    if (_error != null || _employee == null || _token == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 50,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Session invalide.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadSession,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pages = _buildPages();

    return Scaffold(
      backgroundColor: Colors.white,

      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFF1F5F9),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.date_range_rounded),
              label: 'Planning',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Historique',
            ),
          ],
          selectedItemColor: Color(0xFF4F46E5),
          unselectedItemColor: Color(0xFF94A3B8),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
    );
  }
}