import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_gate_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/cards/presentation/card_list_screen.dart';
import '../features/cards/presentation/card_detail_screen.dart';
import '../features/cards/presentation/add_card_screen.dart';
import '../features/designs/presentation/design_browser_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/account_screen.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Auth routes
      GoRoute(
        path: '/',
        name: 'authGate',
        builder: (context, state) => const AuthGateScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const CardListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'addCard',
            builder: (context, state) => const AddCardScreen(),
          ),
          GoRoute(
            path: 'card/:id',
            name: 'cardDetail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CardDetailScreen(cardId: id);
            },
          ),
        ],
      ),

      // Designs
      GoRoute(
        path: '/designs',
        name: 'designs',
        builder: (context, state) => const DesignBrowserScreen(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'account',
            name: 'account',
            builder: (context, state) => const AccountScreen(),
          ),
        ],
      ),
    ],
  );
}
