import 'package:flutter/material.dart';

class DrawerProvider extends ChangeNotifier{

final scaffold1 = GlobalKey<ScaffoldState>();
GlobalKey<ScaffoldState> get keyDashboard => scaffold1;
}