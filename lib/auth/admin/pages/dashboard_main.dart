import 'package:attendance/auth/admin/pages/dashboard_desktop_page.dart';
import 'package:attendance/auth/admin/pages/dashboard_mobile_page.dart';
import 'package:attendance/auth/admin/pages/dashboard_tablet_page.dart';
import 'package:flutter/material.dart';

import '../../../core/res/responsive.dart';

class DashBoardMain extends StatelessWidget {
  const DashBoardMain({super.key});

  @override
  Widget build(BuildContext context) {
    return Responsive(mobile: DashBoardMobilePage(), tablet: DashBoardTabletPage(), desktop: DashBoardDesktopPage());
  }
}