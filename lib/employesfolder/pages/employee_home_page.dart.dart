import 'dart:async';

import 'package:attendance/controllers/employees/employee_conttroller.dart';
import 'package:attendance/employesfolder/pages/employee_attendance_page.dart';
import 'package:flutter/material.dart';

import 'package:attendance/models/employees/employee_model.dart';

class EmployeHome extends StatefulWidget {
  const EmployeHome({super.key});

  @override
  State<EmployeHome> createState() => _EmployeHomeState();
}

class _EmployeHomeState extends State<EmployeHome> {
  final EmployeeController _employeeController = EmployeeController();

  String _currentTime = '';

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _updateTime();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    await _employeeController.loadProfile();

    if (mounted) {
      setState(() {});
    }
  }

  void _updateTime() {
    if (!mounted) return;

    final now = DateTime.now();

    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _employeeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employee = _employeeController.employee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _employeeController.loading && employee == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4F46E5),
                ),
              )
            : employee == null
                ? _buildErrorState()
                : _buildHome(employee),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person_off_rounded,
                size: 36,
                color: Color(0xFFDC2626),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Profil indisponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _employeeController.error ??
                  'Impossible de charger votre profil.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _buildHome(EmployeeModel employee) {
    return Column(
      children: [
        _buildHeader(employee),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF4F46E5),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAttendanceCard(employee),

                  const SizedBox(height: 20),

                  _buildKpis(),

                  const SizedBox(height: 24),

                  _buildQuickActions(),

                  const SizedBox(height: 24),

                  _buildRecentActivity(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(EmployeeModel employee) {
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        18,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF4F46E5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(now),
                      style: const TextStyle(
                        color: Color(0xFFC7D2FE),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Bonjour, ${employee.firstName} 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (employee.position != null &&
                        employee.position!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        employee.position!,
                        style: const TextStyle(
                          color: Color(0xFFE0E7FF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              _buildAvatar(employee),
            ],
          ),

          const SizedBox(height: 16),

          _buildAttendanceStatus(),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(EmployeeModel employee) {
    final hasImage =
        employee.profileImage != null &&
        employee.profileImage!.isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF818CF8),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                employee.profileImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _initials(employee);
                },
              )
            : _initials(employee),
      ),
    );
  }

  Widget _initials(EmployeeModel employee) {
    return Center(
      child: Text(
        employee.initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // ============================================================
  // ATTENDANCE STATUS
  // ============================================================

  Widget _buildAttendanceStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: Color(0xFFCBD5E1),
          ),

          SizedBox(width: 8),

          Text(
            'Statut du pointage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ATTENDANCE CARD
  // ============================================================

  Widget _buildAttendanceCard(EmployeeModel employee) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'POINTAGE',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _currentTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
  onPressed: () => _openAttendance(employee),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF10B981),
    foregroundColor: Colors.white,
    minimumSize: const Size(
      double.infinity,
      54,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    elevation: 4,
  ),
  icon: const Icon(
    Icons.fingerprint_rounded,
  ),
  label: const Text(
    'Pointer mon arrivée',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
),
          const SizedBox(height: 12),

          const Text(
            'Sélectionnez votre méthode de pointage.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KPI
  // ============================================================

  Widget _buildKpis() {
    return Row(
      children: [
        Expanded(
          child: _buildWeeklyHoursCard(),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildLeaveBalanceCard(),
        ),
      ],
    );
  }

  Widget _buildWeeklyHoursCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text(
                  'HEURES / SEMAINE',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(width: 5),

              Text(
                '32h / 35h',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.91,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF4F46E5),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOLDE CONGÉS',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '14',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(width: 4),

              Expanded(
                child: Text(
                  'jours restants',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIONS RAPIDES',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            _buildQuickActionItem(
              'Congé',
              Icons.calendar_today_rounded,
              _openLeaveRequest,
            ),

            const SizedBox(width: 12),

            _buildQuickActionItem(
              'Permission',
              Icons.assignment_rounded,
              _openPermissionRequest,
            ),

            const SizedBox(width: 12),

            _buildQuickActionItem(
              'Oubli',
              Icons.warning_amber_rounded,
              _reportForgottenAttendance,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF1F5F9),
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4F46E5),
                  size: 20,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIVITÉ RÉCENTE',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5)
                .withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFA7F3D0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF059669),
                  size: 18,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demande de congé approuvée',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Du 20 au 24 août validée par le Manager.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                'Hier',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _openAttendance(EmployeeModel employee) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EmployeeAttendancePage(
        employee: employee,
      ),
    ),
  );
}

  

  void _openLeaveRequest() {
    // TODO: page demande de congé
  }

  void _openPermissionRequest() {
    // TODO: page demande de permission
  }

  void _reportForgottenAttendance() {
    // TODO: page déclaration d'oubli
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime date) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

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

    return '${days[date.weekday - 1]} '
        '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}