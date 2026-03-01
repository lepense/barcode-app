import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/cards_provider.dart';
import '../../../core/services/ai_card_service.dart';
import '../../../core/services/barcode_lookup_service.dart';
import '../domain/card_model.dart';
import 'share_card_sheet.dart';

// ── Internal scan result ─────────────────────────────────────────────────────

class _ScanResult {
  final String value;
  final BarcodeFormat format;
  const _ScanResult(this.value, this.format);
}

// ── BarcodeFormat → our type string ─────────────────────────────────────────

String _mapFormat(BarcodeFormat format) => switch (format) {
      BarcodeFormat.qrCode => 'QR',
      BarcodeFormat.code128 => 'CODE128',
      BarcodeFormat.code39 => 'CODE39',
      BarcodeFormat.ean13 => 'EAN13',
      BarcodeFormat.ean8 => 'EAN8',
      BarcodeFormat.upcA => 'UPC_A',
      BarcodeFormat.upcE => 'UPC_E',
      BarcodeFormat.pdf417 => 'PDF417',
      BarcodeFormat.aztec => 'AZTEC',
      BarcodeFormat.dataMatrix => 'DATA_MATRIX',
      _ => 'CODE128',
    };

// ── Screen ───────────────────────────────────────────────────────────────────

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
  bool _isLookingUp = false;
  bool _isAiScanning = false;
  bool _showScanSuccess = false;

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

  // ── Scanner ────────────────────────────────────────────────────────────────

  Future<void> _openScanner() async {
    final scan = await Navigator.of(context).push<_ScanResult>(
      MaterialPageRoute(builder: (_) => const _BarcodeScannerSheet()),
    );
    if (scan == null || !mounted) return;

    // ── Check if this is a Barcode Wallet share QR ──────────────────────────
    final shared = ShareCardSheet.tryDecodeCard(scan.value);
    if (shared != null && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kart İçe Aktar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bu QR kod bir Barcode Wallet kartı içeriyor:'),
              const SizedBox(height: 12),
              Text('Mağaza: ${shared.merchantName}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Barkod: ${shared.barcodeValue}'),
              Text('Tür: ${shared.barcodeType}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ekle'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        setState(() {
          _merchantController.text = shared.merchantName;
          _barcodeController.text = shared.barcodeValue;
          _selectedBarcodeType = shared.barcodeType;
          _showScanSuccess = true;
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _showScanSuccess = false);
        });
      }
      return; // Do not run normal barcode lookup
    }

    final type = _mapFormat(scan.format);

    // Auto-fill barcode type and value immediately + show success anim
    setState(() {
      _selectedBarcodeType = type;
      _barcodeController.text = scan.value;
      _isLookingUp = true;
      _showScanSuccess = true;
    });
    // Hide success animation after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showScanSuccess = false);
    });

    // Try to resolve merchant name in the background
    final name = await BarcodeLookupService.lookupName(scan.value, type);
    if (!mounted) return;

    setState(() => _isLookingUp = false);

    if (name != null && name.isNotEmpty) {
      _merchantController.text = name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İsim otomatik tespit edildi: $name'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // If name was not found: merchant field stays empty → user types it
  }

  // ── AI Scan ────────────────────────────────────────────────────────────────

  Future<void> _aiScan() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 1200,
    );
    if (image == null || !mounted) return;

    setState(() => _isAiScanning = true);
    try {
      final result = await AiCardService.recognizeCard(image);
      if (!mounted) return;

      if (!result.hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kart bilgisi tanınamadı, lütfen manuel girin'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        if (result.merchantName?.isNotEmpty ?? false) {
          _merchantController.text = result.merchantName!;
        }
        if (result.barcodeValue?.isNotEmpty ?? false) {
          _barcodeController.text = result.barcodeValue!;
        }
        if (result.barcodeType?.isNotEmpty ?? false) {
          _selectedBarcodeType = result.barcodeType!;
        }
        _showScanSuccess = true;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showScanSuccess = false);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.merchantName?.isNotEmpty ?? false
                  ? 'AI ile tespit edildi: ${result.merchantName}'
                  : 'AI tarama tamamlandı',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI tarama hatası: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAiScanning = false);
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

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
          SnackBar(content: Text('Kart kaydedilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kart Ekle'),
        actions: [
          if (_isAiScanning)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome_outlined),
              tooltip: 'Kartı AI ile tara',
              onPressed: _aiScan,
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Merchant name (auto-filled after scan) ──────────────────
                TextFormField(
                  controller: _merchantController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Mağaza / Kart Adı',
                    prefixIcon: const Icon(Icons.store),
                    suffixIcon: _isLookingUp
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    helperText: _isLookingUp ? 'İsim aranıyor…' : null,
                  ),
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : 'Mağaza adı girin',
                ),

                const SizedBox(height: 16),

                // ── Barcode type (auto-set from scan format) ────────────────
                // key: ValueKey forces widget recreation when type changes
                // so the dropdown always reflects the auto-detected format.
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedBarcodeType),
                  value: _selectedBarcodeType,
                  decoration: const InputDecoration(
                    labelText: 'Barkod Türü',
                    prefixIcon: Icon(Icons.qr_code),
                    helperText: 'Tarama yapılınca otomatik seçilir',
                  ),
                  items: _barcodeTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedBarcodeType = v);
                  },
                ),

                const SizedBox(height: 16),

                // ── Barcode value + camera button ───────────────────────────
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barkod Değeri',
                    prefixIcon: const Icon(Icons.dialpad),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      tooltip: 'Barkodu tara',
                      onPressed: _isLookingUp ? null : _openScanner,
                    ),
                  ),
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : 'Barkod değeri girin',
                ),

                const SizedBox(height: 12),

                // ── Hint about auto-scan ────────────────────────────────────
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kamerayı açıp barkodu tarayınca tür ve isim otomatik dolar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                FilledButton.icon(
                  onPressed: (_isSaving || _isLookingUp || _isAiScanning) ? null : _saveCard,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Kartı Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),

          // ── Scan success overlay ─────────────────────────────────────────
          if (_showScanSuccess)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Lottie.asset(
                    LottieAssets.scanSuccess,
                    width: 160,
                    height: 160,
                    repeat: false,
                    frameRate: FrameRate.max,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Full-screen barcode scanner ──────────────────────────────────────────────

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
    final format = barcode?.format;
    // Ignore unknown / empty scans
    if (value == null ||
        value.isEmpty ||
        format == null ||
        format == BarcodeFormat.unknown) {
      return;
    }

    _detected = true;
    Navigator.of(context).pop(_ScanResult(value, format));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkodu Tara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Flaş',
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

          // Scanning frame overlay
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

          // Corner accents
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(painter: _CornerPainter(context)),
            ),
          ),

          // Instruction text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Barkodu çerçeve içine hizalayın\nTür ve isim otomatik algılanacak',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 6)],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Corner accent painter ────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  final BuildContext context;
  _CornerPainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    const r = 12.0;

    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(
          Offset(x + dx * r, y), Offset(x + dx * (r + len), y), paint);
      canvas.drawLine(
          Offset(x, y + dy * r), Offset(x, y + dy * (r + len)), paint);
    }

    corner(0, 0, 1, 1);
    corner(size.width, 0, -1, 1);
    corner(0, size.height, 1, -1);
    corner(size.width, size.height, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
