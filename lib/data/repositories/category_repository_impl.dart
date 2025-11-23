import 'package:dartz/dartz.dart';
import 'package:monetrack/core/constants/db_constants.dart';
import 'package:monetrack/core/errors/failures.dart';
import 'package:monetrack/data/datasources/database_helper.dart';
import 'package:monetrack/data/models/category_model.dart';
import 'package:monetrack/domain/entities/category.dart';
import 'package:monetrack/domain/repositories/category_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseHelper _dbHelper;

  CategoryRepositoryImpl(this._dbHelper);

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(DbConstants.tableCategories);
      final categories = result.map((e) => CategoryModel.fromMap(e)).toList();
      return Right(categories);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category?>> getCategoryById(String id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        DbConstants.tableCategories,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        return Right(CategoryModel.fromMap(result.first));
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCategory(Category category) async {
    try {
      final db = await _dbHelper.database;
      final model = CategoryModel(
        id: category.id,
        name: category.name,
        icon: category.icon,
        color: category.color,
        defaultType: category.defaultType,
      );
      await db.insert(
        DbConstants.tableCategories,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(Category category) async {
    try {
      final db = await _dbHelper.database;
      final model = CategoryModel(
        id: category.id,
        name: category.name,
        icon: category.icon,
        color: category.color,
        defaultType: category.defaultType,
      );
      await db.update(
        DbConstants.tableCategories,
        model.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: [category.id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      final db = await _dbHelper.database;
      // Note: Logic to reassign transactions should be handled in UseCase or here.
      // For now, just delete.
      await db.delete(
        DbConstants.tableCategories,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
