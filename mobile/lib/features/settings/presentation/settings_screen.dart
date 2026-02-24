import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account'),
            subtitle: const Text('Profile, login, delete account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/account'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Default Design'),
            subtitle: const Text('Choose default card cover'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to default design picker
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Cloud Sync'),
            subtitle: const Text('Sync cards across devices'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Sync settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Purchases'),
            subtitle: const Text('Recover your premium content'),
            onTap: () {
              // TODO: Restore purchases
            },
          ),
          const Divider(),
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
