import 'package:flutter/material.dart';

import 'package:attendance/controllers/admins/leave_controller.dart';
import 'package:attendance/models/admins/leave_model..dart';

class EmployeeLeavesPage extends StatefulWidget {
  const EmployeeLeavesPage({super.key});

  @override
  State<EmployeeLeavesPage> createState() =>
      _EmployeeLeavesPageState();
}

class _EmployeeLeavesPageState
    extends State<EmployeeLeavesPage> {
  late final LeaveController _controller;

  final TextEditingController _searchController =
      TextEditingController();

  String _search = '';

  @override
  void initState() {
    super.initState();

    _controller = LeaveController();

    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });

    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.loadLeaves();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();

    super.dispose();
  }

  // ============================================================
  // FILTRE
  // ============================================================

  List<LeaveModel> get _filteredLeaves {
    if (_search.isEmpty) {
      return _controller.leaves;
    }

    return _controller.leaves.where((leave) {
      return leave.employeeName
              .toLowerCase()
              .contains(_search) ||
          leave.leaveType
              .toLowerCase()
              .contains(_search);
    }).toList();
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? Colors.red : Colors.green,
      ),
    );
  }

  // ============================================================
  // APPROUVER
  // ============================================================

  Future<void> _approve(LeaveModel leave) async {
    final success =
        await _controller.approveLeave(leave.id);

    if (!mounted) return;

    setState(() {});

    if (success) {
      _showMessage(
        'Demande de ${leave.employeeName} approuvée.',
      );
    } else {
      _showMessage(
        _controller.error ?? 'Impossible d\'approuver la demande.',
        error: true,
      );
    }
  }

  // ============================================================
  // REFUSER
  // ============================================================

  Future<void> _reject(LeaveModel leave) async {
    final success =
        await _controller.rejectLeave(leave.id);

    if (!mounted) return;

    setState(() {});

    if (success) {
      _showMessage(
        'Demande de ${leave.employeeName} refusée.',
      );
    } else {
      _showMessage(
        _controller.error ?? 'Impossible de refuser la demande.',
        error: true,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,

          child: _controller.loading &&
                  _controller.leaves.isEmpty
              ? const SingleChildScrollView(
                  physics:
                      AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 600,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.all(24),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      _buildHeader(),

                      const SizedBox(height: 24),

                      _buildStatistics(),

                      const SizedBox(height: 32),

                      _buildSearch(),

                      const SizedBox(height: 16),

                      _buildLeaveList(),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;

        final title = const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Supervision des Congés',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),

            SizedBox(height: 4),

            Text(
              'Gérez et validez les demandes des collaborateurs.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        );

        final exportButton =
            OutlinedButton.icon(
          onPressed: () {
            _showMessage(
              'Export disponible prochainement.',
            );
          },
          icon: const Icon(
            Icons.download,
            size: 18,
          ),
          label: const Text('Exporter'),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                const Color(0xFF1E293B),
            side: const BorderSide(
              color: Color(0xFFCBD5E1),
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(8),
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 16),
              exportButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: title),
            exportButton,
          ],
        );
      },
    );
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  Widget _buildStatistics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count =
            constraints.maxWidth > 800 ? 3 : 1;

        return GridView.count(
          crossAxisCount: count,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.8,

          children: [
            _AdminStatCard(
              title: 'En attente de validation',
              count: '${_controller.pendingCount}',
              color: const Color(0xFFD97706),
              icon: Icons.hourglass_top,
            ),

            _AdminStatCard(
              title: 'Demandes approuvées',
              count: '${_controller.approvedCount}',
              color: const Color(0xFF2563EB),
              icon: Icons.check_circle_outline,
            ),

            _AdminStatCard(
              title: 'Demandes refusées',
              count: '${_controller.rejectedCount}',
              color: const Color(0xFFDC2626),
              icon: Icons.cancel_outlined,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // RECHERCHE
  // ============================================================

  Widget _buildSearch() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Demandes récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: constraints.maxWidth > 500
                  ? 350
                  : double.infinity,
              child: TextField(
                controller: _searchController,

                decoration:
                    InputDecoration(
                  hintText:
                      'Rechercher un employé...',
                  prefixIcon:
                      const Icon(Icons.search),
                  suffixIcon:
                      _search.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController
                                    .clear();
                              },
                              icon: const Icon(
                                Icons.clear,
                              ),
                            )
                          : null,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LISTE
  // ============================================================

  Widget _buildLeaveList() {
    final leaves = _filteredLeaves;

    if (leaves.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(50),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),

        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 60,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'Aucune demande de congé',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Les demandes apparaîtront ici.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),

      child: ListView.separated(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),

        itemCount: leaves.length,

        separatorBuilder:
            (context, index) =>
                const Divider(
          height: 1,
          color: Color(0xFFE2E8F0),
        ),

        itemBuilder: (context, index) {
          return _buildLeaveItem(
            leaves[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // ITEM CONGE
  // ============================================================

  Widget _buildLeaveItem(
    LeaveModel leave,
  ) {
    final processing =
        _controller.processingId ==
            leave.id;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              CircleAvatar(
                backgroundColor:
                    const Color(0xFFEFF6FF),

                child: Text(
                  leave.employeeInitials,

                  style:
                      const TextStyle(
                    color:
                        Color(0xFF2563EB),
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      leave.employeeName,

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 15,
                        color:
                            Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${leave.leaveType} • '
                      '${_formatDate(leave.startDate)} '
                      'au '
                      '${_formatDate(leave.endDate)} '
                      '(${leave.totalDays} jours)',

                      style:
                          const TextStyle(
                        color:
                            Color(0xFF475569),
                        fontSize: 13,
                      ),
                    ),

                    if (leave.reason.isNotEmpty) ...[
                      const SizedBox(height: 4),

                      Text(
                        'Motif : ${leave.reason}',

                        style:
                            const TextStyle(
                          color:
                              Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              _buildStatusBadge(leave),
            ],
          ),

          if (leave.isPending) ...[
            const SizedBox(height: 14),

            Align(
              alignment:
                  Alignment.centerRight,

              child: Wrap(
                spacing: 8,
                runSpacing: 8,

                children: [
                  OutlinedButton.icon(
                    onPressed: processing
                        ? null
                        : () =>
                            _reject(leave),

                    icon: const Icon(
                      Icons.close,
                      size: 16,
                    ),

                    label:
                        const Text('Refuser'),

                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(
                        0xFF991B1B,
                      ),
                      side:
                          const BorderSide(
                        color:
                            Color(0xFFFCA5A5),
                      ),
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: processing
                        ? null
                        : () =>
                            _approve(leave),

                    icon: processing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check,
                            size: 16,
                          ),

                    label:
                        const Text('Accepter'),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF166534,
                      ),
                      foregroundColor:
                          Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusBadge(
    LeaveModel leave,
  ) {
    Color color;
    Color background;
    String text;

    if (leave.isApproved) {
      color = const Color(0xFF166534);
      background = const Color(0xFFDCFCE7);
      text = 'Approuvé';
    } else if (leave.isRejected) {
      color = const Color(0xFF991B1B);
      background = const Color(0xFFFEE2E2);
      text = 'Refusé';
    } else {
      color = const Color(0xFF92400E);
      background = const Color(0xFFFEF3C7);
      text = 'En attente';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        text,

        style: TextStyle(
          color: color,
          fontWeight:
              FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

// ================================================================
// STAT CARD
// ================================================================

class _AdminStatCard
    extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const _AdminStatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: .1),
              borderRadius:
                  BorderRadius.circular(10),
            ),

            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                Text(
                  title,

                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xFF64748B),
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  count,

                  style:
                      const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF1E293B),
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