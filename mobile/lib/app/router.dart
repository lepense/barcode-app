import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/auth_provider.dart';
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

/// Creates a GoRouter that reacts to auth state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      // Not logged in and trying to access protected route -> auth gate
      if (!isLoggedIn && !isAuthRoute) return '/';

      // Logged in and on auth route -> home
      if (isLoggedIn && isAuthRoute) return '/home';

      return null; // No redirect
    },
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

      // Designs — state.extra is an optional cardId String when picking a design
      GoRoute(
        path: '/designs',
        name: 'designs',
        builder: (context, state) => DesignBrowserScreen(
          pickForCardId: state.extra as String?,
        ),
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
});
