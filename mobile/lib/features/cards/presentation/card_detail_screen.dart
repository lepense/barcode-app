import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/providers/cards_provider.dart';
import '../../designs/domain/design_catalog.dart';
import '../../designs/domain/design_model.dart';
import '../domain/card_model.dart';
import 'card_cover_widget.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

/// Streams the single card with [id] — rebuilds automatically on any DB change.
final _cardDetailProvider =
    StreamProvider.family<LoyaltyCard, int>((ref, id) {
  return ref.watch(cardRepositoryProvider).watchCardById(id);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class CardDetailScreen extends ConsumerWidget {
  final String cardId;

  const CardDetailScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(cardId);
    if (id == null) {
      return const Scaffold(body: Center(child: Text('Invalid card ID')));
    }

    return ref.watch(_cardDetailProvider(id)).when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Card Detail')),
            body: Center(child: Text('Error: $e')),
          ),
          data: (card) => _CardDetailView(card: card),
        );
  }
}

// ── Detail view ───────────────────────────────────────────────────────────────

class _CardDetailView extends ConsumerWidget {
  final LoyaltyCard card;
  const _CardDetailView({required this.card});

  Barcode _resolveBarcode(String type) => switch (type) {
        'QR' => Barcode.qrCode(),
        'CODE128' => Barcode.code128(),
        'CODE39' => Barcode.code39(),
        'EAN13' => Barcode.ean13(),
        'EAN8' => Barcode.ean8(),
        'UPC_A' => Barcode.upcA(),
        'UPC_E' => Barcode.upcE(),
        'PDF417' => Barcode.pdf417(),
        'AZTEC' => Barcode.aztec(),
        'DATA_MATRIX' => Barcode.dataMatrix(),
        _ => Barcode.qrCode(),
      };

  Future<void> _pickDesign(BuildContext context, WidgetRef ref) async {
    final designId = await context.push<String>(
      '/designs',
      extra: card.id.toString(),
    );
    // If a design was selected via the grid (pop returns its id), apply it.
    // Template selection applies the card directly inside DesignBrowserScreen
    // and pops without a value — the StreamProvider updates automatically.
    if (designId != null && card.id != null) {
      await ref.read(cardRepositoryProvider).updateCard(
            card.copyWith(coverDesignId: designId),
          );
    }
  }

  Future<void> _removeDesign(WidgetRef ref) async {
    if (card.id == null) return;
    await ref.read(cardRepositoryProvider).updateCard(
          card.copyWith(coverDesignId: null),
        );
  }

  // ── Custom photo ──────────────────────────────────────────────────────────

  Future<void> _pickPhoto(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null || !context.mounted) return;

    // Copy the picked image to the app's documents directory so the card
    // continues to display even if the original gallery photo is deleted.
    final docsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(docsDir.path, 'card_covers'));
    if (!coversDir.existsSync()) coversDir.createSync(recursive: true);

    final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final fileName = 'card_${card.id ?? 'new'}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(coversDir.path, fileName);

    await File(picked.path).copy(destPath);

    if (!context.mounted) return;
    await ref.read(cardRepositoryProvider).updateCard(
          card.copyWith(
            customCoverImagePath: destPath,
            coverDesignId: null, // clear any gradient design
          ),
        );
    // StreamProvider updates automatically — no invalidate needed.
  }

  Future<void> _removePhoto(WidgetRef ref) async {
    if (card.id == null) return;
    // Delete the file from disk if it lives in our covers dir.
    if (card.customCoverImagePath != null) {
      final f = File(card.customCoverImagePath!);
      if (f.existsSync()) f.deleteSync();
    }
    await ref.read(cardRepositoryProvider).updateCard(
          card.copyWith(customCoverImagePath: null),
        );
    // StreamProvider updates automatically — no invalidate needed.
  }

  void _showCoverSheet(BuildContext context, WidgetRef ref) {
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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(context, ref, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Fotoğraf çek'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(context, ref, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Hazır tema seç'),
              onTap: () {
                Navigator.pop(ctx);
                _pickDesign(context, ref);
              },
            ),
            if (card.customCoverImagePath != null ||
                card.coverDesignId != null) ...[
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text(
                  card.customCoverImagePath != null
                      ? 'Fotoğrafı kaldır'
                      : 'Temayı kaldır',
                  style:
                      TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (card.customCoverImagePath != null) {
                    _removePhoto(ref);
                  } else {
                    _removeDesign(ref);
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text(
          'Remove "${card.merchantName}" from your wallet? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && card.id != null) {
      await ref.read(cardRepositoryProvider).deleteCard(card.id!);
      if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final design = card.coverDesignId != null
        ? DesignCatalog.findById(card.coverDesignId!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(card.merchantName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete card',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Full credit-card cover ─────────────────────────────────────
            LoyaltyCardCover(
              card: card,
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            ),

            // ── Cover customization row ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Active cover label
                  if (card.customCoverImagePath != null) ...[
                    const Icon(Icons.image_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Özel fotoğraf',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else if (design != null) ...[
                    _DesignChip(design: design),
                    const Spacer(),
                  ] else
                    Expanded(
                      child: Text(
                        'Kapak yok',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                  // Action button — always visible
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Kapağı düzenle'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    onPressed: () => _showCoverSheet(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Barcode card ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      BarcodeWidget(
                        barcode: _resolveBarcode(card.barcodeType),
                        data: card.barcodeValue,
                        width: double.infinity,
                        height: 160,
                        color: theme.colorScheme.onSurface,
                        backgroundColor: theme.colorScheme.surface,
                        errorBuilder: (context, error) => Center(
                          child: Text(
                            'Cannot render barcode: $error',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        card.barcodeValue,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Card info ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.merchantName, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${card.barcodeType}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        card.isSynced
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        card.isSynced ? 'Synced' : 'Not synced',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _DesignChip ───────────────────────────────────────────────────────────────

/// Small pill showing the active design name with its first gradient colour.
class _DesignChip extends StatelessWidget {
  final CoverDesign design;
  const _DesignChip({required this.design});

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(design.gradientColors.first);
    return Chip(
      avatar: CircleAvatar(backgroundColor: color),
      label: Text(design.name, style: Theme.of(context).textTheme.labelSmall),
      visualDensity: VisualDensity.compact,
    );
  }
}
