import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/app_glow_logo.dart';
import '../domain/auth_repository.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen>
    with TickerProviderStateMixin {
  // ── Auth state ─────────────────────────────────────────────────────────────
  bool _loading = false;
  String? _error;

  // ── Logo animation controllers ─────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _glowCtrl;

  late final Animation<double> _scale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    // Entry: fade-in + elastic scale (700 ms)
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
      ),
    );

    // Glow: breathes continuously (950 ms / cycle)
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _glow = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _startLogoAnimation();
  }

  Future<void> _startLogoAnimation() async {
    await _entryCtrl.forward();
    _glowCtrl.repeat(reverse: true); // breathes forever while on this screen
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Auth actions ───────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Router redirect will handle navigation
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
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
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
              // ── Animated glow logo (1.5× splash size = 300 px) ──────────
              AnimatedBuilder(
                animation: Listenable.merge([_entryCtrl, _glowCtrl]),
                builder: (_, __) => Center(
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: AppGlowLogo(
                        size: 300.0,
                        glowIntensity: _glow.value,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

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

              // Sign in with Apple (iOS only)
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
