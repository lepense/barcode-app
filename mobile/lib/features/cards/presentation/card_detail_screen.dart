import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/cards_provider.dart';
import '../../designs/domain/design_catalog.dart';
import '../../designs/domain/design_model.dart';
import '../domain/card_model.dart';
import 'card_cover_widget.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _cardDetailProvider =
    FutureProvider.family<LoyaltyCard, int>((ref, id) async {
  return ref.watch(cardRepositoryProvider).getCardById(id);
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
    if (designId != null && card.id != null) {
      await ref.read(cardRepositoryProvider).updateCard(
            card.copyWith(coverDesignId: designId),
          );
      ref.invalidate(_cardDetailProvider(card.id!));
    }
  }

  Future<void> _removeDesign(WidgetRef ref) async {
    if (card.id == null) return;
    await ref.read(cardRepositoryProvider).updateCard(
          card.copyWith(coverDesignId: null),
        );
    ref.invalidate(_cardDetailProvider(card.id!));
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

            // ── Design picker ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (design != null) ...[
                    _DesignChip(design: design),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _removeDesign(ref),
                      child: const Text('Remove'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _pickDesign(context, ref),
                      child: const Text('Change'),
                    ),
                  ] else
                    TextButton.icon(
                      icon: const Icon(Icons.palette_outlined),
                      label: const Text('Choose Design'),
                      onPressed: () => _pickDesign(context, ref),
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
