import 'package:dartz/dartz.dart';
import 'package:monetrack/core/constants/db_constants.dart';
import 'package:monetrack/core/errors/failures.dart';
import 'package:monetrack/data/datasources/database_helper.dart';
import 'package:monetrack/data/models/transaction_model.dart';
import 'package:monetrack/domain/entities/transaction.dart';
import 'package:monetrack/domain/repositories/transaction_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseHelper _dbHelper;

  TransactionRepositoryImpl(this._dbHelper);

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
  }) async {
    try {
      final db = await _dbHelper.database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startDate != null) {
        whereClause += '${DbConstants.colDate} >= ? AND ';
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }
      if (endDate != null) {
        whereClause += '${DbConstants.colDate} <= ? AND ';
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }
      if (categoryId != null) {
        whereClause += '${DbConstants.colCategoryId} = ? AND ';
        whereArgs.add(categoryId);
      }
      if (type != null) {
        whereClause += '${DbConstants.colType} = ? AND ';
        whereArgs.add(type);
      }

      if (whereClause.endsWith(' AND ')) {
        whereClause = whereClause.substring(0, whereClause.length - 5);
      }

      final result = await db.query(
        DbConstants.tableTransactions,
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: '${DbConstants.colDate} DESC',
      );

      final transactions = result.map((e) => TransactionModel.fromMap(e)).toList();
      return Right(transactions);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity?>> getTransactionById(String id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        DbConstants.tableTransactions,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        return Right(TransactionModel.fromMap(result.first));
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addTransaction(TransactionEntity transaction) async {
    try {
      final db = await _dbHelper.database;
      final model = TransactionModel(
        id: transaction.id,
        amount: transaction.amount,
        currency: transaction.currency,
        type: transaction.type,
        date: transaction.date,
        payee: transaction.payee,
        categoryId: transaction.categoryId,
        notes: transaction.notes,
        source: transaction.source,
        rawText: transaction.rawText,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
      );
      await db.insert(
        DbConstants.tableTransactions,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(TransactionEntity transaction) async {
    try {
      final db = await _dbHelper.database;
      final model = TransactionModel(
        id: transaction.id,
        amount: transaction.amount,
        currency: transaction.currency,
        type: transaction.type,
        date: transaction.date,
        payee: transaction.payee,
        categoryId: transaction.categoryId,
        notes: transaction.notes,
        source: transaction.source,
        rawText: transaction.rawText,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
      );
      await db.update(
        DbConstants.tableTransactions,
        model.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: [transaction.id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        DbConstants.tableTransactions,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllData() async {
    try {
      await _dbHelper.resetDatabase();
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
