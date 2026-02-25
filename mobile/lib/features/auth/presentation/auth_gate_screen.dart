import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../domain/auth_repository.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Router redirect will handle navigation
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),

              // Sign in with Google
              ElevatedButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 12),

              // Sign in with Apple (iOS only, hidden on Android/Web)
              if (Theme.of(context).platform == TargetPlatform.iOS)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _signInWithApple,
                    icon: const Icon(Icons.apple),
                    label: const Text('Sign in with Apple'),
                  ),
                ),

              // Sign in with Email
              OutlinedButton.icon(
                onPressed: _loading ? null : () => context.push('/login'),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Sign in with Email'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _loading ? null : () => context.push('/signup'),
                child: const Text("Don't have an account? Sign up"),
              ),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
