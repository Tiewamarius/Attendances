
import 'package:attendance/core/res/responsive.dart';
import 'package:attendance/pages/admin/console/desktop_console.dart';
import 'package:attendance/pages/admin/console/mobile_console.dart';
import 'package:attendance/pages/admin/console/tablet_console.dart';
import 'package:flutter/material.dart';

class ConsolePage extends StatelessWidget {
  const ConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Responsive(desktop: DesktopConsole(),mobile: MobileConsole(),tablet: TabletConsole(), );
  }
}