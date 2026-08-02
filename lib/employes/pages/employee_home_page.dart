import 'package:attendance/employes/pages/widgets/activity_tile.dart';
import 'package:attendance/employes/pages/widgets/qr_card.dart';
import 'package:attendance/employes/pages/widgets/quick_action.dart';
import 'package:flutter/material.dart';


class EmployeeHomePage extends StatelessWidget {
  const EmployeeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              Container(
                padding: const EdgeInsets.all(20),

                decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5),

                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),

                child: const Column(
                  children: [

                    CircleAvatar(
                      radius: 35,
                      child: Icon(Icons.person, size: 40),
                    ),

                    SizedBox(height: 10),

                    Text(
                      "Tiewa Marius",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "Département IT",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const QrCard(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,

                  children: [

                    QuickAction(
                      title: "Présence",
                      icon: Icons.fact_check,
                      onTap: () {},
                    ),

                    QuickAction(
                      title: "Congés",
                      icon: Icons.beach_access,
                      onTap: () {},
                    ),

                    QuickAction(
                      title: "Profil",
                      icon: Icons.person,
                      onTap: () {},
                    ),

                    QuickAction(
                      title: "QR",
                      icon: Icons.qr_code,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),

                child: Align(
                  alignment: Alignment.centerLeft,

                  child: Text(
                    "Dernières activités",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const ActivityTile(
                title: "Entrée",
                date: "01/08/2026 - 08:00",
                status: "Présent",
              ),

              const ActivityTile(
                title: "Sortie",
                date: "01/08/2026 - 17:30",
                status: "Présent",
              ),
            ],
          ),
        ),
      ),
    );
  }
}