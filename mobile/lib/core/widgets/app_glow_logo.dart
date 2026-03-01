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
    final borderWidth = size * 0.005; // ~1 px on 200px logo, scales with size

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
          BoxShadow(
            color: _goldGlow.withAlpha((140 * g).round()),
            blurRadius: 3 * g,
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
