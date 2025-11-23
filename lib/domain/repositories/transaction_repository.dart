import 'package:dartz/dartz.dart';
import 'package:monetrack/core/errors/failures.dart';
import 'package:monetrack/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
  });
  Future<Either<Failure, TransactionEntity?>> getTransactionById(String id);
  Future<Either<Failure, void>> addTransaction(TransactionEntity transaction);
  Future<Either<Failure, void>> updateTransaction(TransactionEntity transaction);
  Future<Either<Failure, void>> deleteTransaction(String id);
  Future<Either<Failure, void>> deleteAllData();
}
