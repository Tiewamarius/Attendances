import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login/login_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/splash/presentation/splash_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',

    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
    ],

    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text(
            "Route introuvable\n${state.uri}",
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
}