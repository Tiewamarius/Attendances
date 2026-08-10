import 'package:attendance/auth/admin/pages/dashboard_main.dart';
import 'package:flutter/material.dart';

class DesktopConsole extends StatefulWidget {
  const DesktopConsole({super.key});

  @override
  State<DesktopConsole> createState() => _DesktopConsoleState();
}

class _DesktopConsoleState extends State<DesktopConsole> {
  @override
  Widget build(BuildContext context) {
    return const DashBoardMain();
  }
}