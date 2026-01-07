import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/language.dart';
import '../providers/locale_provider.dart';

import 'counter_screen.dart';
import 'user_screen.dart';
import 'async_data_screen.dart';
import 'todo_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(localeProvider.notifier).currentLanguage;
    final supportedLanguages = ref.watch(supportedLanguagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<Language>(
            icon: const Icon(Icons.language),
            tooltip: 'Language / 語言',
            onSelected: (Language language) {
              ref.read(localeProvider.notifier).setLanguage(language);
            },
            itemBuilder: (BuildContext context) {
              return supportedLanguages.map((Language language) {
                final isSelected = language == currentLanguage;
                return PopupMenuItem<Language>(
                  value: language,
                  child: Row(
                    children: [
                      if (isSelected)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              language.nativeName,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            if (language.nativeName != language.englishName)
                              Text(
                                language.englishName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildExampleCard(
            context,
            title: l10n.counterExampleTitle,
            description: l10n.counterExampleDesc,
            icon: Icons.add_circle_outline,
            color: Colors.blue,
            onTap: () => _navigateTo(context, const CounterScreen()),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: l10n.userExampleTitle,
            description: l10n.userExampleDesc,
            icon: Icons.person_outline,
            color: Colors.green,
            onTap: () => _navigateTo(context, const UserScreen()),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: l10n.asyncExampleTitle,
            description: l10n.asyncExampleDesc,
            icon: Icons.cloud_download_outlined,
            color: Colors.orange,
            onTap: () => _navigateTo(context, const AsyncDataScreen()),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: l10n.todoExampleTitle,
            description: l10n.todoExampleDesc,
            icon: Icons.checklist_outlined,
            color: Colors.purple,
            onTap: () => _navigateTo(context, const TodoScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.usageInstructions,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInstruction(l10n.instruction1),
                _buildInstruction(l10n.instruction2),
                _buildInstruction(l10n.instruction3),
                _buildInstruction(l10n.instruction4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }
}
