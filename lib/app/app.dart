import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "ATTENDANCE",
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      routerConfig: AppRouter.router,
    );
  }
}