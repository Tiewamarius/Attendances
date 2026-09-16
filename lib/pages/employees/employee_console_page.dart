import 'package:attendance/controllers/employee/employee_controller.dart';
import 'package:attendance/models/employee_model.dart';
import 'package:attendance/pages/employees/employee_home_page.dart.dart';
import 'package:flutter/material.dart';
import 'package:attendance/core/auth/auth_service.dart';
import 'package:attendance/pages/employees/employee_history_page.dart';
import 'package:attendance/pages/employees/planning_pages.dart';

class EmployeeConsolePage extends StatefulWidget {
  const EmployeeConsolePage({super.key});

  @override
  State<EmployeeConsolePage> createState() => _EmployeeConsolePageState();
}

class _EmployeeConsolePageState extends State<EmployeeConsolePage> {
  late final EmployeeController _employeeController;

  int _selectedIndex = 0;

  String? _token;
  EmployeeModel? _employee;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _employeeController = EmployeeController();

    _employeeController.addListener(_onEmployeeControllerChanged);

    _loadSession();
  }

  // ===========================================================================
  // CONTROLLER
  // ===========================================================================

  void _onEmployeeControllerChanged() {
    if (!mounted) return;

    final employee = _employeeController.employee;

    if (employee != null && employee != _employee) {
      setState(() {
        _employee = employee;
        _error = null;
      });
    }

    if (!_employeeController.loading &&
        _employeeController.error != null &&
        _employee == null) {
      setState(() {
        _error = _employeeController.error;
      });
    }
  }

  // ===========================================================================
  // SESSION
  // ===========================================================================

  Future<void> _loadSession() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // -----------------------------------------------------------------------
      // 1. Vérification de la session AuthService
      // -----------------------------------------------------------------------

      final sessionReady = await AuthService.isSessionReady();

      if (!sessionReady) {
        throw Exception(
          'Votre session utilisateur n’est plus disponible.',
        );
      }

      // -----------------------------------------------------------------------
      // 2. Token utilisateur
      // -----------------------------------------------------------------------

      final token = await AuthService.getToken();

      if (token == null || token.trim().isEmpty) {
        throw Exception(
          'Token utilisateur introuvable.',
        );
      }

      // -----------------------------------------------------------------------
      // 3. Employé sauvegardé localement
      // -----------------------------------------------------------------------

      final savedEmployee =
          await AuthService.getSavedEmployee();

      EmployeeModel? employee;

      if (savedEmployee != null &&
          savedEmployee.isNotEmpty) {
        try {
          employee = EmployeeModel.fromJson(
            Map<String, dynamic>.from(savedEmployee),
          );
        } catch (e) {
          debugPrint(
            'EmployeeConsolePage: erreur parsing employé local: $e',
          );
        }
      }

      // -----------------------------------------------------------------------
      // 4. Mise à jour immédiate de l'interface avec le cache
      // -----------------------------------------------------------------------

      if (mounted) {
        setState(() {
          _token = token;
          _employee = employee;
          _isLoading = employee == null;
        });
      }

      // -----------------------------------------------------------------------
      // 5. Synchronisation avec l'API via EmployeeController
      // -----------------------------------------------------------------------

      await _employeeController.loadProfile();

      final remoteEmployee =
          _employeeController.employee;

      if (!mounted) return;

      if (remoteEmployee != null) {
        setState(() {
          _employee = remoteEmployee;
          _token = token;
          _isLoading = false;
          _error = null;
        });

        return;
      }

      // -----------------------------------------------------------------------
      // 6. Si l'API échoue mais qu'on possède un cache valide
      // -----------------------------------------------------------------------

      if (_employee != null) {
        setState(() {
          _isLoading = false;
          _error = null;
        });

        return;
      }

      throw Exception(
        _employeeController.error ??
            'Impossible de récupérer votre profil employé.',
      );
    } catch (e) {
      debugPrint(
        'EmployeeConsolePage._loadSession(): $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _employee = null;
        _token = null;
        _error = _errorMessage(e);
      });
    }
  }

  // ===========================================================================
  // REFRESH
  // ===========================================================================

  Future<void> _refreshSession() async {
    if (_employeeController.loading) return;

    try {
      final success =
          await _employeeController.refresh();

      if (!mounted) return;

      if (success) {
        final employee =
            _employeeController.employee;

        setState(() {
          _employee = employee;
          _error = null;
        });

        return;
      }

      if (_employee != null) {
        setState(() {
          _error = null;
        });

        return;
      }

      setState(() {
        _error =
            _employeeController.error ??
                'Impossible de mettre à jour votre profil.';
      });
    } catch (e) {
      debugPrint(
        'EmployeeConsolePage._refreshSession(): $e',
      );

      if (!mounted) return;

      setState(() {
        _error = _errorMessage(e);
      });
    }
  }

  // ===========================================================================
  // PAGES
  // ===========================================================================

  List<Widget> _buildPages() {
    final employee = _employee;
    final token = _token;

    if (employee == null ||
        token == null ||
        token.trim().isEmpty) {
      return const [
        SizedBox.shrink(),
        SizedBox.shrink(),
        SizedBox.shrink(),
      ];
    }

    return [
      EmployeHome(
        employee: employee,
        controller: _employeeController,
      ),

      const EmployeePlanningPage(),

      EmployeeHistoryPage(
        employee: employee,
        token: token,
      ),
    ];
  }

  // ===========================================================================
  // LOADING
  // ===========================================================================

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Chargement de votre espace...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Récupération de votre profil employé',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SESSION ERROR
  // ===========================================================================

  Widget _buildSessionError() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.person_off_rounded,
                    size: 38,
                    color: Color(0xFFDC2626),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Session indisponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _error ??
                      'Impossible de récupérer votre espace employé.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _loadSession,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Réessayer',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION
  // ===========================================================================

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        if (!mounted) return;

        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: Colors.white,
      indicatorColor:
          const Color(0xFFE0E7FF),
      elevation: 0,
      height: 72,
      destinations: const [
        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
          ),
          selectedIcon: Icon(
            Icons.home_rounded,
          ),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.calendar_month_outlined,
          ),
          selectedIcon: Icon(
            Icons.calendar_month_rounded,
          ),
          label: 'Planning',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.history_outlined,
          ),
          selectedIcon: Icon(
            Icons.history_rounded,
          ),
          label: 'Historique',
        ),
      ],
    );
  }

  // ===========================================================================
  // ERROR MESSAGE
  // ===========================================================================

  String _errorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception:')) {
      return message.replaceFirst(
        'Exception:',
        '',
      ).trim();
    }

    return 'Impossible de récupérer votre espace employé.';
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading &&
        _employee == null) {
      return _buildLoading();
    }

    if (_employee == null ||
        _token == null ||
        _token!.trim().isEmpty) {
      return _buildSessionError();
    }

    final pages = _buildPages();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      bottomNavigationBar:
          _buildBottomNavigationBar(),
    );
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _employeeController.removeListener(
      _onEmployeeControllerChanged,
    );

    _employeeController.dispose();

    super.dispose();
  }
}