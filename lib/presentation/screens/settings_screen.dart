import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetrack/core/utils/csv_exporter.dart';
import 'package:monetrack/presentation/providers/repository_providers.dart';
import 'package:monetrack/presentation/providers/settings_controller.dart';
import 'package:monetrack/presentation/providers/transaction_list_controller.dart';
import 'package:monetrack/presentation/providers/reports_controller.dart';
import 'package:monetrack/core/services/auto_import_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          final autoAdd = settings['autoAdd'] as bool;
          final currency = settings['currency'] as String;
          final themeMode = settings['themeMode'] as String;

          return ListView(
            children: [
              _buildSectionHeader(context, 'Preferences'),
              SwitchListTile(
                title: const Text('Auto-add Transactions'),
                subtitle: const Text('Automatically save parsed transactions'),
                value: autoAdd,
                onChanged: (value) {
                  ref.read(settingsControllerProvider.notifier).toggleAutoAdd(value);
                },
              ),
              if (autoAdd)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Grant Notification Permission'),
                    onPressed: () {
                      ref.read(autoImportServiceProvider).openNotificationSettings();
                    },
                  ),
                ),
              if (autoAdd)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Simulate Test Transaction'),
                    onPressed: () {
                      ref.read(autoImportServiceProvider).simulateTransaction(
                        'Rs. 150.00 spent at Starbucks on 22-11-2025.'
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test transaction simulated')),
                      );
                    },
                  ),
                ),
              ListTile(
                title: const Text('Currency'),
                subtitle: Text(currency),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showCurrencyDialog(context, ref, currency),
              ),
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(themeMode.toUpperCase()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showThemeDialog(context, ref, themeMode),
              ),
              
              _buildSectionHeader(context, 'Data Management'),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export to CSV'),
                subtitle: const Text('Save your transactions to a CSV file'),
                onTap: () async {
                  try {
                    final repo = ref.read(transactionRepositoryProvider);
                    final result = await repo.getTransactions();
                    result.fold(
                      (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message))),
                      (r) => CsvExporter.exportTransactions(r),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete All Data', style: TextStyle(color: Colors.red)),
                onTap: () => _showDeleteConfirmDialog(context, ref),
              ),
              
              _buildSectionHeader(context, 'About'),
              const ListTile(
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showCurrencyDialog(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Currency'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Currency Symbol/Code'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(settingsControllerProvider.notifier).setCurrency(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemeDialog(BuildContext context, WidgetRef ref, String current) async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Theme'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              ref.read(settingsControllerProvider.notifier).setThemeMode('system');
              Navigator.pop(context);
            },
            child: const Text('System'),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(settingsControllerProvider.notifier).setThemeMode('light');
              Navigator.pop(context);
            },
            child: const Text('Light'),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(settingsControllerProvider.notifier).setThemeMode('dark');
              Navigator.pop(context);
            },
            child: const Text('Dark'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text('This action cannot be undone. All transactions and categories will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final repo = ref.read(transactionRepositoryProvider);
              final result = await repo.deleteAllData();
              if (context.mounted) {
                result.fold(
                  (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message))),
                  (r) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data deleted')));
                    // Refresh providers if needed, though Riverpod might handle it if we invalidate
                    ref.invalidate(transactionListControllerProvider);
                    ref.invalidate(reportsControllerProvider);
                  },
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
