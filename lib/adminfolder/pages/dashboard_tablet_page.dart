import 'package:flutter/material.dart';

class DashBoardTabletPage extends StatefulWidget {
  const DashBoardTabletPage({super.key});

  @override
  State<DashBoardTabletPage> createState() => _DashBoardTabletPageState();
}

class _DashBoardTabletPageState extends State<DashBoardTabletPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text(
          'Tablet Dashboard',
          style: TextStyle(fontSize: 24),
        ),
      )
    );
  }
}