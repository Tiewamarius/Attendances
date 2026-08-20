import 'package:flutter/material.dart';

class PresencesEmployeesPage extends StatefulWidget {
  const PresencesEmployeesPage({super.key});

  @override
  State<PresencesEmployeesPage> createState() => _PresencesEmployeesPageState();
}

class _PresencesEmployeesPageState extends State<PresencesEmployeesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'Tous';

  final List<Map<String, dynamic>> _employees = [];
  bool isLoading = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    final search = _searchController.text.toLowerCase().trim();

    return _employees.where((employee) {
      final matchesSearch =
          employee['name'].toString().toLowerCase().contains(search) ||
          employee['matricule'].toString().toLowerCase().contains(search) ||
          employee['department'].toString().toLowerCase().contains(search);

      final matchesFilter =
          _selectedFilter == 'Tous' || employee['status'] == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get _presentCount =>
      _employees.where((e) => e['status'] == 'Présent').length;

  int get _lateCount =>
      _employees.where((e) => e['status'] == 'En retard').length;

  int get _absentCount =>
      _employees.where((e) => e['status'] == 'Absent').length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(theme),

                    const SizedBox(height: 24),

                    _buildStatistics(),

                    const SizedBox(height: 28),

                    _buildFilters(),

                    const SizedBox(height: 20),

                    _buildEmployeesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            color: const Color(0xFF4F46E5),
            size: 28,
          ),

          const SizedBox(width: 12),

          const Text(
            'Attendance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),

          const Spacer(),

          IconButton(
            tooltip: 'Actualiser',
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4B5563)),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Présences des employés',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Suivez en temps réel les présences et horaires de votre personnel.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 800) {
          return Column(
            children: [
              _buildStatCard(
                title: 'Présents',
                value: '$_presentCount',
                subtitle: 'Employés présents',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'En retard',
                value: '$_lateCount',
                subtitle: 'Arrivées tardives',
                icon: Icons.schedule_rounded,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'Absents',
                value: '$_absentCount',
                subtitle: 'Employés absents',
                icon: Icons.cancel_outlined,
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                title: 'Total',
                value: '${_employees.length}',
                subtitle: 'Employés enregistrés',
                icon: Icons.people_outline_rounded,
                color: const Color(0xFF4F46E5),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Présents',
                value: '$_presentCount',
                subtitle: 'Employés présents',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'En retard',
                value: '$_lateCount',
                subtitle: 'Arrivées tardives',
                icon: Icons.schedule_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Absents',
                value: '$_absentCount',
                subtitle: 'Employés absents',
                icon: Icons.cancel_outlined,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Total',
                value: '${_employees.length}',
                subtitle: 'Employés enregistrés',
                icon: Icons.people_outline_rounded,
                color: const Color(0xFF4F46E5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 14),
                _buildFilterDropdown(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 16),
              SizedBox(width: 190, child: _buildFilterDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Rechercher un employé...',
        prefixIcon: const Icon(Icons.search_rounded, size: 21),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded, size: 19),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFF4F46E5)),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedFilter,
      decoration: InputDecoration(
        labelText: 'Statut',
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Tous', child: Text('Tous')),
        DropdownMenuItem(value: 'Présent', child: Text('Présents')),
        DropdownMenuItem(value: 'En retard', child: Text('En retard')),
        DropdownMenuItem(value: 'Absent', child: Text('Absents')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  // ============================================================
  // EMPLOYEES LIST
  // ============================================================

  Widget _buildEmployeesList() {
    final employees = _filteredEmployees;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Liste des présences',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                Text(
                  '${employees.length} employé${employees.length > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          if (employees.isEmpty)
            _buildEmptyState()
          else
            ...employees.map((employee) => _buildEmployeeRow(employee)),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow(Map<String, dynamic> employee) {
    final status = employee['status'] as String;

    final Color statusColor;

    switch (status) {
      case 'Présent':
        statusColor = const Color(0xFF16A34A);
        break;
      case 'En retard':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'Absent':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = Colors.grey;
    }

    return InkWell(
      onTap: () {
        _showEmployeeDetails(employee);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                employee['avatar'],
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Nom
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee['matricule'],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Département
            Expanded(
              flex: 2,
              child: Text(
                employee['department'],
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),

            // Arrivée
            Expanded(child: _buildTimeColumn('Arrivée', employee['arrival'])),

            // Départ
            Expanded(child: _buildTimeColumn('Départ', employee['departure'])),

            // Durée
            Expanded(child: _buildTimeColumn('Durée', employee['duration'])),

            // Statut
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusBadge(status, statusColor),
              ),
            ),

            const SizedBox(width: 8),

            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),

          const SizedBox(height: 14),

          const Text(
            'Aucun employé trouvé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Modifiez votre recherche ou votre filtre.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS EMPLOYE
  // ============================================================

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  employee['avatar'],
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  employee['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailLine('Matricule', employee['matricule']),
              _buildDetailLine('Département', employee['department']),
              _buildDetailLine('Arrivée', employee['arrival']),
              _buildDetailLine('Départ', employee['departure']),
              _buildDetailLine('Durée', employee['duration']),
              _buildDetailLine('Statut', employee['status']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate() {
    final now = DateTime.now();

    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
