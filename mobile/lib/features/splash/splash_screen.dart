import 'package:flutter/material.dart';

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

  // ── Gold palette (matches the logo) ────────────────────────────────────────
  static const Color _bg        = Color(0xFF0C0C18);
  static const Color _goldInner = Color(0xFFD4A843);
  static const Color _goldOuter = Color(0xFFE8C55A);
  static const Color _goldHalo  = Color(0xFFF5D060);

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
      animation:
          Listenable.merge([_entryCtrl, _glowCtrl, _exitCtrl]),
      builder: (context, _) {
        final g = _glow.value;

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
                    child: _GlowLogo(glowIntensity: g),
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

// ── Glow logo widget ──────────────────────────────────────────────────────────

class _GlowLogo extends StatelessWidget {
  final double glowIntensity; // 0.0 → 1.0
  const _GlowLogo({required this.glowIntensity});

  @override
  Widget build(BuildContext context) {
    final g = glowIntensity;
    const size = 200.0;
    const radius = 40.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Tight inner glow
          BoxShadow(
            color: _SplashScreenState._goldInner
                .withAlpha((200 * g).round()),
            blurRadius: 28 * g,
            spreadRadius: 2 * g,
          ),
          // Mid glow
          BoxShadow(
            color: _SplashScreenState._goldOuter
                .withAlpha((140 * g).round()),
            blurRadius: 60 * g,
            spreadRadius: 6 * g,
          ),
          // Wide halo
          BoxShadow(
            color: _SplashScreenState._goldHalo
                .withAlpha((80 * g).round()),
            blurRadius: 120 * g,
            spreadRadius: 4 * g,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
