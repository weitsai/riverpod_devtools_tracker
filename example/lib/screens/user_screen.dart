import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';

import '../providers/user_provider.dart';

class UserScreen extends ConsumerWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userDataProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userScreenTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isLoggedIn ? Icons.check_circle : Icons.cancel,
                          color: isLoggedIn ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isLoggedIn ? l10n.loggedIn : l10n.notLoggedIn,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (user != null) ...[
                      const Divider(height: 24),
                      _buildUserInfo(l10n.name, user.name),
                      const SizedBox(height: 8),
                      _buildUserInfo(l10n.age, '${user.age}'),
                      const SizedBox(height: 8),
                      _buildUserInfo(l10n.email, user.email),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!isLoggedIn) ...[
              ElevatedButton.icon(
                onPressed: () => _login(ref, context),
                icon: const Icon(Icons.login),
                label: Text(l10n.login),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _updateUserName(ref, context),
                icon: const Icon(Icons.edit),
                label: Text(l10n.changeName),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _incrementAge(ref),
                icon: const Icon(Icons.cake),
                label: Text(l10n.increaseAge),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _logout(ref),
                icon: const Icon(Icons.logout),
                label: Text(l10n.logout),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // These methods will trigger state changes and be tracked by DevTools
  void _login(WidgetRef ref, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.read(userDataProvider.notifier).login(
      User(
        name: l10n.defaultUserName,
        age: 25,
        email: 'user@example.com',
      ),
    );
  }

  void _logout(WidgetRef ref) {
    ref.read(userDataProvider.notifier).logout();
  }

  void _incrementAge(WidgetRef ref) {
    ref.read(userDataProvider.notifier).incrementAge();
  }

  void _updateUserName(WidgetRef ref, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.read(userDataProvider);
    if (currentUser == null) return;

    final controller = TextEditingController(text: currentUser.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.changeNameDialogTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.newName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(userDataProvider.notifier).updateName(controller.text);
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}
