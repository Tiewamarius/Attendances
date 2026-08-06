import 'package:attendance/adminfolder/model/menu_model.dart';
import 'package:flutter/material.dart';

class SideMenuData {
  final menu = const <MenuModel>[
    MenuModel(icon: Icons.home, title: 'Dashboard'),
    MenuModel(icon: Icons.people, title: 'Employés'),
    MenuModel(icon: Icons.access_time, title: 'Présences'),
    MenuModel(icon: Icons.event, title: 'Congés'),
    MenuModel(icon: Icons.analytics, title: 'Rapports'),
 
    MenuModel(icon: Icons.logout, title: 'Deconnexion'),
  ];
}

