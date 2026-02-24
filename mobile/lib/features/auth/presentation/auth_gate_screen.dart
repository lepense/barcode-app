import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.qr_code_2,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Barcode App',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your loyalty cards, organized.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              // Sign in with Google
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement Google sign-in
                },
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 12),
              // Sign in with Apple
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement Apple sign-in
                },
                icon: const Icon(Icons.apple),
                label: const Text('Sign in with Apple'),
              ),
              const SizedBox(height: 12),
              // Sign in with Email
              OutlinedButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Sign in with Email'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
