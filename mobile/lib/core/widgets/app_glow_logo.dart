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
            color: _goldInner.withAlpha((200 * g).round()),
            blurRadius: 28 * g,
            spreadRadius: 2 * g,
          ),
          // Mid glow
          BoxShadow(
            color: _goldOuter.withAlpha((140 * g).round()),
            blurRadius: 60 * g,
            spreadRadius: 6 * g,
          ),
          // Wide halo
          BoxShadow(
            color: _goldHalo.withAlpha((80 * g).round()),
            blurRadius: 120 * g,
            spreadRadius: 4 * g,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        // Transform.scale zooms into the centre of the image so the wallet
        // graphic inside the logo appears 2× larger; ClipRRect clips overflow.
        child: Transform.scale(
          scale: 2.0,
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
