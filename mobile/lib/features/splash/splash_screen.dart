import 'package:flutter/material.dart';

import '../../core/widgets/app_glow_logo.dart';

/// Full-screen animated splash shown once at app startup.
///
/// Animation sequence:
///   0 –  700 ms  → logo fades in + scales up (elastic)
///   700 – 2600 ms → golden glow breathes (2 pulses × 950 ms)
///   2600 – 3100 ms → whole screen fades to black
///   3100 ms       → [onComplete] is called → router takes over
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;   // logo in
  late final AnimationController _glowCtrl;    // breathing glow
  late final AnimationController _exitCtrl;    // screen out

  // ── Animations ─────────────────────────────────────────────────────────────
  late final Animation<double> _scale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _glow;          // 0 → 1 (breathe)
  late final Animation<double> _exitOpacity;   // 1 → 0 (screen out)

  static const Color _bg = Color(0xFF0C0C18);

  @override
  void initState() {
    super.initState();

    // 1. Logo entry (700 ms)
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.0, 0.55, curve: Curves.easeIn)));

    // 2. Glow breath (950 ms / cycle, repeats)
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950));
    _glow = Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // 3. Exit fade (500 ms)
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Phase 1 — logo slides in
    await _entryCtrl.forward();

    // Phase 2 — glow breathes for ~1900 ms (2 full cycles)
    _glowCtrl.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 1900));
    _glowCtrl.stop();

    // Phase 3 — fade out
    await _exitCtrl.forward();

    // Hand off to the router
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entryCtrl, _glowCtrl, _exitCtrl]),
      builder: (context, _) {
        return Opacity(
          opacity: _exitOpacity.value,
          child: ColoredBox(
            color: _bg,
            child: SizedBox.expand(
              child: Center(
                child: Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: AppGlowLogo(size: 400.0, glowIntensity: _glow.value),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
