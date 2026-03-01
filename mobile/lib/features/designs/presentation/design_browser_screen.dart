import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/cards_provider.dart';
import '../../../core/providers/custom_photo_templates_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/entitlements_provider.dart';
import '../../../core/providers/iap_provider.dart';
import '../../cards/presentation/photo_position_screen.dart';
import '../../iap/domain/entitlements_model.dart';
import '../domain/design_catalog.dart';
import '../domain/design_model.dart';
import 'doodle_painter.dart';
import 'paywall_sheet.dart';

enum _DesignFilter { all, free, owned }

class DesignBrowserScreen extends ConsumerStatefulWidget {
  /// When non-null, selecting a design/template applies it to this card ID
  /// and pops back.  When null, the screen is in browse-only mode.
  final String? pickForCardId;

  const DesignBrowserScreen({super.key, this.pickForCardId});

  @override
  ConsumerState<DesignBrowserScreen> createState() =>
      _DesignBrowserScreenState();
}

class _DesignBrowserScreenState extends ConsumerState<DesignBrowserScreen> {
  _DesignFilter _filter = _DesignFilter.all;
  bool _isPickingPhoto = false;

  List<CoverDesign> _filtered(EntitlementsModel ent) {
    return switch (_filter) {
      _DesignFilter.all => DesignCatalog.all,
      _DesignFilter.free =>
        DesignCatalog.all.where((d) => !d.isPremium).toList(),
      _DesignFilter.owned =>
        DesignCatalog.all.where((d) => ent.hasDesign(d)).toList(),
    };
  }

  // ── Design tile tap ──────────────────────────────────────────────────────

