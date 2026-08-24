import 'package:attendance/models/admins/dashboard_model.dart';
import 'package:flutter/material.dart';

class UserService {
  static final UserService instance = UserService._();

  UserService._();

  factory UserService() => instance;

  Future<AdminDashboardModel> getDashboard() async {
    return AdminDashboardModel(
      stats: DashboardStats(
        totalEmployees: 0,
        present: 0,
        remote: 0,
        absent: 0,
        late: 0,
      ),
      pendingRequests: const [],
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late final UserService _userService;

  AdminDashboardModel? _dashboard;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _userService = UserService.instance;

    _loadDashboard();
  }

  // ============================================================
  // CHARGEMENT DU DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboard = await _userService.getDashboard();

      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // RESPONSIVE
    // ============================================================

    final screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 768;
    final bool isDesktop = screenWidth >= 1024;

    final double horizontalPadding = isMobile
        ? 16.0
        : (isDesktop ? 32.0 : 24.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: _buildBody(
          isMobile: isMobile,
          isDesktop: isDesktop,
          horizontalPadding: horizontalPadding,
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody({
    required bool isMobile,
    required bool isDesktop,
    required double horizontalPadding,
  }) {
    // ------------------------------------------------------------
    // LOADING
    // ------------------------------------------------------------

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4F46E5),
        ),
      );
    }

    // ------------------------------------------------------------
    // ERREUR
    // ------------------------------------------------------------

    if (_error != null) {
      return _buildError();
    }

    // ------------------------------------------------------------
    // AUCUNE DONNÉE
    // ------------------------------------------------------------

