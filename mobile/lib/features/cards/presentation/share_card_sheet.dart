import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/card_model.dart';

/// Payload version tag — bump if schema changes.
const _kShareVersion = '1';
const _kShareType    = 'bw_share';

class ShareCardSheet extends StatelessWidget {
  final LoyaltyCard card;

  const ShareCardSheet({super.key, required this.card});

  // ── Public helpers ─────────────────────────────────────────────────────────

  /// Encodes [card] into the shareable QR payload JSON string.
  static String encodeCard(LoyaltyCard card) => jsonEncode({
        'v': _kShareVersion,
        'type': _kShareType,
        'm': card.merchantName,
        'bv': card.barcodeValue,
        'bt': card.barcodeType,
      });

  /// Returns a [LoyaltyCard] stub (no id/dates) if [raw] is a valid share
  /// payload, or `null` otherwise.
  static LoyaltyCard? tryDecodeCard(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['type'] != _kShareType) return null;
      return LoyaltyCard(
        merchantName: (map['m'] as String?) ?? '',
        barcodeType: (map['bt'] as String?) ?? 'CODE128',
        barcodeValue: (map['bv'] as String?) ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = encodeCard(card);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Kartı Paylaş',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${card.merchantName} kartını arkadaşlarınla paylaş',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // QR code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BarcodeWidget(
                barcode: Barcode.qrCode(errorCorrectLevel: BarcodeQRCorrectionLevel.medium),
                data: payload,
                width: 220,
                height: 220,
                color: Colors.black,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Info chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoChip(
                  icon: Icons.store_outlined,
                  label: card.merchantName,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.qr_code_outlined,
                  label: card.barcodeType,
                  theme: theme,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Copy payload button (for debugging / manual transfer)
            OutlinedButton.icon(
              icon: const Icon(Icons.copy_outlined, size: 16),
              label: const Text('Kart numarasını kopyala'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: card.barcodeValue));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kart numarası kopyalandı')),
                );
              },
            ),

            const SizedBox(height: 12),

            Text(
              'Karşı taraf Barcode Wallet uygulamasını açıp\n'
              'barkod tarayıcısını bu QR koda tutmalı.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
