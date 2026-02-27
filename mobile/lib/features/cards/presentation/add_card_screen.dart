import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/providers/cards_provider.dart';
import '../domain/card_model.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _barcodeController = TextEditingController();
  String _selectedBarcodeType = 'QR';
  bool _isSaving = false;

  static const _barcodeTypes = [
    'QR',
    'CODE128',
    'CODE39',
    'EAN13',
    'EAN8',
    'UPC_A',
    'UPC_E',
    'PDF417',
    'AZTEC',
    'DATA_MATRIX',
  ];

  @override
  void dispose() {
    _merchantController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _BarcodeScannerSheet()),
    );
    if (result != null) {
      _barcodeController.text = result;
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final card = LoyaltyCard(
        merchantName: _merchantController.text.trim(),
        barcodeType: _selectedBarcodeType,
        barcodeValue: _barcodeController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(cardRepositoryProvider).addCard(card);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save card: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Card')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _merchantController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Merchant Name',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : 'Enter merchant name',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBarcodeType,
                  decoration: const InputDecoration(
                    labelText: 'Barcode Type',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  items: _barcodeTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedBarcodeType = v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode Value',
                    prefixIcon: const Icon(Icons.dialpad),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      tooltip: 'Scan barcode',
                      onPressed: _openScanner,
                    ),
                  ),
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : 'Enter barcode value',
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isSaving ? null : _saveCard,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Card'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen barcode scanner.
class _BarcodeScannerSheet extends StatefulWidget {
  const _BarcodeScannerSheet();

  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _detected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value != null && value.isNotEmpty) {
      _detected = true;
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'Align the barcode inside the frame',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 4)],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
