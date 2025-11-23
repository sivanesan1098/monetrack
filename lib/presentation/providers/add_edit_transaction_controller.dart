import 'package:monetrack/domain/entities/transaction.dart';
import 'package:monetrack/presentation/providers/repository_providers.dart';
import 'package:monetrack/presentation/providers/transaction_list_controller.dart';
import 'package:monetrack/presentation/providers/reports_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'add_edit_transaction_controller.g.dart';

@riverpod
class AddEditTransactionController extends _$AddEditTransactionController {
  @override
  FutureOr<void> build() {}

  Future<void> addTransaction({
    required double amount,
    required String type,
    required String payee,
    required DateTime date,
    String? categoryId,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      final transaction = TransactionEntity(
        id: const Uuid().v4(),
        amount: amount,
        currency: 'INR',
        type: type,
        date: date,
        payee: payee,
        categoryId: categoryId,
        notes: notes,
        source: 'manual',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await repository.addTransaction(transaction);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          ref.invalidate(transactionListControllerProvider);
          ref.invalidate(reportsControllerProvider);
        },
      );
    });
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required String type,
    required String payee,
    required DateTime date,
    String? categoryId,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(transactionRepositoryProvider);
      final existingResult = await repository.getTransactionById(id);
      
      await existingResult.fold(
        (failure) => throw Exception(failure.message),
        (existing) async {
          if (existing == null) throw Exception('Transaction not found');
          
          final updated = TransactionEntity(
            id: id,
            amount: amount,
            currency: existing.currency,
            type: type,
            date: date,
            payee: payee,
            categoryId: categoryId,
            notes: notes,
            source: existing.source,
            rawText: existing.rawText,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
          );
          
          final result = await repository.updateTransaction(updated);
          return result.fold(
            (failure) => throw Exception(failure.message),
            (_) {
              ref.invalidate(transactionListControllerProvider);
              ref.invalidate(reportsControllerProvider);
            },
          );
        },
      );
    });
  }
  
  Future<TransactionEntity?> getTransaction(String id) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.getTransactionById(id);
    return result.fold((l) => null, (r) => r);
  }
}
