import 'package:attendance/auth/admin/admin_page.dart';
import 'package:attendance/auth/admin/setup_admin_page.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../auth/login/login_page.dart';
import '../dashboard/dashboard_page.dart';
import '../features/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',

    redirect: (context, state) async {

  final prefs = await SharedPreferences.getInstance();

  final token = prefs.getString('token');

  final isLoggedIn =
      token != null && token.isNotEmpty;


  final location = state.matchedLocation;


  final isLogin = location == '/login';

  final isSplash = location == '/';


  final isSetup = location == '/setup/admin';



  // Pas connecté
  // Autoriser login + splash + setup
  if (!isLoggedIn &&
      !isLogin &&
      !isSplash &&
      !isSetup) {

    return '/login';

  }



  // Déjà connecté
  // Empêcher login/setup après connexion
  if (isLoggedIn &&
      (isLogin || isSetup)) {

    return '/dashboard';

  }


  return null;
},

    routes: [
      GoRoute(path: '/', name: 'splash', builder: (_, _) => const SplashPage()),

      GoRoute(
        path: '/setup/admin',
        name: 'setup-admin',
        builder: (context, state) => const SetupAdminPage(),
      ),


GoRoute(
  path: '/admin',
  name: 'admin',
  builder: (_, __) => const AdminPage(),
),


      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, _) => const LoginPage(),
      ),

      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (_, _) => const DashboardPage(),
      ),

      // Employés
      GoRoute(
        path: '/employees',
        name: 'employees',
        builder: (_, _) => const Placeholder(),
      ),

      // Présence
      GoRoute(
        path: '/attendance',
        name: 'attendance',
        builder: (_, _) => const Placeholder(),
      ),

      // Congés
      GoRoute(
        path: '/leaves',
        name: 'leaves',
        builder: (_, _) => const Placeholder(),
      ),

      // Permissions
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (_, _) => const Placeholder(),
      ),

      // Rapports
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (_, _) => const Placeholder(),
      ),

      // Profil
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, _) => const Placeholder(),
      ),
    ],

    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text(
            'Route introuvable\n${state.uri}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
}
