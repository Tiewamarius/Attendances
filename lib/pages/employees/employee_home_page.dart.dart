import 'dart:async';

import 'package:attendance/controllers/employee/employee_controller.dart';
import 'package:attendance/models/employee_model.dart';
import 'package:attendance/pages/employees/employee_attendance_page.dart';
import 'package:flutter/material.dart';

class EmployeHome extends StatefulWidget {
  final EmployeeModel employee;
  final EmployeeController controller;

  const EmployeHome({
    super.key,
    required this.employee,
    required this.controller,
  });

  @override
  State<EmployeHome> createState() => _EmployeHomeState();
}

class _EmployeHomeState extends State<EmployeHome> {
  String _currentTime = '';

  Timer? _timer;

  EmployeeModel get employee => widget.employee;

  EmployeeController get controller =>
      widget.controller;

  @override
  void initState() {
    super.initState();

    _updateTime();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );

    controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(
    covariant EmployeHome oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(
        _onControllerChanged,
      );

      widget.controller.addListener(
        _onControllerChanged,
      );
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ===========================================================================
  // CLOCK
  // ===========================================================================

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

  // ===========================================================================
  // REFRESH
  // ===========================================================================

  Future<void> _refresh() async {
    await controller.refresh();

    if (!mounted) return;

    setState(() {});
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final currentEmployee =
        controller.employee ?? employee;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFF4F46E5),
          backgroundColor: Colors.white,

          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            slivers: [
              SliverToBoxAdapter(
                child:
                    _buildHeader(currentEmployee),
              ),

              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  30,
                ),

                sliver: SliverList(
                  delegate:
                      SliverChildListDelegate(
                    [
                      _buildAttendanceCard(
                        currentEmployee,
                      ),

                      const SizedBox(height: 20),

                      _buildKpis(),

                      const SizedBox(height: 24),

                      _buildQuickActions(),

                      const SizedBox(height: 24),

                      _buildProfileCard(
                        currentEmployee,
                      ),

                      const SizedBox(height: 24),

                      _buildRecentActivity(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader(
    EmployeeModel employee,
  ) {
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
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      _formatDate(now),
                      style: const TextStyle(
                        color: Color(0xFFC7D2FE),
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Bonjour, ${employee.firstName}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      employee.positionName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE0E7FF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              _buildAvatar(employee),
            ],
          ),

          const SizedBox(height: 16),

          _buildAccountStatus(employee),
        ],
      ),
    );
  }

  // ===========================================================================
  // AVATAR
  // ===========================================================================

  Widget _buildAvatar(
    EmployeeModel employee,
  ) {
    final image =
        employee.profileImage?.trim();

    final hasImage =
        image != null && image.isNotEmpty;

    return Container(
      width: 52,
      height: 52,

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
                image,
                fit: BoxFit.cover,

                errorBuilder:
                    (_, __, ___) {
                  return _initials(
                    employee,
                  );
                },

                loadingBuilder:
                    (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress ==
                      null) {
                    return child;
                  }

                  return _initials(
                    employee,
                  );
                },
              )
            : _initials(employee),
      ),
    );
  }

  Widget _initials(
    EmployeeModel employee,
  ) {
    return Center(
      child: Text(
        employee.initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  // ===========================================================================
  // ACCOUNT STATUS
  // ===========================================================================

  Widget _buildAccountStatus(
    EmployeeModel employee,
  ) {
    final active = employee.active;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.15,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF34D399)
                  : const Color(0xFFFCA5A5),
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 8),

          Text(
            active
                ? 'Compte actif'
                : 'Compte désactivé',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ATTENDANCE CARD
  // ===========================================================================

  Widget _buildAttendanceCard(
    EmployeeModel employee,
  ) {
    final loading = controller.loading;

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

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.10,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
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
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _currentTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed:
                loading || !employee.active
                    ? null
                    : () =>
                        _openAttendance(
                          employee,
                        ),

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF10B981),
              disabledBackgroundColor:
                  const Color(0xFF475569),
              foregroundColor:
                  Colors.white,

              minimumSize:
                  const Size(
                double.infinity,
                54,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              elevation: 4,
            ),

            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.fingerprint_rounded,
                  ),

            label: Text(
              !employee.active
                  ? 'Compte désactivé'
                  : loading
                      ? 'Synchronisation...'
                      : 'Pointer mon arrivée',
              style: const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Accédez aux méthodes de pointage disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // KPI
  // ===========================================================================

  Widget _buildKpis() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
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

  // ---------------------------------------------------------------------------
  // WEEKLY HOURS
  // ---------------------------------------------------------------------------

  Widget _buildWeeklyHoursCard() {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'HEURES / SEMAINE',
                  style: TextStyle(
                    color:
                        Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              Icon(
                Icons.access_time_rounded,
                size: 17,
                color:
                    Color(0xFF94A3B8),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Text(
            '—',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          const Text(
            'Données non disponibles',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),

            child:
                const LinearProgressIndicator(
              value: 0,
              backgroundColor:
                  Color(0xFFE2E8F0),
              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                Color(0xFF4F46E5),
              ),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEAVE BALANCE
  // ---------------------------------------------------------------------------

  Widget _buildLeaveBalanceCard() {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'SOLDE CONGÉS',
                  style: TextStyle(
                    color:
                        Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              Icon(
                Icons.beach_access_rounded,
                size: 17,
                color:
                    Color(0xFF94A3B8),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            '—',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          const Text(
            'Solde à récupérer',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // QUICK ACTIONS
  // ===========================================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

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
      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(16),

          child: Container(
            padding:
                const EdgeInsets.symmetric(
              vertical: 16,
            ),

            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              border: Border.all(
                color:
                    const Color(0xFFF1F5F9),
              ),
            ),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                Container(
                  width: 40,
                  height: 40,

                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    icon,
                    color:
                        const Color(
                      0xFF4F46E5,
                    ),
                    size: 20,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  label,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF334155),
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
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
  // PROFILE CARD
  // ===========================================================================

  Widget _buildProfileCard(
    EmployeeModel employee,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'MON PROFIL',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  const Color(0xFFF1F5F9),
            ),
          ),

          child: Column(
            children: [
              _buildProfileRow(
                Icons.badge_outlined,
                'Matricule',
                _displayValue(
                  employee.employeeCode,
                ),
              ),

              _buildDivider(),

              _buildProfileRow(
                Icons.work_outline_rounded,
                'Poste',
                employee.positionName,
              ),

              _buildDivider(),

              _buildProfileRow(
                Icons.apartment_outlined,
                'Département',
                employee.departmentName,
              ),

              _buildDivider(),

              _buildProfileRow(
                Icons.person_outline_rounded,
                'Manager',
                employee.managerName,
              ),

              _buildDivider(),

              _buildProfileRow(
                Icons.email_outlined,
                'Email',
                _displayValue(
                  employee.email,
                ),
              ),

              if (employee.phone != null &&
                  employee.phone!
                      .trim()
                      .isNotEmpty) ...[
                _buildDivider(),

                _buildProfileRow(
                  Icons.phone_outlined,
                  'Téléphone',
                  employee.phone!.trim(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,

          decoration:
              const BoxDecoration(
            color: Color(0xFFF8FAFC),
            shape: BoxShape.circle,
          ),

          child: Icon(
            icon,
            color:
                const Color(0xFF4F46E5),
            size: 18,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  color:
                      Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color:
                      Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        vertical: 11,
      ),
      child: Divider(
        height: 1,
        color: Color(0xFFF1F5F9),
      ),
    );
  }

  String _displayValue(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Non renseigné';
    }

    return value.trim();
  }

  // ===========================================================================
  // RECENT ACTIVITY
  // ===========================================================================

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

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
          width: double.infinity,
          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  const Color(0xFFF1F5F9),
            ),
          ),

          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.history_rounded,
                  color:
                      Color(0xFF64748B),
                  size: 22,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Aucune activité disponible',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      Color(0xFF334155),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Vos derniers pointages et demandes apparaîtront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      Color(0xFF94A3B8),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ATTENDANCE
  // ===========================================================================

  void _openAttendance(
    EmployeeModel employee,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EmployeeAttendancePage(
          employee: employee,
        ),
      ),
    );
  }

  // ===========================================================================
  // QUICK ACTIONS
  // ===========================================================================

  void _openLeaveRequest() {
    _showComingSoon(
      'Demande de congé',
      'Le module de demande de congé sera bientôt disponible.',
    );
  }

  void _openPermissionRequest() {
    _showComingSoon(
      'Demande de permission',
      'Le module de demande de permission sera bientôt disponible.',
    );
  }

  void _reportForgottenAttendance() {
    _showComingSoon(
      'Oubli de pointage',
      'Le module de déclaration d’oubli sera bientôt disponible.',
    );
  }

  void _showComingSoon(
    String title,
    String message,
  ) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),

      builder: (_) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              20,
            ),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Container(
                  width: 44,
                  height: 5,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFE2E8F0,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: 52,
                  height: 52,

                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFFE0E7FF),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.construction_rounded,
                    color:
                        Color(0xFF4F46E5),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  title,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  message,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child:
                      ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(
                      context,
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF4F46E5,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          13,
                        ),
                      ),
                    ),
                    child:
                        const Text(
                      'Fermer',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // DATE
  // ===========================================================================

  String _formatDate(
    DateTime date,
  ) {
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

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _timer?.cancel();

    controller.removeListener(
      _onControllerChanged,
    );

    super.dispose();
  }
}