  void _onDesignTap(CoverDesign design, EntitlementsModel ent) {
    if (ent.hasDesign(design)) {
      if (widget.pickForCardId != null) {
        context.pop(design.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${design.name}" seçildi')),
        );
      }
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => PaywallSheet(design: design),
      );
    }
  }

  // ── Photo picker → save as template ──────────────────────────────────────

  Future<void> _pickAndPositionPhoto(ImageSource source) async {
    setState(() => _isPickingPhoto = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;

      // Copy to app documents so it outlives the gallery selection.
      final docsDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory(p.join(docsDir.path, 'card_covers'));
      if (!coversDir.existsSync()) coversDir.createSync(recursive: true);

      final ext = p.extension(picked.path).isEmpty
          ? '.jpg'
          : p.extension(picked.path);
      final fileName =
          'photo_tmpl_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = p.join(coversDir.path, fileName);
      await File(picked.path).copy(destPath);

      if (!mounted) return;

      // Let user position / zoom the photo inside a card-shaped frame.
      final result = await Navigator.push<PhotoPositionResult>(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoPositionScreen(imagePath: destPath),
        ),
      );

      if (result == null || !mounted) return;

      // Save as a reusable template in the DB.
      final db = ref.read(databaseProvider);
      await db.customPhotoTemplatesDao.insertTemplate(
        CustomPhotoTemplatesCompanion(
          imagePath: Value(result.imagePath),
          offsetX: Value(result.offsetX),
          offsetY: Value(result.offsetY),
          scale: Value(result.scale),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf şablonu kaydedildi ✓'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  // ── Apply a photo template to the card ────────────────────────────────────

  Future<void> _applyTemplate(CustomPhotoTemplate tmpl) async {
    if (widget.pickForCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uygulamak için kart detayından tasarım seç'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final cardId = int.tryParse(widget.pickForCardId!);
    if (cardId == null) return;

    final repo = ref.read(cardRepositoryProvider);
    final card = await repo.getCardById(cardId);
    await repo.updateCard(
      card.copyWith(
        customCoverImagePath: tmpl.imagePath,
        coverDesignId: null,
        coverImageOffsetX: tmpl.offsetX,
        coverImageOffsetY: tmpl.offsetY,
        coverImageScale: tmpl.scale,
      ),
    );
    if (mounted) context.pop();
  }

  // ── Delete a template with confirmation ───────────────────────────────────

  Future<void> _deleteTemplate(CustomPhotoTemplate tmpl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şablonu sil'),
        content: const Text(
            'Bu fotoğraf şablonu listeden kaldırılsın mı?\n'
            'Kartlara uygulanmış fotoğraflar etkilenmez.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await db.customPhotoTemplatesDao.deleteTemplate(tmpl.id);
    }
  }

  // ── Source picker bottom sheet ─────────────────────────────────────────────

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndPositionPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Fotoğraf çek'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndPositionPhoto(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final entitlementsAsync = ref.watch(entitlementsProvider);
    final templatesAsync = ref.watch(customPhotoTemplatesProvider);

    // Pre-warm the IAP service.
    ref.watch(iapServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pickForCardId != null ? 'Tasarım Seç' : 'Tasarımlar',
        ),
      ),
      body: entitlementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (ent) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── "Add photo" banner ──────────────────────────────────────
              _AddPhotoTile(
                isLoading: _isPickingPhoto,
                onTap: _isPickingPhoto ? null : _showPhotoSourceSheet,
              ),

              // ── Saved photo templates grid ──────────────────────────────
              templatesAsync.when(
                data: (templates) => templates.isEmpty
                    ? const SizedBox.shrink()
                    : _PhotoTemplatesStrip(
                        templates: templates,
                        onTap: _applyTemplate,
                        onDelete: _deleteTemplate,
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // ── Filter bar ──────────────────────────────────────────────
              _FilterBar(
                current: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),

              // ── Design grid (shrinkWrap inside the shared scroll) ───────
              _DesignGrid(
                designs: _filtered(ent),
                entitlements: ent,
                onTap: (d) => _onDesignTap(d, ent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── "Add photo" banner ────────────────────────────────────────────────────────

class _AddPhotoTile extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _AddPhotoTile({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.primary.withAlpha(80),
              width: 1.5,
            ),
            gradient: LinearGradient(
              colors: [
                cs.primaryContainer.withAlpha(60),
                cs.secondaryContainer.withAlpha(60),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: cs.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kendi Fotoğrafını Ekle',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Galerinden veya kamerandan seç → şablon olarak kaydet',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Saved photo templates grid ────────────────────────────────────────────────

class _PhotoTemplatesStrip extends StatelessWidget {
  final List<CustomPhotoTemplate> templates;
  final void Function(CustomPhotoTemplate) onTap;
  final void Function(CustomPhotoTemplate) onDelete;

  const _PhotoTemplatesStrip({
    required this.templates,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            'Fotoğraflarım',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // 2-column grid, same aspect ratio as the design tiles.
        // shrinkWrap + NeverScrollableScrollPhysics so the outer Column
        // owns the scroll — the design grid below still scrolls independently.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 85.6 / 53.98,
          ),
          itemCount: templates.length,
          itemBuilder: (_, i) => _PhotoTemplateTile(
            template: templates[i],
            onTap: () => onTap(templates[i]),
            onDelete: () => onDelete(templates[i]),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Single photo template tile ────────────────────────────────────────────────

class _PhotoTemplateTile extends StatelessWidget {
  final CustomPhotoTemplate template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PhotoTemplateTile({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        // Width & height come from the parent GridView; no explicit sizing needed.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo with the saved pan/zoom transform applied.
              Transform(
                transform: Matrix4.identity()
                  ..translate(template.offsetX, template.offsetY)
                  ..scale(template.scale),
                alignment: Alignment.center,
                child: Image.file(
                  File(template.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: cs.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: cs.outline,
                    ),
                  ),
                ),
              ),

              // Subtle delete hint — "long press to delete".
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _DesignFilter current;
  final ValueChanged<_DesignFilter> onChanged;
  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<_DesignFilter>(
        segments: const [
          ButtonSegment(value: _DesignFilter.all, label: Text('Tümü')),
          ButtonSegment(value: _DesignFilter.free, label: Text('Ücretsiz')),
          ButtonSegment(value: _DesignFilter.owned, label: Text('Paketlerim')),
        ],
        selected: {current},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

// ── Design grid ───────────────────────────────────────────────────────────────

class _DesignGrid extends StatelessWidget {
  final List<CoverDesign> designs;
  final EntitlementsModel entitlements;
  final ValueChanged<CoverDesign> onTap;

  const _DesignGrid({
    required this.designs,
    required this.entitlements,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (designs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Bu kategoride tasarım yok',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 85.6 / 53.98,
      ),
      itemCount: designs.length,
      itemBuilder: (context, i) => _DesignTile(
        design: designs[i],
        isOwned: entitlements.hasDesign(designs[i]),
        onTap: () => onTap(designs[i]),
      ),
    );
  }
}

// ── Design tile ───────────────────────────────────────────────────────────────

class _DesignTile extends StatelessWidget {
  final CoverDesign design;
  final bool isOwned;
  final VoidCallback onTap;

  const _DesignTile({
    required this.design,
    required this.isOwned,
    required this.onTap,
  });

  List<Color> get _colors => design.gradientColors.map(_hexToColor).toList();

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final decoration = _colors.length == 1
        ? BoxDecoration(
            color: _colors.first,
            borderRadius: BorderRadius.circular(16),
          )
        : BoxDecoration(
            gradient: LinearGradient(
              colors: _colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          );

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: decoration),

            // ── Doodle pattern overlay ───────────────────────────────────
            if (design.patternType != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: DoodlePainter(design.patternType!),
                ),
              ),

            Positioned(
              right: -16,
              top: -16,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: -22,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(15),
                ),
              ),
            ),

            // Mini EMV chip
            Positioned(
              left: 10,
              top: 0,
              bottom: 28,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD4A843),
                        Color(0xFFF5C842),
                        Color(0xFFD4A843),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFFBF9000).withAlpha(178),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            // Name scrim
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withAlpha(153), Colors.transparent],
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text(
                  design.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
              ),
            ),

            if (design.isPremium && !isOwned)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: Colors.white, size: 13),
                ),
              ),

            if (design.isPremium && isOwned)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
