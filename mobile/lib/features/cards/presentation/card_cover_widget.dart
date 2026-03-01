import 'dart:io';

import 'package:flutter/material.dart';

import '../../designs/domain/design_catalog.dart';
import '../../designs/domain/design_model.dart';
import '../../designs/presentation/doodle_painter.dart';
import '../domain/card_model.dart';

// ── Fallback gradient palettes (used when no design is assigned) ──────────────

const _kFallbackPalettes = [
  ['#1565C0', '#1976D2', '#42A5F5'], // Sapphire blue
  ['#00695C', '#00897B', '#4DB6AC'], // Teal
  ['#6A1B9A', '#8E24AA', '#CE93D8'], // Amethyst purple
  ['#E65100', '#F57C00', '#FFB74D'], // Amber orange
  ['#880E4F', '#C2185B', '#F48FB1'], // Ruby red
  ['#1B5E20', '#2E7D32', '#81C784'], // Emerald green
  ['#0D47A1', '#1565C0', '#4FC3F7'], // Navy blue
  ['#311B92', '#4527A0', '#9575CD'], // Deep indigo
];

Color _hex(String h) {
  final s = h.replaceFirst('#', '');
  return Color(int.parse('FF$s', radix: 16));
}

/// Resolves the gradient colors for [card].
///
/// Uses the card's assigned design if set, otherwise picks a deterministic
/// fallback palette based on the first character of the merchant name.
List<Color> resolveCardColors(LoyaltyCard card) {
  final design = card.coverDesignId != null
      ? DesignCatalog.findById(card.coverDesignId!)
      : null;
  if (design != null) return design.gradientColors.map(_hex).toList();

  final idx = card.merchantName.isEmpty
      ? 0
      : card.merchantName.codeUnitAt(0) % _kFallbackPalettes.length;
  return _kFallbackPalettes[idx].map(_hex).toList();
}

/// Resolves the [DoodlePattern] for [card], if any.
DoodlePattern? resolveCardPattern(LoyaltyCard card) {
  if (card.coverDesignId == null) return null;
  return DesignCatalog.findById(card.coverDesignId!)?.patternType;
}

// ── LoyaltyCardCover ──────────────────────────────────────────────────────────

/// A full-width, credit-card proportioned widget (85.6 × 53.98 mm ratio)
/// that renders the card's gradient design with a chip, merchant name, and
/// barcode-type badge.
///
/// Wrap in a [GestureDetector] or pass [onTap] to make it tappable.
class LoyaltyCardCover extends StatelessWidget {
  final LoyaltyCard card;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const LoyaltyCardCover({
    super.key,
    required this.card,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final colors = resolveCardColors(card);
    final pattern = resolveCardPattern(card);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: margin,
        child: AspectRatio(
          aspectRatio: 85.6 / 53.98, // ISO 7810 ID-1 standard credit card
          child: _CardBody(card: card, colors: colors, pattern: pattern),
        ),
      ),
    );
  }
}

// ── _CardBody ─────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  final LoyaltyCard card;
  final List<Color> colors;
  final DoodlePattern? pattern;

  const _CardBody({
    required this.card,
    required this.colors,
    this.pattern,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = card.customCoverImagePath != null &&
        card.customCoverImagePath!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Show gradient only when there is no custom photo
        gradient: hasPhoto
            ? null
            : LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: hasPhoto ? Colors.black : null,
        boxShadow: [
          BoxShadow(
            color: hasPhoto
                ? Colors.black.withOpacity(0.4)
                : colors.first.withOpacity(0.5),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // ── Custom photo background (takes priority over gradient) ─────
            if (card.customCoverImagePath != null &&
                card.customCoverImagePath!.isNotEmpty)
              Positioned.fill(
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(
                      card.coverImageOffsetX ?? 0.0,
                      card.coverImageOffsetY ?? 0.0,
                    )
                    ..scale(card.coverImageScale ?? 1.0),
                  alignment: Alignment.center,
                  child: Image.file(
                    File(card.customCoverImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

            // ── Decorative background circles (gradient mode only) ─────────
            if (card.customCoverImagePath == null ||
                card.customCoverImagePath!.isEmpty) ...[
              Positioned(
                right: -30,
                top: -30,
                child: _Circle(size: 160, opacity: 0.08),
              ),
              Positioned(
                right: 24,
                bottom: -44,
                child: _Circle(size: 120, opacity: 0.06),
              ),
              Positioned(
                left: -18,
                bottom: -18,
                child: _Circle(size: 90, opacity: 0.05),
              ),
            ],

            // ── Doodle pattern overlay ─────────────────────────────────────
            if (pattern != null && !hasPhoto)
              Positioned.fill(
                child: CustomPaint(
                  painter: DoodlePainter(pattern!),
                ),
              ),

            // ── Top row: sync icon + barcode type badge ────────────────────
            Positioned(
              top: 14,
              left: 18,
              right: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    card.isSynced
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: Colors.white.withOpacity(0.65),
                    size: 16,
                  ),
                  _BarcodeTypeBadge(type: card.barcodeType),
                ],
              ),
            ),

            // ── EMV Chip (centre-left) ─────────────────────────────────────
            Positioned(
              left: 18,
              top: 0,
              bottom: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: const _EmvChip(),
              ),
            ),

            // ── Bottom scrim + merchant name ───────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
                child: Text(
                  card.merchantName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;
  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _BarcodeTypeBadge extends StatelessWidget {
  final String type;
  const _BarcodeTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Simulated EMV / gold chip rendered with a gradient container + line painter.
class _EmvChip extends StatelessWidget {
  const _EmvChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A843), Color(0xFFF5C842), Color(0xFFD4A843)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFFBF9000).withOpacity(0.8),
          width: 0.8,
        ),
      ),
      child: CustomPaint(painter: _ChipLinePainter()),
    );
  }
}

class _ChipLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9A6800).withOpacity(0.55)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Vertical centre line
    canvas.drawLine(
      Offset(size.width / 2, 2),
      Offset(size.width / 2, size.height - 2),
      paint,
    );
    // Horizontal contact-pad lines
    for (final t in [0.33, 0.67]) {
      canvas.drawLine(
        Offset(2, size.height * t),
        Offset(size.width - 2, size.height * t),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
