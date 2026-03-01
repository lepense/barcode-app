import 'package:flutter/material.dart';

/// Golden pulse-ring logo shared between SplashScreen and AuthGateScreen.
///
/// [size] — width & height in logical pixels (default 200).
/// [glowIntensity] — 0.0 → 1.0; drives border opacity & ring visibility.
class AppGlowLogo extends StatefulWidget {
  final double size;
  final double glowIntensity;

  const AppGlowLogo({
    super.key,
    this.size = 200.0,
    required this.glowIntensity,
  });

  @override
  State<AppGlowLogo> createState() => _AppGlowLogoState();
}

class _AppGlowLogoState extends State<AppGlowLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  static const Color _gold = Color(0xFFD4A843);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scale = Tween<double>(begin: 1.0, end: 1.30).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.75, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.glowIntensity;
    final size = widget.size;
    final radius = size * 0.20;
    final borderWidth = size * 0.005;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none, // ring can overflow the widget bounds
          children: [
            // ── Expanding pulse ring ──────────────────────────────────────
            Opacity(
              opacity: (_opacity.value * g).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: _gold,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // ── Logo with thin static golden border ───────────────────────
            child!,
          ],
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: _gold.withAlpha((180 * g).round()),
            width: borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - borderWidth),
          child: Image.asset(
            'assets/images/logo.png',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
