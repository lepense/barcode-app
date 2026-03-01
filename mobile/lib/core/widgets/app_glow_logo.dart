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

  static const Color _goldInner = Color(0xFFD4A843);
  static const Color _goldOuter = Color(0xFFE8C55A);
  static const Color _goldHalo  = Color(0xFFF5D060);

  @override
  Widget build(BuildContext context) {
    final g = glowIntensity;
    final radius = size * 0.20; // keeps the corner ratio consistent

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Tight inner glow
          BoxShadow(
            color: _goldInner.withAlpha((130 * g).round()),
            blurRadius: 12 * g,
            spreadRadius: 1 * g,
          ),
          // Mid glow
          BoxShadow(
            color: _goldOuter.withAlpha((90 * g).round()),
            blurRadius: 26 * g,
            spreadRadius: 2 * g,
          ),
          // Soft outer halo
          BoxShadow(
            color: _goldHalo.withAlpha((45 * g).round()),
            blurRadius: 50 * g,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        // BoxFit.contain shows the full PNG scaled to fill the square
        // container — the wallet is always fully visible and centred
        // regardless of where it sits inside the original image file.
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
