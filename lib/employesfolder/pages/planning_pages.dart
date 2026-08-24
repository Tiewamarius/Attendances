import 'package:flutter/material.dart';

class EmployeePlanningPage extends StatefulWidget {
  const EmployeePlanningPage({super.key});

  @override
  State<EmployeePlanningPage> createState() =>
      _EmployeePlanningPageState();
}

class _EmployeePlanningPageState
    extends State<EmployeePlanningPage> {
  DateTime _focusedMonth = DateTime(2026, 8);
  DateTime? _startDate;
  DateTime? _endDate;

  String _requestType = 'permission';

  final TextEditingController _reasonController =
      TextEditingController();

  final TextEditingController _noteController =
      TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 22),

              _buildCalendarCard(),

              const SizedBox(height: 18),

              _buildDateSelectionCard(),

              const SizedBox(height: 18),

              _buildRequestTypeCard(),

              const SizedBox(height: 18),

              _buildReasonCard(),

              const SizedBox(height: 22),

              _buildSummaryCard(),

              const SizedBox(height: 22),

              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MON PLANNING',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            letterSpacing: 1.3,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Mes demandes',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Sélectionnez une période et choisissez le type de demande.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Widget _buildCalendarCard() {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;

    final firstDay =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);

    // Dart : lundi = 1 ... dimanche = 7
    final offset = firstDay.weekday - 1;

    final totalCells = ((offset + daysInMonth) / 7).ceil() * 7;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),

          const SizedBox(height: 20),

          Row(
            children: [
              ...[
                'L',
                'M',
                'M',
                'J',
                'V',
                'S',
                'D',
              ].map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              if (index < offset) {
                return const SizedBox();
              }

              final day = index - offset + 1;

              if (day > daysInMonth) {
                return const SizedBox();
              }

              final date = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                day,
              );

              return _buildCalendarDay(date);
            },
          ),

          const SizedBox(height: 16),

          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMonthButton(
          icon: Icons.chevron_left_rounded,
          onTap: () {
            setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month - 1,
              );
            });
          },
        ),

        Text(
          _formatMonth(_focusedMonth),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        _buildMonthButton(
          icon: Icons.chevron_right_rounded,
          onTap: () {
            setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildMonthButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 20,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  // ============================================================
  // CALENDAR DAY
  // ============================================================

  Widget _buildCalendarDay(DateTime date) {
    final selected = _isSelected(date);
    final inRange = _isInRange(date);
    final today = _isToday(date);

    Color background = Colors.transparent;
    Color textColor = const Color(0xFF334155);

    if (selected) {
      background = const Color(0xFF4F46E5);
      textColor = Colors.white;
    } else if (inRange) {
      background = const Color(0xFFEDE9FE);
      textColor = const Color(0xFF4F46E5);
    }

    if (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday) {
      if (!selected && !inRange) {
        textColor = const Color(0xFFCBD5E1);
      }
    }

    return GestureDetector(
      onTap: () => _selectDate(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: today && !selected
              ? Border.all(
                  color: const Color(0xFF818CF8),
                  width: 1.5,
                )
              : null,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: selected || inRange || today
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE SELECTION
  // ============================================================

  void _selectDate(DateTime date) {
    setState(() {
      if (_startDate == null || _endDate != null) {
        _startDate = date;
        _endDate = null;
        return;
      }

      if (date.isBefore(_startDate!)) {
        _endDate = _startDate;
        _startDate = date;
      } else {
        _endDate = date;
      }
    });
  }

  bool _isSelected(DateTime date) {
    return _sameDay(date, _startDate) ||
        _sameDay(date, _endDate);
  }

  bool _isInRange(DateTime date) {
    if (_startDate == null || _endDate == null) {
      return false;
    }

    return date.isAfter(_startDate!) &&
        date.isBefore(_endDate!);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }

    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  // ============================================================
  // CALENDAR LEGEND
  // ============================================================

  Widget _buildCalendarLegend() {
    return Row(
      children: [
        _legend(
          color: const Color(0xFF4F46E5),
          label: 'Sélection',
        ),
        const SizedBox(width: 18),
        _legend(
          color: const Color(0xFFEDE9FE),
          label: 'Période',
        ),
        const SizedBox(width: 18),
        _legend(
          color: const Color(0xFFCBD5E1),
          label: 'Week-end',
        ),
      ],
    );
  }

  Widget _legend({
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE CARD
  // ============================================================

  Widget _buildDateSelectionCard() {
    return _buildSectionCard(
      title: 'PÉRIODE SÉLECTIONNÉE',
      icon: Icons.date_range_rounded,
      child: Row(
        children: [
          Expanded(
            child: _buildDateBox(
              label: 'DATE DE DÉBUT',
              date: _startDate,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ),

          Expanded(
            child: _buildDateBox(
              label: 'DATE DE FIN',
              date: _endDate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox({
    required String label,
    required DateTime? date,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date == null
                ? '-- / -- / ----'
                : _formatDateShort(date),
            style: TextStyle(
              color: date == null
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TYPE
  // ============================================================

  Widget _buildRequestTypeCard() {
    return _buildSectionCard(
      title: 'TYPE DE DEMANDE',
      icon: Icons.assignment_rounded,
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption(
              type: 'permission',
              title: 'Permission',
              subtitle: 'Absence ponctuelle',
              icon: Icons.access_time_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTypeOption(
              type: 'conge',
              title: 'Congé',
              subtitle: 'Repos / absence',
              icon: Icons.beach_access_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _requestType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _requestType = type;
        });
      },
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEEF2FF)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? const Color(0xFF4F46E5)
                : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF4F46E5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF3730A3)
                    : const Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REASON / NOTE
  // ============================================================

  Widget _buildReasonCard() {
    final isPermission = _requestType == 'permission';

    return _buildSectionCard(
      title: isPermission
          ? 'MOTIF DE LA PERMISSION'
          : 'NOTE DU CONGÉ',
      icon: isPermission
          ? Icons.edit_note_rounded
          : Icons.notes_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: isPermission
                ? _reasonController
                : _noteController,
            maxLines: 4,
            minLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: isPermission
                  ? 'Ex. Rendez-vous médical, raison familiale...'
                  : 'Ajoutez une note si nécessaire...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isPermission
                ? '* Le motif est obligatoire.'
                : 'Facultatif — vous pouvez laisser ce champ vide.',
            style: TextStyle(
              color: isPermission
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard() {
    final hasDates =
        _startDate != null && _endDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _requestType == 'permission'
                  ? Icons.access_time_rounded
                  : Icons.beach_access_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _requestType == 'permission'
                      ? 'Demande de permission'
                      : 'Demande de congé',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  hasDates
                      ? '${_formatDateShort(_startDate!)} → ${_formatDateShort(_endDate!)}'
                      : 'Sélectionnez votre période',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .65),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (hasDates)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF4ADE80),
              size: 20,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting
            ? null
            : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          disabledBackgroundColor:
              const Color(0xFFCBD5E1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_rounded,
                    size: 18,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Soumettre la demande',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // SUBMIT ACTION
  // ============================================================

  Future<void> _submitRequest() async {
    if (_startDate == null || _endDate == null) {
      _showMessage(
        'Veuillez sélectionner une date de début et une date de fin.',
        error: true,
      );
      return;
    }

    if (_requestType == 'permission' &&
        _reasonController.text.trim().isEmpty) {
      _showMessage(
        'Le motif de la permission est obligatoire.',
        error: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ========================================================
      // ICI TU FERAS TON APPEL API
      // ========================================================

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      _showMessage(
        _requestType == 'permission'
            ? 'Votre demande de permission a été soumise.'
            : 'Votre demande de congé a été soumise.',
      );

      setState(() {
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
        _noteController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Impossible de soumettre la demande.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF4F46E5),
                ),
              ),

              const SizedBox(width: 9),

              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // FORMATTERS
  // ============================================================

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatMonth(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: error
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      );
  }
}