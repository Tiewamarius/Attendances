import 'package:attendance/pages/employees/employee_home_page.dart.dart';
import 'package:flutter/material.dart';

import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/models/employee_model.dart';

import 'package:attendance/pages/employees/employee_history_page.dart';
import 'package:attendance/pages/employees/planning_pages.dart';

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

  // ==========================================================================
  // CHARGEMENT DE LA SESSION
  // ==========================================================================

  Future<void> _loadSession() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ----------------------------------------------------------------------
      // TOKEN
      // ----------------------------------------------------------------------

      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token utilisateur introuvable.');
      }

      // ----------------------------------------------------------------------
      // EMPLOYÉ
      // ----------------------------------------------------------------------

      final employeeData = await AuthService.getSavedEmployee();

      if (employeeData == null || employeeData.isEmpty) {
        throw Exception('Données employé introuvables.');
      }

      // ----------------------------------------------------------------------
      // MODÈLE EMPLOYÉ
      // ----------------------------------------------------------------------

      final employee = EmployeeModel.fromJson(employeeData);

      if (!mounted) return;

      setState(() {
        _token = token;
        _employee = employee;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _employee = null;
        _token = null;
        _error = 'Impossible de récupérer votre session.';
      });
    }
  }

  // ==========================================================================
  // PAGES
  // ==========================================================================

  List<Widget> _buildPages() {
    final employee = _employee;
    final token = _token;

    if (employee == null || token == null || token.isEmpty) {
      return const [
        SizedBox.shrink(),
        SizedBox.shrink(),
        SizedBox.shrink(),
      ];
    }

    return [
      const EmployeHome(),

      const EmployeePlanningPage(),

      EmployeeHistoryPage(
        employee: employee,
        token: token,
      ),
    ];
  }

  // ==========================================================================
  // LOADING
  // ==========================================================================

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4F46E5),
        ),
      ),
    );
  }

  // ==========================================================================
  // ERREUR SESSION
  // ==========================================================================

  Widget _buildSessionError() {
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

  // ==========================================================================
  // BOTTOM NAVIGATION
  // ==========================================================================

  Widget _buildBottomNavigationBar() {
    return Container(
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
          if (index == _selectedIndex) {
            return;
          }

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
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null || _employee == null || _token == null) {
      return _buildSessionError();
    }

    final pages = _buildPages();

    return Scaffold(
      backgroundColor: Colors.white,

      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}