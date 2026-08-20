import 'package:attendance/adminfolder/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {

  @override
  Widget build(BuildContext context) {
    // Détection de la taille d'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final bool isDesktop = screenWidth >= 1024;
    
    // Marges dynamiques selon le support
    final double horizontalPadding = isMobile ? 16.0 : (isDesktop ? 32.0 : 24.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: SafeArea(
        child: Column(
          children: [
              
            // Contenu Scrollable Responsive
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200), // Empêche l'étirement excessif sur grands écrans
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. STATS GLOBALES (KPIS) -> 2 colonnes sur mobile/tablette, 4 sur desktop
                        const Text(
                          "PRÉSENCES DU JOUR",
                          style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),
                        
                        GridView.count(
                          crossAxisCount: isDesktop ? 4 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: isDesktop ? 1.8 : 1.5,
                          children: [
                            _buildStatCard("Présents", "42 / 48", Icons.check_circle_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                            _buildStatCard("En Télétravail", "4", Icons.home_work_rounded, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                            _buildStatCard("Absents", "2", Icons.cancel_rounded, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                            _buildStatCard("Retards", "1", Icons.schedule_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // 3. ACTIONS RAPIDES ADMIN / RACCOURCIS
                        const Text(
                          "ACTIONS RAPIDES",
                          style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),
                        
                        // Utilisation d'un Wrap sur mobile si l'espace est restreint, ou Row flexible
                        Row(
                          children: [
                            _buildQuickActionItem("Valider Congés", Icons.event_available_rounded, const Color(0xFF4F46E5), () {}),
                            const SizedBox(width: 12),
                            _buildQuickActionItem("Générer Rapport", Icons.bar_chart_rounded, const Color(0xFF0EA5E9), () {}),
                            const SizedBox(width: 12),
                            _buildQuickActionItem("Ajouter Employé", Icons.person_add_rounded, const Color(0xFF10B981), () {}),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // 4. DEMANDES EN ATTENTE (ALERTES VALIDATION)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "DEMANDES EN ATTENTE",
                              style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text("Voir tout", style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Carte de demande 1
                        _buildPendingRequestCard(
                          name: "Jean Dupont",
                          role: "Développeur Full-Stack",
                          requestType: "Congé payé (5 jours)",
                          dateInfo: "Du 20 au 24 Août",
                          avatarText: "JD",
                        ),
                        const SizedBox(height: 12),
                        // Carte de demande 2
                        _buildPendingRequestCard(
                          name: "Sarah Connor",
                          role: "UI/UX Designer",
                          requestType: "Télétravail",
                          dateInfo: "Vendredi 14 Août",
                          avatarText: "SC",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour une carte de statistique (KPI)
  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Widget pour les actions rapides admin
  Widget _buildQuickActionItem(String label, IconData icon, Color iconColor, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour une carte de demande en attente de validation
  Widget _buildPendingRequestCard({
    required String name,
    required String role,
    required String requestType,
    required String dateInfo,
    required String avatarText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          // Avatar
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
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Infos Employé
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 1),
                Text("$requestType • $dateInfo", style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),
          // Boutons Valider / Refuser
          Row(
            children: [
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF059669), size: 18),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Color(0xFFDC2626), size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}