import 'package:monetrack/data/datasources/database_helper.dart';
import 'package:monetrack/data/repositories/category_repository_impl.dart';
import 'package:monetrack/data/repositories/transaction_repository_impl.dart';
import 'package:monetrack/domain/repositories/category_repository.dart';
import 'package:monetrack/domain/repositories/transaction_repository.dart';
import 'package:monetrack/core/services/sms_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
DatabaseHelper databaseHelper(DatabaseHelperRef ref) {
  return DatabaseHelper.instance;
}

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return CategoryRepositoryImpl(dbHelper);
}

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return TransactionRepositoryImpl(dbHelper);
}

@riverpod
SmsService smsService(SmsServiceRef ref) {
  return SmsService();
}
