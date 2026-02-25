import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../auth/domain/auth_repository.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage:
                        user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: theme.colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'User',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(
                      'Signed in with ${user?.provider ?? "unknown"}',
                      style: theme.textTheme.labelSmall,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () => _confirmLogout(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete Account',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () => _confirmDeleteAccount(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).logout();
              // Router redirect will navigate to auth gate
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authRepositoryProvider).deleteAccount();
              } on AuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
