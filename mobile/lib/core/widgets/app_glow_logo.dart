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

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.20; // keeps the corner ratio consistent

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
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
