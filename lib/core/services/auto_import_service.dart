import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetrack/core/utils/message_parser.dart';
import 'package:monetrack/presentation/providers/settings_controller.dart';
import 'package:monetrack/domain/entities/transaction.dart';
import 'package:monetrack/presentation/providers/repository_providers.dart';
import 'package:monetrack/presentation/providers/transaction_list_controller.dart';
import 'package:monetrack/presentation/providers/reports_controller.dart';
import 'package:uuid/uuid.dart';

// Global instance initialized in main
late AutoImportService globalAutoImportService;

final autoImportServiceProvider = Provider<AutoImportService>((ref) {
  return globalAutoImportService;
});

class AutoImportService {
  static const platform = MethodChannel('com.monetrack.monetrack/auto_import');
  final ProviderContainer _container;
  final MessageParser _parser = MessageParser();

  AutoImportService(this._container) {
    _init();
  }

  void _init() {
    platform.setMethodCallHandler(_handleMethodCall);
    _parser.loadRules();
  }

  Future<void> openNotificationSettings() async {
    try {
      await platform.invokeMethod('openNotificationSettings');
    } on PlatformException catch (e) {
      print("Failed to open settings: '${e.message}'.");
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onNotificationReceived') {
      final dynamic data = call.arguments;
      if (data is Map) {
        await _processNotification(
          data['package'] as String?,
          data['title'] as String?,
          data['text'] as String?,
        );
      }
    }
  }

  Future<void> simulateTransaction(String text) async {
    await _processNotification('com.test.app', 'Test Notification', text);
  }

  Future<void> _processNotification(String? packageName, String? title, String? text) async {
    if (text == null) return;

    // Check if auto-add is enabled
    final settings = await _container.read(settingsControllerProvider.future);
    if (settings['autoAdd'] != true) return;

    // Parse message
    final transaction = _parser.parse(text);
    
    if (transaction != null) {
      // Add transaction using repository directly
      try {
        final repository = _container.read(transactionRepositoryProvider);
        final newTransaction = TransactionEntity(
          id: const Uuid().v4(),
          amount: transaction.amount,
          currency: 'INR',
          type: transaction.type,
          date: transaction.date ?? DateTime.now(),
          payee: transaction.payee,
          notes: 'Auto-imported from $packageName',
          source: 'auto',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = await repository.addTransaction(newTransaction);
        
        result.fold(
          (failure) => print('Failed to add transaction: ${failure.message}'),
          (_) {
            print('Auto-imported transaction: ${transaction.amount} to ${transaction.payee}');
            // Invalidate providers to refresh UI
            _container.invalidate(transactionListControllerProvider);
            _container.invalidate(reportsControllerProvider);
          },
        );
      } catch (e) {
        print('Failed to auto-import transaction: $e');
      }
    }
  }
}
