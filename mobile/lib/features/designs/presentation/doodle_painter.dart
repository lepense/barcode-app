import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/design_model.dart';

/// A [CustomPainter] that tiles a doodle pattern across the entire canvas.
///
/// All patterns draw white lines/shapes at a low opacity so they work on
/// any gradient background without requiring any image assets.
class DoodlePainter extends CustomPainter {
  final DoodlePattern pattern;

  const DoodlePainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    switch (pattern) {
      case DoodlePattern.polkaDots:
        _drawPolkaDots(canvas, size);
      case DoodlePattern.stripes:
        _drawStripes(canvas, size);
      case DoodlePattern.zigzag:
        _drawZigzag(canvas, size);
      case DoodlePattern.stars:
        _drawStars(canvas, size);
      case DoodlePattern.hearts:
        _drawHearts(canvas, size);
      case DoodlePattern.crosshatch:
        _drawCrosshatch(canvas, size);
      case DoodlePattern.waves:
        _drawWaves(canvas, size);
      case DoodlePattern.triangles:
        _drawTriangles(canvas, size);
      case DoodlePattern.flowers:
        _drawFlowers(canvas, size);
      case DoodlePattern.scribbles:
        _drawScribbles(canvas, size);
    }
  }

  // ── Polka Dots ────────────────────────────────────────────────────────────

  void _drawPolkaDots(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    const spacing = 22.0;
    const radius = 4.0;

    int row = 0;
    for (double y = spacing / 2; y < size.height + spacing; y += spacing) {
      final offsetX = (row % 2 == 0) ? 0.0 : spacing / 2;
      for (double x = offsetX; x < size.width + spacing; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
      row++;
    }
  }

  // ── Diagonal Stripes ─────────────────────────────────────────────────────

  void _drawStripes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    const gap = 20.0;
    final diagonal = size.width + size.height;

    for (double i = -diagonal; i < diagonal; i += gap) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  // ── Zigzag ────────────────────────────────────────────────────────────────

  void _drawZigzag(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    const rowHeight = 16.0;
    const segmentWidth = 16.0;

    for (double y = rowHeight / 2; y < size.height + rowHeight; y += rowHeight * 2) {
      final path = Path();
      bool up = true;
      path.moveTo(0, y);
      for (double x = 0; x < size.width + segmentWidth; x += segmentWidth) {
        path.lineTo(x, up ? y - rowHeight / 2 : y + rowHeight / 2);
        up = !up;
      }
      canvas.drawPath(path, paint);
    }
  }

  // ── Stars ─────────────────────────────────────────────────────────────────

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spacing = 32.0;

    int row = 0;
    for (double y = spacing / 2; y < size.height + spacing; y += spacing) {
      final offsetX = (row % 2 == 0) ? 0.0 : spacing / 2;
      for (double x = offsetX; x < size.width + spacing; x += spacing) {
        _drawStar(canvas, Offset(x, y), 7.0, paint);
      }
      row++;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 5;
    const innerFactor = 0.45;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final angle = (math.pi / points) * i - math.pi / 2;
      final r = (i % 2 == 0) ? radius : radius * innerFactor;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ── Hearts ────────────────────────────────────────────────────────────────

  void _drawHearts(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    int row = 0;
    for (double y = spacing / 2; y < size.height + spacing; y += spacing) {
      final offsetX = (row % 2 == 0) ? 0.0 : spacing / 2;
      for (double x = offsetX; x < size.width + spacing; x += spacing) {
        _drawHeart(canvas, Offset(x, y), 8.0, paint);
      }
      row++;
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final x = center.dx;
    final y = center.dy;
    final s = size * 0.9;

    path.moveTo(x, y + s * 0.4);
    path.cubicTo(x - s, y - s * 0.2, x - s, y - s * 0.8, x, y - s * 0.35);
    path.cubicTo(x + s, y - s * 0.8, x + s, y - s * 0.2, x, y + s * 0.4);
    canvas.drawPath(path, paint);
  }

  // ── Crosshatch ────────────────────────────────────────────────────────────

  void _drawCrosshatch(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const gap = 16.0;

    // Forward diagonals
    for (double i = -size.height; i < size.width + size.height; i += gap) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
    // Backward diagonals
    for (double i = -(size.width + size.height); i < size.width + size.height; i += gap) {
      canvas.drawLine(Offset(i, size.height), Offset(i + size.height, 0), paint);
    }
  }

  // ── Waves ─────────────────────────────────────────────────────────────────

  void _drawWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const amplitude = 6.0;
    const waveLength = 30.0;
    const rowGap = 16.0;

    for (double y = rowGap; y < size.height + rowGap; y += rowGap) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 1) {
        final dy = amplitude * math.sin((x / waveLength) * 2 * math.pi);
        path.lineTo(x, y + dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  // ── Triangles ─────────────────────────────────────────────────────────────

  void _drawTriangles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const s = 20.0; // side length
    final h = s * math.sqrt(3) / 2;
    const cols = 7;
    const rows = 5;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final xOffset = col * s + (row % 2 == 0 ? 0 : s / 2);
        final yOffset = row * h;

        // Upward triangle
        final path = Path()
          ..moveTo(xOffset, yOffset + h)
          ..lineTo(xOffset + s / 2, yOffset)
          ..lineTo(xOffset + s, yOffset + h)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  // ── Flowers ───────────────────────────────────────────────────────────────

  void _drawFlowers(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spacing = 32.0;

    int row = 0;
    for (double y = spacing / 2; y < size.height + spacing; y += spacing) {
      final offsetX = (row % 2 == 0) ? 0.0 : spacing / 2;
      for (double x = offsetX; x < size.width + spacing; x += spacing) {
        _drawFlower(canvas, Offset(x, y), 8.0, paint);
      }
      row++;
    }
  }

  void _drawFlower(Canvas canvas, Offset center, double r, Paint paint) {
    const petals = 6;
    for (int i = 0; i < petals; i++) {
      final angle = (2 * math.pi / petals) * i;
      final petalCenter = Offset(
        center.dx + r * 0.7 * math.cos(angle),
        center.dy + r * 0.7 * math.sin(angle),
      );
      canvas.drawCircle(petalCenter, r * 0.45, paint);
    }
    // Centre dot
    canvas.drawCircle(center, r * 0.28, paint);
  }

  // ── Scribbles ─────────────────────────────────────────────────────────────

  void _drawScribbles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Deterministic pseudo-random scribble grid
    final rng = math.Random(42);
    const cellSize = 28.0;

    for (double cy = 0; cy < size.height + cellSize; cy += cellSize) {
      for (double cx = 0; cx < size.width + cellSize; cx += cellSize) {
        final path = Path();
        final sx = cx + rng.nextDouble() * cellSize * 0.4;
        final sy = cy + rng.nextDouble() * cellSize * 0.4;
        path.moveTo(sx, sy);
        for (int k = 0; k < 3; k++) {
          final ex = cx + rng.nextDouble() * cellSize;
          final ey = cy + rng.nextDouble() * cellSize;
          final cx1 = cx + rng.nextDouble() * cellSize;
          final cy1 = cy + rng.nextDouble() * cellSize;
          path.quadraticBezierTo(cx1, cy1, ex, ey);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DoodlePainter old) => old.pattern != pattern;
}
