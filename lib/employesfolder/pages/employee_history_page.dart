import 'package:flutter/material.dart';

class EmployeeHistoryPage extends StatelessWidget {
  const EmployeeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Liste simulée d'historique de pointage
    final List<Map<String, dynamic>> historyItems = [
      {'date': 'Mardi 11 Août 2026', 'arrivee': '08:28', 'depart': '17:35', 'total': '8h07', 'status': 'Normal'},
      {'date': 'Lundi 10 Août 2026', 'arrivee': '08:45', 'depart': '17:30', 'total': '7h45', 'status': 'Retard'},
      {'date': 'Vendredi 7 Août 2026', 'arrivee': '08:30', 'depart': '17:00', 'total': '7h30', 'status': 'Normal'},
      {'date': 'Jeudi 6 Août 2026', 'arrivee': '-', 'depart': '-', 'total': '0h00', 'status': 'Congé'},
      {'date': 'Mercredi 5 Août 2026', 'arrivee': '08:15', 'depart': '17:45', 'total': '8h30', 'status': 'Normal'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "HISTORIQUE",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Mes Pointages",
                        style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  // Filtre rapide
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF4F46E5)),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Liste des pointages passés
              Expanded(
                child: ListView.separated(
                  itemCount: historyItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = historyItems[index];
                    bool isLeave = item['status'] == 'Congé';
                    bool isRetard = item['status'] == 'Retard';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['date'],
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              // Badge de Statut
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLeave
                                      ? const Color(0xFFFEF3C7)
                                      : isRetard
                                          ? const Color(0xFFFEE2E2)
                                          : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['status'],
                                  style: TextStyle(
                                    color: isLeave
                                        ? const Color(0xFFD97706)
                                        : isRetard
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF16A34A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          isLeave
                              ? const Text(
                                  "Journée de congé validée",
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildTimeInfo("Arrivée", item['arrivee']),
                                    _buildTimeInfo("Départ", item['depart']),
                                    _buildTimeInfo("Total", item['total'], isBold: true),
                                  ],
                                ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            color: const Color(0xFF334155),
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}