import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/iap_provider.dart';
import '../../../core/providers/sync_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final isSyncing = syncState.status == SyncStatus.syncing;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Account ─────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account'),
            subtitle: const Text('Profile, login, delete account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/account'),
          ),
          const Divider(),

          // ── Default Design ───────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Default Design'),
            subtitle: const Text('Choose default card cover'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/designs'),
          ),
          const Divider(),

          // ── Cloud Sync ───────────────────────────────────────────────────
          ListTile(
            leading: isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    syncState.status == SyncStatus.error
                        ? Icons.sync_problem_outlined
                        : Icons.sync,
                    color: syncState.status == SyncStatus.error
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
            title: const Text('Cloud Sync'),
            subtitle: Text(
              syncState.message ??
                  (syncState.status == SyncStatus.error
                      ? 'Sync failed'
                      : 'Sync cards to the cloud'),
            ),
            trailing: isSyncing
                ? null
                : TextButton(
                    onPressed: () => ref.read(syncProvider.notifier).sync(),
                    child: const Text('Sync now'),
                  ),
          ),
          const Divider(),

          // ── Restore Purchases ────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Purchases'),
            subtitle: const Text('Recover your premium content'),
            onTap: () async {
              final iapAsync = ref.read(iapServiceProvider);
              final svc = iapAsync.valueOrNull;
              if (svc == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Store not available')),
                );
                return;
              }
              try {
                await svc.restore();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchases restored')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e')),
                  );
                }
              }
            },
          ),
          const Divider(),

          // ── About ────────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Barcode App',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026',
              );
            },
          ),
        ],
      ),
    );
  }
}
