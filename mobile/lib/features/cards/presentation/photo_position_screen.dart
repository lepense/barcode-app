import 'dart:io';

import 'package:flutter/material.dart';

/// Result returned by [PhotoPositionScreen].
class PhotoPositionResult {
  final String imagePath;
  final double offsetX;
  final double offsetY;
  final double scale;

  const PhotoPositionResult({
    required this.imagePath,
    required this.offsetX,
    required this.offsetY,
    required this.scale,
  });
}

/// Full-screen editor that lets the user pan and pinch-to-zoom a photo
/// inside a credit-card–shaped frame (ISO 7810 ID-1 ratio 85.6 × 53.98 mm).
///
/// Push this screen and await the result:
/// ```dart
/// final result = await Navigator.push<PhotoPositionResult>(
///   context,
///   MaterialPageRoute(builder: (_) => PhotoPositionScreen(imagePath: path)),
/// );
/// ```
/// Returns [PhotoPositionResult] on confirm, null on cancel.
class PhotoPositionScreen extends StatefulWidget {
  final String imagePath;

  /// Pre-existing position to restore when re-editing.
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialScale;

  const PhotoPositionScreen({
    super.key,
    required this.imagePath,
    this.initialOffsetX = 0.0,
    this.initialOffsetY = 0.0,
    this.initialScale = 1.0,
  });

  @override
  State<PhotoPositionScreen> createState() => _PhotoPositionScreenState();
}

class _PhotoPositionScreenState extends State<PhotoPositionScreen> {
  late double _scale;
  late Offset _offset;

  // Gesture tracking
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _offset = Offset(widget.initialOffsetX, widget.initialOffsetY);
  }

  void _onScaleStart(ScaleStartDetails d) {
    _startScale = _scale;
    _startOffset = _offset;
    _startFocalPoint = d.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      // Clamp zoom: 0.5× – 4×
      _scale = (_startScale * d.scale).clamp(0.5, 4.0);
      // Pan: shift by how much the focal point moved
      _offset = _startOffset + (d.focalPoint - _startFocalPoint);
    });
  }

  void _reset() => setState(() {
        _scale = 1.0;
        _offset = Offset.zero;
      });

  void _apply() {
    Navigator.of(context).pop(
      PhotoPositionResult(
        imagePath: widget.imagePath,
        offsetX: _offset.dx,
        offsetY: _offset.dy,
        scale: _scale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Fotoğrafı Konumlandır'),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('Sıfırla', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Instruction ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              'Kaydırarak konumlandır • Sıkıştırarak yakınlaştır',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // ── Card preview area ──────────────────────────────────────────────
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _CardFrame(
                  imagePath: widget.imagePath,
                  offset: _offset,
                  scale: _scale,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                ),
              ),
            ),
          ),

          // ── Bottom buttons ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _apply,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Uygula'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card-shaped clipping frame with gesture detector ─────────────────────────

class _CardFrame extends StatelessWidget {
  final String imagePath;
  final Offset offset;
  final double scale;
  final void Function(ScaleStartDetails)? onScaleStart;
  final Function(ScaleUpdateDetails)? onScaleUpdate;

  const _CardFrame({
    required this.imagePath,
    required this.offset,
    required this.scale,
    this.onScaleStart,
    this.onScaleUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 85.6 / 53.98,
      child: GestureDetector(
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Photo with user transform ──────────────────────────────
              Transform(
                transform: Matrix4.identity()
                  ..translate(offset.dx, offset.dy)
                  ..scale(scale),
                alignment: Alignment.center,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Colors.grey,
                  ),
                ),
              ),

              // ── Grid overlay to help alignment ─────────────────────────
              Positioned.fill(
                child: CustomPaint(painter: _GridPainter()),
              ),

              // ── Corner outline ─────────────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(100),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // ── Centre crosshair ───────────────────────────────────────
              const Center(
                child: _Crosshair(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subtle grid overlay to aid positioning ────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..strokeWidth = 0.5;
    // Rule-of-thirds lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Tiny centre crosshair ─────────────────────────────────────────────────────

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _CrosshairPainter()),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(120)
      ..strokeWidth = 1.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
