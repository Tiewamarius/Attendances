import 'package:attendance/adminfolder/screens/main_screen.dart';
import 'package:attendance/auth/admin/setup_admin_page.dart';
import 'package:attendance/features/kiosk/kiosk_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login/login_page.dart';
import '../dashboard/dashboard_page.dart';
import '../features/splash_page.dart';

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

      final isLoggedIn = token != null && token.isNotEmpty;

      final location = state.matchedLocation;

      final isSplash = location == '/';

      final isLogin = location == '/login';

      final isSetup = location == '/setup/admin';

      /*
      ==========================
      NON CONNECTE
      ==========================
      */

      if (!isLoggedIn) {
        if (isSplash || isLogin || isSetup) {
          return null;
        }

        return '/login';
      }

      /*
      ==========================
      CONNECTE
      ==========================
      */

      if (isSplash || isLogin) {
        final home = await getHomeRoute();

        switch (home) {
          case 'admin':
            return '/admin';

          case 'kiosk':
            return '/kiosk';

          case 'employee-home':
            return '/dashboard';

          default:
            return '/dashboard';
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/',

        name: 'splash',

        builder: (_, _) => const SplashPage(),
      ),

      GoRoute(
        path: '/login',

        name: 'login',

        builder: (_, _) => const LoginPage(),
      ),

      GoRoute(
        path: '/setup/admin',

        name: 'setup-admin',

        builder: (_, _) => const SetupAdminPage(),
      ),

      GoRoute(
        path: '/admin',

        name: 'admin',

        builder: (_, _) => const MainScreen(),
      ),

      GoRoute(
        path: '/kiosk',

        name: 'kiosk',

        builder: (_, _) => const KioskPage(),
      ),

      GoRoute(
        path: '/dashboard',

        name: 'dashboard',

        builder: (_, _) => const DashboardPage(),
      ),

      GoRoute(
        path: '/employees',

        name: 'employees',

        builder: (_, _) => const Placeholder(),
      ),

      GoRoute(
        path: '/attendance',

        name: 'attendance',

        builder: (_, _) => const Placeholder(),
      ),

      GoRoute(
        path: '/leaves',

        name: 'leaves',

        builder: (_, _) => const Placeholder(),
      ),

      GoRoute(
        path: '/permissions',

        name: 'permissions',

        builder: (_, _) => const Placeholder(),
      ),

      GoRoute(
        path: '/reports',

        name: 'reports',

        builder: (_, _) => const Placeholder(),
      ),

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
