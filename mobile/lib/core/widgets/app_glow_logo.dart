import 'package:flutter/material.dart';

/// Golden glow logo shared between SplashScreen and AuthGateScreen.
///
/// [size] — width & height in logical pixels (default 200).
/// [glowIntensity] — 0.0 (dark) → 1.0 (full glow); drive with an animation.
class AppGlowLogo extends StatelessWidget {
  final double size;
  final double glowIntensity;

  const AppGlowLogo({
    super.key,
    this.size = 200.0,
    required this.glowIntensity,
  });

  static const Color _goldBorder = Color(0xFFD4A843);
  static const Color _goldGlow   = Color(0xFFE8C55A);

  @override
  Widget build(BuildContext context) {
    final g = glowIntensity;
    final radius = size * 0.20;
    final borderWidth = size * 0.012; // ~2.4 px on 200px logo, scales with size

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Visible golden border
        border: Border.all(
          color: _goldBorder.withAlpha((220 * g).round()),
          width: borderWidth,
        ),
        boxShadow: [
          // Tight outer glow — stays at the border
          BoxShadow(
            color: _goldGlow.withAlpha((160 * g).round()),
            blurRadius: 5 * g,
            spreadRadius: 0,
          ),
          // Softer wide aura — subtle, not bloated
          BoxShadow(
            color: _goldGlow.withAlpha((60 * g).round()),
            blurRadius: 10 * g,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - borderWidth),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
