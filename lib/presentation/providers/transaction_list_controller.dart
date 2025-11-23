import 'package:monetrack/domain/entities/transaction.dart';
import 'package:monetrack/presentation/providers/repository_providers.dart';
import 'package:monetrack/presentation/providers/reports_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_list_controller.g.dart';

@riverpod
class TransactionListController extends _$TransactionListController {
  @override
  Future<List<TransactionEntity>> build() async {
    return _fetchTransactions();
  }

  Future<List<TransactionEntity>> _fetchTransactions() async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.getTransactions();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (transactions) => transactions,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTransactions());
  }
  
  Future<void> deleteTransaction(String id) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.deleteTransaction(id);
    result.fold(
      (failure) => null, // Handle error
      (_) {
        refresh();
        ref.invalidate(reportsControllerProvider);
      },
    );
  }
}