    if (_dashboard == null) {
      return const Center(
        child: Text(
          'Aucune donnée disponible.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
      );
    }

    // ------------------------------------------------------------
    // DONNÉES DU DASHBOARD
    // ------------------------------------------------------------

    final dashboard = _dashboard!;

    return RefreshIndicator(
      onRefresh: _loadDashboard,

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 20.0,
        ),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // 1. PRÉSENCES DU JOUR
                // ==================================================

                const Text(
                  "PRÉSENCES DU JOUR",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 12),

                _buildStats(
                  dashboard.stats,
                  isDesktop,
                ),

                const SizedBox(height: 28),

                // ==================================================
                // 2. ACTIONS RAPIDES
                // ==================================================

                const Text(
                  "ACTIONS RAPIDES",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 12),

                _buildQuickActions(
                  isMobile,
                ),

                const SizedBox(height: 28),

                // ==================================================
                // 3. DEMANDES EN ATTENTE
                // ==================================================

                _buildPendingHeader(),

                const SizedBox(height: 8),

                _buildPendingRequests(
                  dashboard.pendingRequests,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  Widget _buildStats(
    DashboardStats stats,
    bool isDesktop,
  ) {
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,

      crossAxisSpacing: 16,
      mainAxisSpacing: 16,

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      childAspectRatio: isDesktop ? 1.8 : 1.5,

      children: [
        // --------------------------------------------------------
        // PRÉSENTS
        // --------------------------------------------------------

        _buildStatCard(
          "Présents",
          "${stats.present} / ${stats.totalEmployees}",
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
          const Color(0xFFECFDF5),
        ),

        // --------------------------------------------------------
        // TÉLÉTRAVAIL
        // --------------------------------------------------------

        _buildStatCard(
          "En Télétravail",
          "${stats.remote}",
          Icons.home_work_rounded,
          const Color(0xFF3B82F6),
          const Color(0xFFEFF6FF),
        ),

        // --------------------------------------------------------
        // ABSENTS
        // --------------------------------------------------------

        _buildStatCard(
          "Absents",
          "${stats.absent}",
          Icons.cancel_rounded,
          const Color(0xFFEF4444),
          const Color(0xFFFEF2F2),
        ),

        // --------------------------------------------------------
        // RETARDS
        // --------------------------------------------------------

        _buildStatCard(
          "Retards",
          "${stats.late}",
          Icons.schedule_rounded,
          const Color(0xFFF59E0B),
          const Color(0xFFFFFBEB),
        ),
      ],
    );
  }

  // ============================================================
  // CARTE STATISTIQUE
  // ============================================================

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
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

        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),

                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),

                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Container(
                padding: const EdgeInsets.all(6),

                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,

            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS RAPIDES
  // ============================================================

  Widget _buildQuickActions(
    bool isMobile,
  ) {
    final actions = [
      {
        'label': 'Valider Congés',
        'icon': Icons.event_available_rounded,
        'color': const Color(0xFF4F46E5),
      },
      {
        'label': 'Générer Rapport',
        'icon': Icons.bar_chart_rounded,
        'color': const Color(0xFF0EA5E9),
      },
      {
        'label': 'Ajouter Employé',
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFF10B981),
      },
    ];

    // ------------------------------------------------------------
    // MOBILE
    // ------------------------------------------------------------

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            _buildQuickActionItem(
              actions[i]['label'] as String,
              actions[i]['icon'] as IconData,
              actions[i]['color'] as Color,
              () {
                _handleQuickAction(
                  actions[i]['label'] as String,
                );
              },
            ),

            if (i < actions.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      );
    }

    // ------------------------------------------------------------
    // TABLETTE / DESKTOP
    // ------------------------------------------------------------

    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          Expanded(
            child: _buildQuickActionItem(
              actions[i]['label'] as String,
              actions[i]['icon'] as IconData,
              actions[i]['color'] as Color,
              () {
                _handleQuickAction(
                  actions[i]['label'] as String,
                );
              },
            ),
          ),

          if (i < actions.length - 1)
            const SizedBox(width: 12),
        ],
      ],
    );
  }

  // ============================================================
  // ACTION RAPIDE
  // ============================================================

  void _handleQuickAction(
    String action,
  ) {
    switch (action) {
      case 'Valider Congés':
        // TODO: navigation vers les demandes
        break;

      case 'Générer Rapport':
        // TODO: navigation vers les rapports
        break;

      case 'Ajouter Employé':
        // TODO: navigation vers les employés
        break;
    }
  }

  // ============================================================
  // WIDGET ACTION RAPIDE
  // ============================================================

  Widget _buildQuickActionItem(
    String label,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(16),

      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: const Color(0xFFF1F5F9),
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 40,
              height: 40,

              decoration: BoxDecoration(
                color: iconColor.withValues(
                  alpha: 0.1,
                ),

                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              label,

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER DEMANDES EN ATTENTE
  // ============================================================

  Widget _buildPendingHeader() {
    final pendingCount =
        _dashboard?.pendingRequests.length ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        const Text(
          "DEMANDES EN ATTENTE",

          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),

        TextButton(
          onPressed: () {
            // TODO: afficher toutes les demandes
          },

          child: Text(
            "Voir tout ($pendingCount)",

            style: const TextStyle(
              color: Color(0xFF4F46E5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LISTE DES DEMANDES
  // ============================================================

  Widget _buildPendingRequests(
    List<PendingRequestModel> requests,
  ) {
    // ------------------------------------------------------------
    // AUCUNE DEMANDE
    // ------------------------------------------------------------

    if (requests.isEmpty) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: const Color(0xFFF1F5F9),
          ),
        ),

        child: const Column(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF10B981),
              size: 32,
            ),

            SizedBox(height: 10),

            Text(
              'Aucune demande en attente',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------
    // DEMANDES DYNAMIQUES
    // ------------------------------------------------------------

    return Column(
      children: [
        for (int i = 0; i < requests.length; i++) ...[
          _buildPendingRequestCard(
            request: requests[i],
          ),

          if (i < requests.length - 1)
            const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ============================================================
  // CARTE DEMANDE DYNAMIQUE
  // ============================================================

  Widget _buildPendingRequestCard({
    required PendingRequestModel request,
  }) {
    final avatarText = _getInitials(
      request.employeeName,
    );

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
      ),

      child: Row(
        children: [
          // ======================================================
          // AVATAR
          // ======================================================

          Container(
            width: 42,
            height: 42,

            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),

            child: Center(
              child: Text(
                avatarText,

                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ======================================================
          // INFORMATIONS
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  request.employeeName,

                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Poste
                Text(
                  request.position.isNotEmpty
                      ? request.position
                      : 'Poste non renseigné',

                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                // Type + dates
                Text(
                  _buildRequestDescription(request),

                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ======================================================
          // BOUTONS
          // ======================================================

          Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              // --------------------------------------------------
              // ACCEPTER
              // --------------------------------------------------

              InkWell(
                onTap: () {
                  _approveRequest(request);
                },

                borderRadius: BorderRadius.circular(8),

                child: Container(
                  padding: const EdgeInsets.all(8),

                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF059669),
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // --------------------------------------------------
              // REFUSER
              // --------------------------------------------------

              InkWell(
                onTap: () {
                  _rejectRequest(request);
                },

                borderRadius: BorderRadius.circular(8),

                child: Container(
                  padding: const EdgeInsets.all(8),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: const Icon(
                    Icons.close,
                    color: Color(0xFFDC2626),
                    size: 18,
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
  // DESCRIPTION DE LA DEMANDE
  // ============================================================

  String _buildRequestDescription(
    PendingRequestModel request,
  ) {
    final type = request.type.isNotEmpty
        ? request.type
        : 'Demande';

    final start = request.startDate.isNotEmpty
        ? request.startDate
        : '';

    final end = request.endDate.isNotEmpty
        ? request.endDate
        : '';

    if (start.isEmpty && end.isEmpty) {
      return type;
    }

    if (end.isEmpty || end == start) {
      return '$type • $start';
    }

    return '$type • Du $start au $end';
  }

  // ============================================================
  // INITIALLES
  // ============================================================

  String _getInitials(
    String name,
  ) {
    if (name.trim().isEmpty) {
      return '?';
    }

    final parts = name
        .trim()
        .split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length >= 2 ? 2 : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  // ============================================================
  // ACCEPTER UNE DEMANDE
  // ============================================================

  void _approveRequest(
    PendingRequestModel request,
  ) {
    // Pour l'instant uniquement visuel.
    //
    // Plus tard :
    // await _adminService.approveRequest(request.id);
    //
    // puis :
    // _loadDashboard();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demande de ${request.employeeName} à valider.',
        ),
      ),
    );
  }

  // ============================================================
  // REFUSER UNE DEMANDE
  // ============================================================

  void _rejectRequest(
    PendingRequestModel request,
  ) {
    // Pour l'instant uniquement visuel.
    //
    // Plus tard :
    // await _adminService.rejectRequest(request.id);
    //
    // puis :
    // _loadDashboard();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demande de ${request.employeeName} à refuser.',
        ),
      ),
    );
  }

  // ============================================================
  // ERREUR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 42,
            ),

            const SizedBox(height: 12),

            const Text(
              'Impossible de charger le tableau de bord.',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _error ?? 'Une erreur est survenue.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _loadDashboard,

              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),

              label: const Text(
                'Réessayer',
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}