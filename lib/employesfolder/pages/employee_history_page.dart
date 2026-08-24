
import 'package:attendance/models/employees/attendance_history_model.dart';
import 'package:attendance/models/employees/employee_model.dart';
import 'package:attendance/services/employees/attendance_service.dart';
import 'package:flutter/material.dart';

class EmployeeHistoryPage extends StatefulWidget {
  final EmployeeModel employee;
  final String token;

  const EmployeeHistoryPage({
    super.key,
    required this.employee,
    required this.token,
  });

  @override
  State<EmployeeHistoryPage> createState() =>
      _EmployeeHistoryPageState();
}

class _EmployeeHistoryPageState
    extends State<EmployeeHistoryPage> {
  late final AttendanceService _attendanceService;

  List<AttendanceHistoryModel> _history = [];

  bool _isLoading = true;
  String? _error;

  String _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();

    _attendanceService = AttendanceService(
      token: widget.token,
    );

    _loadHistory();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history =
          await _attendanceService.getEmployeeHistory(
        widget.employee.id,
      );

      if (!mounted) return;

      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error =
            'Impossible de récupérer votre historique.';
      });
    }
  }

  // ============================================================
  // FILTRAGE
  // ============================================================

  List<AttendanceHistoryModel> get _filteredHistory {
    if (_selectedFilter == 'Tous') {
      return _history;
    }

    if (_selectedFilter == 'Normaux') {
      return _history
          .where(
            (item) =>
                item.status.toLowerCase() == 'normal',
          )
          .toList();
    }

    if (_selectedFilter == 'Retards') {
      return _history
          .where(
            (item) =>
                item.status.toLowerCase() == 'retard',
          )
          .toList();
    }

    if (_selectedFilter == 'Absences') {
      return _history
          .where(
            (item) =>
                item.status.toLowerCase() == 'absence',
          )
          .toList();
    }

    if (_selectedFilter == 'Congés') {
      return _history
          .where(
            (item) =>
                item.status.toLowerCase() == 'congé',
          )
          .toList();
    }

    return _history;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 20),

                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HISTORIQUE',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mes Pointages',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.employee.fullName,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      _buildFilterButton(),
    ],
  );
}

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget _buildFilterButton() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _selectedFilter = value;
        });
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: 'Tous',
            child: Text('Tous'),
          ),
          PopupMenuItem(
            value: 'Normaux',
            child: Text('Normaux'),
          ),
          PopupMenuItem(
            value: 'Retards',
            child: Text('Retards'),
          ),
          PopupMenuItem(
            value: 'Absences',
            child: Text('Absences'),
          ),
          PopupMenuItem(
            value: 'Congés',
            child: Text('Congés'),
          ),
        ];
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFFF1F5F9),
          ),
        ),
        child: const Icon(
          Icons.filter_list_rounded,
          color: Color(0xFF4F46E5),
          size: 21,
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_filteredHistory.isEmpty) {
      return _buildEmpty();
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filteredHistory.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _filteredHistory[index];

        return _buildHistoryCard(item);
      },
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4F46E5),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),

        const Icon(
          Icons.cloud_off_rounded,
          size: 55,
          color: Color(0xFF94A3B8),
        ),

        const SizedBox(height: 18),

        const Text(
          'Impossible de charger',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 22),

        Center(
          child: ElevatedButton.icon(
            onPressed: _loadHistory,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF111827),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),

        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(
            Icons.history_rounded,
            size: 45,
            color: Color(0xFF0EA5E9),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Aucun pointage',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _selectedFilter == 'Tous'
              ? 'Vous n’avez encore aucun pointage enregistré.'
              : 'Aucun pointage pour le filtre sélectionné.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HISTORY CARD
  // ============================================================

  Widget _buildHistoryCard(
    AttendanceHistoryModel item,
  ) {
    final status = item.status.toLowerCase();

    final isLeave = status == 'congé';
    final isRetard = status == 'retard';
    final isAbsence = status == 'absence';

    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (isLeave) {
      backgroundColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      icon = Icons.beach_access_rounded;
    } else if (isRetard) {
      backgroundColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
      icon = Icons.schedule_rounded;
    } else if (isAbsence) {
      backgroundColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
      icon = Icons.person_off_rounded;
    } else {
      backgroundColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(item.date),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 12,
                      color: textColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.status,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (isLeave)
            _buildSpecialDay(
              icon: Icons.beach_access_rounded,
              text: 'Journée de congé validée',
            )
          else if (isAbsence)
            _buildSpecialDay(
              icon: Icons.person_off_rounded,
              text: 'Aucun pointage enregistré',
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    'ARRIVÉE',
                    item.arrival ?? '--:--',
                    Icons.login_rounded,
                  ),
                ),

                Expanded(
                  child: _buildTimeInfo(
                    'DÉPART',
                    item.departure ?? '--:--',
                    Icons.logout_rounded,
                  ),
                ),

                Expanded(
                  child: _buildTimeInfo(
                    'TOTAL',
                    item.total,
                    Icons.timer_outlined,
                    isBold: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SPECIAL DAY
  // ============================================================

  Widget _buildSpecialDay({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),

          Icon(
            icon,
            size: 18,
            color: Color(0xFF94A3B8),
          ),

          const SizedBox(width: 9),

          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIME INFO
  // ============================================================

  Widget _buildTimeInfo(
    String label,
    String time,
    IconData icon, {
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          time,
          style: TextStyle(
            color: const Color(0xFF334155),
            fontSize: 13,
            fontWeight: isBold
                ? FontWeight.bold
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE FORMAT
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
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    return '${days[date.weekday - 1]} '
        '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}