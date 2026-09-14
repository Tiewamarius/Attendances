import 'package:flutter/material.dart';

import 'package:attendance/controllers/admin/dashboard_controller.dart';
import 'package:attendance/models/dashboard_model.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();

    _controller = DashboardController();
    _controller.refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.loading && !_controller.hasData) {
          return const _DashboardLoading();
        }

        if (_controller.error != null && !_controller.hasData) {
          return _DashboardError(
            message: _controller.error!,
            onRetry: _controller.refresh,
          );
        }

        final dashboard = _controller.dashboard;

        if (dashboard == null) {
          return _DashboardEmpty(
            onRetry: _controller.refresh,
          );
        }

        return _DashboardContent(
          dashboard: dashboard,
          isRefreshing: _controller.loading,
          onRefresh: _controller.refresh,
        );
      },
    );
  }
}

// ============================================================================
// DASHBOARD CONTENT
// ============================================================================

class _DashboardContent extends StatelessWidget {
  final DashboardModel dashboard;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  const _DashboardContent({
    required this.dashboard,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final statistics = dashboard.statistics;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              28,
              28,
              28,
              40,
            ),
            child: SizedBox(
              width: constraints.maxWidth.isFinite
                  ? constraints.maxWidth - 56
                  : double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeader(
                    dashboard: dashboard,
                    isRefreshing: isRefreshing,
                    onRefresh: onRefresh,
                  ),

                  const SizedBox(height: 24),
                  _AttendanceCard(
                    attendance: statistics.attendance,
                  ),
                  
                  const SizedBox(height: 24),

                  _StatisticsGrid(
                    employees: statistics.employees,
                    departments: statistics.departments,
                    kiosks: statistics.kiosks,
                    leaves: statistics.leaves,
                  ),                  

                  const SizedBox(height: 24),

                  _BottomGrid(
                    kiosks: statistics.kiosks,
                    leaves: statistics.leaves,
                    activity: dashboard.recentActivity,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _DashboardHeader extends StatelessWidget {
  final DashboardModel dashboard;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  const _DashboardHeader({
    required this.dashboard,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final organization = dashboard.organization;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 900;

        // ================================================================
        // MOBILE / COMPACT
        // ================================================================

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tableau de bord',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 6),

              // Text(
              //   'Bienvenue dans lorganisation de ${organization.name}.',
              //   style: const TextStyle(
              //     fontSize: 14,
              //     color: Color(0xFF64748B),
              //   ),
              // ),

              // const SizedBox(height: 18),

              // IMPORTANT :
              // Pas de Row avec Expanded dans un espace horizontal
              // potentiellement non borné.
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: isRefreshing ? null : onRefresh,
                    icon: isRefreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            size: 18,
                          ),
                    label: const Text('Actualiser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      side: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // SizedBox(
                  //   width: width >= 500
                  //       ? 300
                  //       : width,
                  //   child: _UserHeaderCard(
                  //     name: dashboard.user.name,
                  //     email: dashboard.user.email,
                  //   ),
                  // ),
                ],
              ),
            ],
          );
        }

        // ================================================================
        // DESKTOP
        // ================================================================

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone titre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tableau de bord',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Bienvenue dans l\'organisation de ${organization.name}.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Bouton actualiser
            OutlinedButton.icon(
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                    ),
              label: const Text('Actualiser'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                side: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Largeur FIXE => plus de contrainte horizontale infinie
            SizedBox(
              width: 300,
              child: _UserHeaderCard(
                name: dashboard.user.name,
                email: dashboard.user.email,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// USER HEADER CARD
// ============================================================================

class _UserHeaderCard extends StatelessWidget {
  final String name;
  final String email;

  const _UserHeaderCard({
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF0F172A),
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Ici Expanded est maintenant sûr :
          // le parent possède une largeur finie.
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATISTICS GRID
// ============================================================================

class _StatisticsGrid extends StatelessWidget {
  final EmployeeStatistics employees;
  final DepartmentStatistics departments;
  final KioskStatistics kiosks;
  final LeaveStatistics leaves;

  const _StatisticsGrid({
    required this.employees,
    required this.departments,
    required this.kiosks,
    required this.leaves,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatisticCardData(
        title: 'Employés',
        value: employees.total,
        subtitle: '${employees.active} actifs',
        icon: Icons.people_outline_rounded,
      ),
      _StatisticCardData(
        title: 'Départements',
        value: departments.total,
        subtitle: '${departments.active} actifs',
        icon: Icons.account_tree_outlined,
      ),
      _StatisticCardData(
        title: 'Kiosks',
        value: kiosks.total,
        subtitle: '${kiosks.active} actifs',
        icon: Icons.devices_outlined,
      ),
      _StatisticCardData(
        title: 'Congés',
        value: leaves.inProgress,
        subtitle: 'En cours',
        icon: Icons.event_busy_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1200
            ? 4
            : width >= 750
                ? 2
                : 1;

        const spacing = 16.0;

        final itemWidth = columns == 1
            ? width
            : (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(
                width: itemWidth,
                child: _StatisticCard(
                  data: card,
                ),
              ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// STATISTIC CARD
// ============================================================================

class _StatisticCard extends StatelessWidget {
  final _StatisticCardData data;

  const _StatisticCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              data.icon,
              color: const Color(0xFF334155),
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  data.value.toString(),
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ATTENDANCE
// ============================================================================

class _AttendanceCard extends StatelessWidget {
  final AttendanceStatistics attendance;

  const _AttendanceCard({
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Présences aujourd’hui',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Résumé des présences de la journée',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 22),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final columns = width >= 700 ? 3 : 1;

              const spacing = 16.0;

              final itemWidth = columns == 1
                  ? width
                  : (width - spacing * 2) / 3;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _AttendanceItem(
                      title: 'Présents',
                      value: attendance.presentToday,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AttendanceItem(
                      title: 'Absents',
                      value: attendance.absentToday,
                      icon: Icons.cancel_outlined,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _AttendanceItem(
                      title: 'En retard',
                      value: attendance.lateToday,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ATTENDANCE ITEM
// ============================================================================

class _AttendanceItem extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;

  const _AttendanceItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 21,
              color: const Color(0xFF334155),
            ),
          ),

          const SizedBox(width: 12),

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTTOM GRID
// ============================================================================

class _BottomGrid extends StatelessWidget {
  final KioskStatistics kiosks;
  final LeaveStatistics leaves;
  final RecentActivity activity;

  const _BottomGrid({
    required this.kiosks,
    required this.leaves,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 850) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KioskCard(kiosks: kiosks),

              const SizedBox(height: 16),

              _LeaveCard(leaves: leaves),

              const SizedBox(height: 16),

              _ActivityCard(activity: activity),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _KioskCard(
                kiosks: kiosks,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _LeaveCard(
                leaves: leaves,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _ActivityCard(
                activity: activity,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// KIOSK CARD
// ============================================================================

class _KioskCard extends StatelessWidget {
  final KioskStatistics kiosks;

  const _KioskCard({
    required this.kiosks,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Kiosks',
      subtitle: 'État des kiosks',
      icon: Icons.devices_outlined,
      child: Column(
        children: [
          _InfoRow(
            label: 'Total',
            value: kiosks.total.toString(),
          ),

          const Divider(height: 24),

          _InfoRow(
            label: 'Actifs',
            value: kiosks.active.toString(),
          ),

          const Divider(height: 24),

          _InfoRow(
            label: 'Inactifs',
            value: '${kiosks.total - kiosks.active}',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LEAVE CARD
// ============================================================================

class _LeaveCard extends StatelessWidget {
  final LeaveStatistics leaves;

  const _LeaveCard({
    required this.leaves,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Congés',
      subtitle: 'Demandes en cours',
      icon: Icons.event_outlined,
      child: Column(
        children: [
          const SizedBox(height: 8),

          Text(
            leaves.inProgress.toString(),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'demande(s) en cours',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTIVITY CARD
// ============================================================================

class _ActivityCard extends StatelessWidget {
  final RecentActivity activity;

  const _ActivityCard({
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final attendanceCount = activity.attendances.length;
    final employeeCount = activity.employees.length;

    return _DashboardPanel(
      title: 'Activité récente',
      subtitle: 'Dernières activités',
      icon: Icons.history_rounded,
      child: Column(
        children: [
          _InfoRow(
            label: 'Présences',
            value: attendanceCount.toString(),
          ),

          const Divider(height: 24),

          _InfoRow(
            label: 'Employés',
            value: employeeCount.toString(),
          ),

          const SizedBox(height: 16),

          if (attendanceCount == 0 && employeeCount == 0)
            const Text(
              'Aucune activité récente.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// DASHBOARD PANEL
// ============================================================================

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: const Color(0xFF334155),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }
}

// ============================================================================
// INFO ROW
// ============================================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// LOADING
// ============================================================================

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

// ============================================================================
// ERROR
// ============================================================================

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 460,
        ),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: Color(0xFF64748B),
            ),

            const SizedBox(height: 16),

            const Text(
              'Impossible de charger le dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY
// ============================================================================

class _DashboardEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardEmpty({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Aucune donnée disponible.',
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: onRetry,
            child: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATISTIC DATA
// ============================================================================

class _StatisticCardData {
  final String title;
  final int value;
  final String subtitle;
  final IconData icon;

  const _StatisticCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
}

// ============================================================================
// INITIALS
// ============================================================================

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}'
      '${parts.last.substring(0, 1)}'
      .toUpperCase();
}