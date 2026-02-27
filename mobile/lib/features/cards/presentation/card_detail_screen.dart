import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/cards_provider.dart';
import '../domain/card_model.dart';

/// Fetches a single card by its local DB id.
final _cardDetailProvider =
    FutureProvider.family<LoyaltyCard, int>((ref, id) async {
  return ref.watch(cardRepositoryProvider).getCardById(id);
});

class CardDetailScreen extends ConsumerWidget {
  final String cardId;

  const CardDetailScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(cardId);
    if (id == null) {
      return const Scaffold(body: Center(child: Text('Invalid card ID')));
    }

    final cardAsync = ref.watch(_cardDetailProvider(id));

    return cardAsync.when(
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

class _CardDetailView extends ConsumerWidget {
  final LoyaltyCard card;
  const _CardDetailView({required this.card});

  Barcode _resolveBarcode(String type) {
    switch (type) {
      case 'QR':
        return Barcode.qrCode();
      case 'CODE128':
        return Barcode.code128();
      case 'CODE39':
        return Barcode.code39();
      case 'EAN13':
        return Barcode.ean13();
      case 'EAN8':
        return Barcode.ean8();
      case 'UPC_A':
        return Barcode.upcA();
      case 'UPC_E':
        return Barcode.upcE();
      case 'PDF417':
        return Barcode.pdf417();
      case 'AZTEC':
        return Barcode.aztec();
      case 'DATA_MATRIX':
        return Barcode.dataMatrix();
      default:
        return Barcode.qrCode();
    }
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BarcodeWidget(
                  barcode: _resolveBarcode(card.barcodeType),
                  data: card.barcodeValue,
                  width: double.infinity,
                  height: 180,
                  color: theme.colorScheme.onSurface,
                  backgroundColor: theme.colorScheme.surface,
                  errorBuilder: (context, error) => Center(
                    child: Text(
                      'Cannot render barcode: $error',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(card.merchantName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Type: ${card.barcodeType}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              card.barcodeValue,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
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
          ],
        ),
      ),
    );
  }
}
