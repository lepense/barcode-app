import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/cards_provider.dart';
import '../../designs/domain/design_catalog.dart';
import '../domain/card_model.dart';

class CardListScreen extends ConsumerWidget {
  const CardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cards) => cards.isEmpty
            ? _EmptyState()
            : _CardList(cards: cards),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/add'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/designs');
            case 2:
              context.push('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.credit_card),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            label: 'Designs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No cards yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first loyalty card',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardList extends StatelessWidget {
  final List<LoyaltyCard> cards;
  const _CardList({required this.cards});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: cards.length,
      itemBuilder: (context, index) => _CardTile(card: cards[index]),
    );
  }
}

class _CardTile extends StatelessWidget {
  final LoyaltyCard card;
  const _CardTile({required this.card});

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy').format(card.updatedAt);
    final design = card.coverDesignId != null
        ? DesignCatalog.findById(card.coverDesignId!)
        : null;
    final colors = design?.gradientColors.map(_hexToColor).toList();

    Widget avatar;
    if (colors != null && colors.isNotEmpty) {
      avatar = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: colors.length == 1
              ? null
              : LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: colors.length == 1 ? colors.first : null,
        ),
        alignment: Alignment.center,
        child: Text(
          card.merchantName.isNotEmpty
              ? card.merchantName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else {
      avatar = CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          card.merchantName.isNotEmpty
              ? card.merchantName[0].toUpperCase()
              : '?',
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: avatar,
        title: Text(card.merchantName),
        subtitle: Text('${card.barcodeType} · $dateStr'),
        trailing: card.isSynced
            ? const Icon(Icons.cloud_done_outlined, size: 16)
            : const Icon(Icons.cloud_off_outlined, size: 16),
        onTap: () => context.push('/home/card/${card.id}'),
      ),
    );
  }
}
