
import 'package:flutter/material.dart';

class EmployeePlanningPage extends StatelessWidget {
  const EmployeePlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              const Text(
                "MON PLANNING",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Août 2026",
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Mini Calendrier Visuel (Exemple de grille de mois)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Jours de la semaine
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                          .map((day) => Text(day, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    // Grille des jours (Simulée pour le mois d'août)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 31, // 31 jours en août
                      itemBuilder: (context, index) {
                        int day = index + 1;
                        // Simulation de statuts : 12 = Aujourd'hui, 10-11 = Weekend, 5-9 = Congé, etc.
                        Color bgColor = Colors.transparent;
                        Color textColor = const Color(0xFF334155);
                        bool isToday = day == 12;

                        if (day == 10 || day == 11 || day == 17 || day == 18 || day == 24 || day == 25 || day == 31) {
                          textColor = const Color(0xFFCBD5E1); // Weekend grisé
                        } else if (day >= 20 && day <= 24) {
                          bgColor = const Color(0xFFFEF3C7); // Congé (Jaune/Orange clair)
                          textColor = const Color(0xFFD97706);
                        } else if (day < 12) {
                          bgColor = const Color(0xFFDCFCE7); // Travaillé (Vert clair)
                          textColor = const Color(0xFF16A34A);
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: isToday ? const Color(0xFF4F46E5) : bgColor,
                            shape: BoxShape.circle,
                            border: isToday ? Border.all(color: const Color(0xFF818CF8), width: 2) : null,
                          ),
                          child: Center(
                            child: Text(
                              "$day",
                              style: TextStyle(
                                color: isToday ? Colors.white : textColor,
                                fontWeight: isToday || bgColor != Colors.transparent ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Légende
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem("Travaillé", const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
                  _buildLegendItem("Congé", const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                  _buildLegendItem("Télétravail", const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
                ],
              ),

              const SizedBox(height: 24),

              // Détail de la journée sélectionnée
              const Text(
                "DÉTAIL DU JOUR (12 AOÛT)",
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow("Arrivée prévue", "08:30"),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildDetailRow("Pointage réel", "08:32 (Bureau Principal)", isGreen: true),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildDetailRow("Pause déjeuner", "12:30 - 13:30"),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildDetailRow("Départ", "En cours..."),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color textColor, Color bgColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle, border: Border.all(color: textColor, width: 2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        Text(value, style: TextStyle(color: isGreen ? const Color(0xFF16A34A) : const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}