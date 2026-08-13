import 'package:attendance/adminfolder/desktop_console.dart';
import 'package:attendance/adminfolder/mobile_console.dart';
import 'package:attendance/adminfolder/tablet_console.dart';
import 'package:attendance/core/res/responsive.dart';
import 'package:flutter/material.dart';

class ConsolePage extends StatelessWidget {
  const ConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Responsive(mobile: MobileConsole(), tablet: TabletConsole(), desktop: DesktopConsole());
  }
}