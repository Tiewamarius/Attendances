import 'package:attendance/console_page.dart';
import 'package:attendance/auth/setup_admin_page.dart';
import 'package:attendance/employesfolder/employee_console_page.dart'; 
import 'package:attendance/kioskfolder/attendance_screen.dart';
import 'package:attendance/kioskfolder/kiosk_activation_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_page.dart';
import '../employesfolder/features/splash_page.dart';

class AppRouter {
  AppRouter._();

  static Future<String?> getHomeRoute() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('home_route');
  }

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,

    initialLocation: '/',

    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      final isLoggedIn =
          token != null && token.isNotEmpty;

      final location = state.matchedLocation;

      // ========================================================
      // ROUTES
      // ========================================================

      final isSplash = location == '/';

      final isLogin = location == '/login';

      final isSetup = location == '/setup/admin';

      final isKioskLogin =
          location == '/kiosk/login';

      // ========================================================
      // UTILISATEUR NON CONNECTÉ
      // ========================================================

      if (!isLoggedIn) {
        /*
         * Ces pages sont accessibles sans authentification.
         */
        if (isSplash ||
            isLogin ||
            isSetup ||
            isKioskLogin) {
          return null;
        }

        /*
         * Toutes les autres pages nécessitent
         * une authentification.
         */
        return '/login';
      }

      // ========================================================
      // UTILISATEUR CONNECTÉ
      // ========================================================

      if (isSplash || isLogin) {
        final home = await getHomeRoute();

        switch (home) {
          case 'admin':
            return '/admin';

          case 'kiosk':
            return '/kiosk';

          case 'employees':
            return '/employees';

          case 'manager':
            return '/dashboard';

          default:
            return '/dashboard';
        }
      }

      return null;
    },

    routes: [
      // ========================================================
      // SPLASH
      // ========================================================

      GoRoute(
        path: '/',
        name: 'splash',
        builder: (_, _) => const SplashPage(),
      ),

      // ========================================================
      // LOGIN
      // ========================================================

      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, _) => const LoginPage(),
      ),

      // ========================================================
      // KIOSK LOGIN / ACTIVATION
      // PUBLIC
      // ========================================================

      GoRoute(
        name: 'kiosk-login',
        path: '/kiosk/login',
        builder: (context, state) =>
            const KioskActivationPage(),
      ),

      // ========================================================
      // KIOSK
      // PROTÉGÉ
      // ========================================================

      GoRoute(
        name: 'kiosk',
        path: '/kiosk',
        builder: (context, state) =>
            const AttendanceScreen(),
      ),

      // ========================================================
      // PREMIÈRE CONFIGURATION
      // PUBLIC
      // ========================================================

      GoRoute(
        path: '/setup/admin',
        name: 'setup-admin',
        builder: (_, _) =>
            const SetupAdminPage(),
      ),

      // ========================================================
      // ADMIN
      // PROTÉGÉ
      // ========================================================

      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, _) => const ConsolePage(),
      ),

      // ========================================================
      // EMPLOYEES
      // PROTÉGÉ
      // ========================================================

      GoRoute(
        path: '/employees',
        name: 'employees',
        builder: (_, _) =>
            const EmployeeConsolePage(),
      ),

      // ========================================================
      // ATTENDANCE
      // ========================================================

      GoRoute(
        path: '/attendance',
        name: 'attendance',
        builder: (_, _) =>
            const Placeholder(),
      ),

      // ========================================================
      // LEAVES
      // ========================================================

      GoRoute(
        path: '/leaves',
        name: 'leaves',
        builder: (_, _) =>
            const Placeholder(),
      ),

      // ========================================================
      // PERMISSIONS
      // ========================================================

      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (_, _) =>
            const Placeholder(),
      ),

      // ========================================================
      // REPORTS
      // ========================================================

      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (_, _) =>
            const Placeholder(),
      ),

      // ========================================================
      // PROFILE
      // ========================================================

      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, _) =>
            const Placeholder(),
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