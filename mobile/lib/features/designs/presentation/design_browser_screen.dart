import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/entitlements_provider.dart';
import '../../../core/providers/iap_provider.dart';
import '../domain/design_catalog.dart';
import '../domain/design_model.dart';
import '../../iap/domain/entitlements_model.dart';
import 'paywall_sheet.dart';

enum _DesignFilter { all, free, owned }

class DesignBrowserScreen extends ConsumerStatefulWidget {
  /// When non-null, selecting a design pops back with the design ID.
  final String? pickForCardId;

  const DesignBrowserScreen({super.key, this.pickForCardId});

  @override
  ConsumerState<DesignBrowserScreen> createState() =>
      _DesignBrowserScreenState();
}

class _DesignBrowserScreenState extends ConsumerState<DesignBrowserScreen> {
  _DesignFilter _filter = _DesignFilter.all;

  List<CoverDesign> _filtered(EntitlementsModel ent) {
    return switch (_filter) {
      _DesignFilter.all => DesignCatalog.all,
      _DesignFilter.free =>
        DesignCatalog.all.where((d) => !d.isPremium).toList(),
      _DesignFilter.owned =>
        DesignCatalog.all.where((d) => ent.hasDesign(d)).toList(),
    };
  }

  void _onDesignTap(CoverDesign design, EntitlementsModel ent) {
    if (ent.hasDesign(design)) {
      if (widget.pickForCardId != null) {
        context.pop(design.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${design.name}" selected')),
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

  @override
  Widget build(BuildContext context) {
    final entitlementsAsync = ref.watch(entitlementsProvider);

    // Pre-warm the IAP service in the background.
    ref.watch(iapServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pickForCardId != null ? 'Pick a Design' : 'Designs',
        ),
      ),
      body: entitlementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ent) => Column(
          children: [
            _FilterBar(
              current: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: _DesignGrid(
                designs: _filtered(ent),
                entitlements: ent,
                onTap: (d) => _onDesignTap(d, ent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          ButtonSegment(value: _DesignFilter.all, label: Text('All')),
          ButtonSegment(value: _DesignFilter.free, label: Text('Free')),
          ButtonSegment(value: _DesignFilter.owned, label: Text('My Pack')),
        ],
        selected: {current},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

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
      return Center(
        child: Text(
          'No designs here yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        // Standard credit-card ratio so previews match the real card shape
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

class _DesignTile extends StatelessWidget {
  final CoverDesign design;
  final bool isOwned;
  final VoidCallback onTap;

  const _DesignTile({
    required this.design,
    required this.isOwned,
    required this.onTap,
  });

  List<Color> get _colors =>
      design.gradientColors.map(_hexToColor).toList();

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
            // Gradient background
            DecoratedBox(decoration: decoration),

            // Decorative circles (mimics LoyaltyCardCover)
            Positioned(
              right: -16,
              top: -16,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
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
                  color: Colors.white.withOpacity(0.06),
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
                      colors: [Color(0xFFD4A843), Color(0xFFF5C842), Color(0xFFD4A843)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFFBF9000).withOpacity(0.7),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            // Name label with gradient scrim
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
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

            // Lock badge for locked premium designs
            if (design.isPremium && !isOwned)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),

            // Owned badge for unlocked premium
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
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
