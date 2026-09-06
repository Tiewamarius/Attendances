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

  // ============================================================
  // HOME ROUTE
  // ============================================================

  static Future<String?> getHomeRoute() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('home_route');
  }

  // ============================================================
  // ORGANISATION ACTIVE
  // ============================================================

  static Future<bool> hasActiveOrganization() async {
    final prefs = await SharedPreferences.getInstance();

    final organization = prefs.getString('organization');

    return organization != null && organization.isNotEmpty;
  }

  // ============================================================
  // ROUTER
  // ============================================================

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,

    initialLocation: '/',

    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();

      // ========================================================
      // AUTHENTIFICATION
      // ========================================================

      final token = prefs.getString('token');

      final isLoggedIn =
          token != null && token.trim().isNotEmpty;

      // ========================================================
      // ORGANISATION ACTIVE
      // ========================================================

      final organizationJson =
          prefs.getString('organization');

      final hasOrganization =
          organizationJson != null &&
          organizationJson.trim().isNotEmpty;

      // ========================================================
      // LOCALISATION ACTUELLE
      // ========================================================

      final location = state.matchedLocation;

      // ========================================================
      // ROUTES PUBLIQUES
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
        debugPrint(
          '[ROUTER] Utilisateur non connecté.',
        );

        // Ces pages restent accessibles sans authentification.
        if (isSplash ||
            isLogin ||
            isSetup ||
            isKioskLogin) {
          return null;
        }

        // Toute autre route nécessite une connexion.
        debugPrint(
          '[ROUTER] Redirection vers /login',
        );

        return '/login';
      }

      // ========================================================
      // UTILISATEUR CONNECTÉ
      // ========================================================

      debugPrint(
        '[ROUTER] Utilisateur connecté.',
      );

      debugPrint(
        '[ROUTER] Organisation active : $hasOrganization',
      );

      // ========================================================
      // SPLASH / LOGIN
      // ========================================================

      if (isSplash || isLogin) {
        final home = await getHomeRoute();

        debugPrint(
          '[ROUTER] Home route sauvegardée : $home',
        );

        // ------------------------------------------------------
        // Aucune organisation active
        // ------------------------------------------------------

        if (!hasOrganization) {
          debugPrint(
            '[ROUTER] Aucune organisation active.',
          );

          // Pour l'instant on revient sur la console admin.
          // La sélection d'organisation pourra ensuite être
          // ajoutée ici lorsque l'utilisateur possède plusieurs
          // organisations.
          return '/admin';
        }

        // ------------------------------------------------------
        // Organisation active
        // ------------------------------------------------------

        switch (home) {
          case 'admin':
            return '/admin';

          case 'employees':
            return '/employees';

          case 'kiosk':
            return '/kiosk';

          default:
            // Toute nouvelle connexion avec organisation active
            // arrive par défaut sur l'administration.
            return '/admin';
        }
      }

      // ========================================================
      // ROUTES PROTÉGÉES
      // ========================================================

      return null;
    },

    // ============================================================
    // ROUTES
    // ============================================================

    routes: [

      // ==========================================================
      // SPLASH
      // ==========================================================

      GoRoute(
        path: '/',
        name: 'splash',
        builder: (_, __) => const SplashPage(),
      ),

      // ==========================================================
      // LOGIN
      // ==========================================================

      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),

      // ==========================================================
      // KIOSK LOGIN / ACTIVATION
      // PUBLIC
      // ==========================================================

      GoRoute(
        path: '/kiosk/login',
        name: 'kiosk-login',
        builder: (context, state) =>
            const KioskActivationPage(),
      ),

      // ==========================================================
      // KIOSK
      // PROTÉGÉ
      // ==========================================================

      GoRoute(
        path: '/kiosk',
        name: 'kiosk',
        builder: (context, state) =>
            const AttendanceScreen(),
      ),

      // ==========================================================
      // PREMIÈRE CONFIGURATION
      // PUBLIC
      // ==========================================================

      GoRoute(
        path: '/setup/admin',
        name: 'setup-admin',
        builder: (_, __) =>
            const SetupAdminPage(),
      ),

      // ==========================================================
      // ADMIN / ORGANISATION
      // PROTÉGÉ
      // ==========================================================

      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) =>
            const ConsolePage(),
      ),

      // ==========================================================
      // EMPLOYÉS
      // PROTÉGÉ
      // ==========================================================

      GoRoute(
        path: '/employees',
        name: 'employees',
        builder: (_, __) =>
            const EmployeeConsolePage(),
      ),

      // ==========================================================
      // PRÉSENCES
      // ==========================================================

      GoRoute(
        path: '/attendance',
        name: 'attendance',
        builder: (_, __) =>
            const Placeholder(),
      ),

      // ==========================================================
      // CONGÉS
      // ==========================================================

      GoRoute(
        path: '/leaves',
        name: 'leaves',
        builder: (_, __) =>
            const Placeholder(),
      ),

      // ==========================================================
      // PERMISSIONS
      // ==========================================================

      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (_, __) =>
            const Placeholder(),
      ),

      // ==========================================================
      // RAPPORTS
      // ==========================================================

      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (_, __) =>
            const Placeholder(),
      ),

      // ==========================================================
      // PROFIL
      // ==========================================================

      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) =>
            const Placeholder(),
      ),
    ],

    // ============================================================
    // ERREUR
    // ============================================================

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