import 'package:flutter/material.dart';

class DashBoardMobilePage extends StatefulWidget {
  const DashBoardMobilePage({super.key});

  @override
  State<DashBoardMobilePage> createState() => _DashBoardMobilePageState();
}

class _DashBoardMobilePageState extends State<DashBoardMobilePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text(
          'Mobile Dashboard',
          style: TextStyle(fontSize: 24),
        ),
      )
    );
  }
}