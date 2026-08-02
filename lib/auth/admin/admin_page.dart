import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();

    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString('user');

    if (data != null) {
      setState(() {
        user = jsonDecode(data);
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    if (!mounted) return;

    context.goNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      appBar: AppBar(
        title: const Text("Administration"),

        backgroundColor: const Color(0xFF0F172A),

        foregroundColor: Colors.white,

        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),

      drawer: isMobile ? _drawer() : null,

      body: isMobile
          ? _mobileBody()
          : Row(
              children: [
                SizedBox(width: 260, child: _sideMenu()),

                Expanded(child: _content()),
              ],
            ),
    );
  }

  Widget _mobileBody() {
    return _content();
  }

  Widget _sideMenu() {
    return Container(color: const Color(0xFF0F172A), child: _menuItems());
  }

  Widget _drawer() {
    return Drawer(
      child: Container(color: const Color(0xFF0F172A), child: _menuItems()),
    );
  }

  Widget _menuItems() {
    return Column(
      children: [
        const SizedBox(height: 40),

        const CircleAvatar(
          radius: 40,

          backgroundColor: Colors.white,

          child: Icon(
            Icons.admin_panel_settings,

            size: 45,

            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 15),

        Text(
          user?['name'] ?? "Administrateur",

          style: const TextStyle(
            color: Colors.white,

            fontSize: 18,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 30),

        _menuButton(Icons.dashboard, "Dashboard", 'dashboard'),

        _menuButton(Icons.people, "Employés", 'employees'),

        _menuButton(Icons.access_time, "Présences", 'attendance'),

        _menuButton(Icons.event, "Congés", 'leaves'),

        _menuButton(Icons.analytics, "Rapports", 'reports'),

        const Spacer(),

        _menuButton(Icons.logout, "Déconnexion", null, logout),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _menuButton(
    IconData icon,

    String title,

    String? route, [
    VoidCallback? action,
  ]) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),

      title: Text(title, style: const TextStyle(color: Colors.white)),

      onTap: () {
        if (action != null) {
          action();
        } else if (route != null) {
          context.goNamed(route);
        }
      },
    );
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.all(25),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            "Bienvenue ${user?['name'] ?? ''}",

            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,

              crossAxisSpacing: 20,

              mainAxisSpacing: 20,

              children: [
                _card(Icons.people, "Employés", Colors.blue, 'employees'),

                _card(
                  Icons.fingerprint,

                  "Pointages",

                  Colors.green,

                  'attendance',
                ),

                _card(Icons.calendar_month, "Congés", Colors.orange, 'leaves'),

                _card(Icons.bar_chart, "Rapports", Colors.purple, 'reports'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(IconData icon, String title, Color color, String route) {
    return InkWell(
      onTap: () {
        context.goNamed(route);
      },

      child: Card(
        elevation: 5,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 55, color: color),

            const SizedBox(height: 15),

            Text(
              title,

              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
