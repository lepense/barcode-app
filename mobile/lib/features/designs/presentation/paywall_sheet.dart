import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/providers/iap_provider.dart';
import '../../iap/data/iap_service.dart';
import '../../iap/domain/iap_skus.dart';
import '../domain/design_model.dart';

/// Bottom sheet that presents the purchase options for a locked [design].
class PaywallSheet extends ConsumerStatefulWidget {
  final CoverDesign design;

  const PaywallSheet({super.key, required this.design});

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  StreamSubscription<IapEvent>? _eventSub;
  bool _isBuying = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    // Subscribe to IAP events once the service is ready.
    ref.listenManual(iapServiceProvider, (_, next) {
      next.whenData((svc) {
        _eventSub?.cancel();
        _eventSub = svc.events.listen(_onIapEvent);
      });
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _onIapEvent(IapEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case IapEventType.purchased:
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase successful!')),
        );
      case IapEventType.error:
        setState(() {
          _isBuying = false;
          _isRestoring = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event.message ?? 'Purchase failed')),
        );
      case IapEventType.canceled:
        setState(() {
          _isBuying = false;
          _isRestoring = false;
        });
      default:
        break;
    }
  }

  Future<void> _buy(IapService svc, String sku) async {
    final product = svc.products[sku];
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not available in this region')),
      );
      return;
    }
    setState(() => _isBuying = true);
    await svc.buy(product);
  }

  Future<void> _restore(IapService svc) async {
    setState(() => _isRestoring = true);
    await svc.restore();
    if (mounted) setState(() => _isRestoring = false);
  }

  @override
  Widget build(BuildContext context) {
    final iapAsync = ref.watch(iapServiceProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Design preview tile
          _DesignPreview(design: widget.design),
          const SizedBox(height: 24),

          // Title
          Text(
            'Unlock ${widget.design.name}',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          iapAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              'Store unavailable: $e',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            data: (svc) => _PurchaseOptions(
              packId: widget.design.packId,
              products: svc.products,
              isBuying: _isBuying,
              isRestoring: _isRestoring,
              onBuyPack: () => _buy(svc, widget.design.packId!),
              onBuyPro: () => _buy(svc, IapSkus.proLifetime),
              onRestore: () => _restore(svc),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignPreview extends StatelessWidget {
  final CoverDesign design;
  const _DesignPreview({required this.design});

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colors = design.gradientColors.map(_hexToColor).toList();
    final decoration = colors.length == 1
        ? BoxDecoration(color: colors.first, borderRadius: BorderRadius.circular(16))
        : BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          );

    return Center(
      child: Container(
        width: 160,
        height: 100,
        decoration: decoration,
      ),
    );
  }
}

class _PurchaseOptions extends StatelessWidget {
  final String? packId;
  final Map<String, ProductDetails> products;
  final bool isBuying;
  final bool isRestoring;
  final VoidCallback onBuyPack;
  final VoidCallback onBuyPro;
  final VoidCallback onRestore;

  const _PurchaseOptions({
    required this.packId,
    required this.products,
    required this.isBuying,
    required this.isRestoring,
    required this.onBuyPack,
    required this.onBuyPro,
    required this.onRestore,
  });

  String _price(String sku) {
    final p = products[sku];
    return p != null ? p.price : '–';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pack option
        if (packId != null) ...[
          _OptionCard(
            title: IapSkus.packDisplayName(packId!),
            subtitle: 'Unlock all designs in this pack',
            price: _price(packId!),
            isPrimary: true,
            isLoading: isBuying,
            onTap: onBuyPack,
          ),
          const SizedBox(height: 12),
        ],

        // Pro lifetime
        _OptionCard(
          title: 'Pro – All Designs Forever',
          subtitle: 'Every pack, past and future',
          price: _price(IapSkus.proLifetime),
          isPrimary: packId == null,
          isLoading: isBuying,
          onTap: onBuyPro,
        ),
        const SizedBox(height: 24),

        // Restore
        Center(
          child: TextButton(
            onPressed: isRestoring ? null : onRestore,
            child: isRestoring
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Restore Purchases',
                    style: theme.textTheme.bodySmall,
                  ),
          ),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isPrimary,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isPrimary
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final fg = isPrimary
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: fg.withOpacity(0.7))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isLoading)
              SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: fg),
              )
            else
              Text(price,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: fg, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

