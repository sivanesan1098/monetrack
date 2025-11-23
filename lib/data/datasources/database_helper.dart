import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:monetrack/core/constants/db_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final _secureStorage = const FlutterSecureStorage();
  static const _kDbKey = 'db_key';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(DbConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Get or generate encryption key
    String? key = await _secureStorage.read(key: _kDbKey);
    if (key == null) {
      // Generate a random 32-byte key (base64 encoded)
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64UrlEncode(values);
      await _secureStorage.write(key: _kDbKey, value: key);
    }

    return await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      password: key,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const boolType = 'INTEGER NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE ${DbConstants.tableCategories} (
  ${DbConstants.colId} $idType,
  ${DbConstants.colName} $textType,
  ${DbConstants.colIcon} $textType,
  ${DbConstants.colColor} $integerType,
  ${DbConstants.colDefaultType} $textType
)
    ''');

    await db.execute('''
CREATE TABLE ${DbConstants.tableTransactions} (
  ${DbConstants.colId} $idType,
  ${DbConstants.colAmount} $realType,
  ${DbConstants.colCurrency} $textType,
  ${DbConstants.colType} $textType,
  ${DbConstants.colDate} $integerType,
  ${DbConstants.colPayee} $textType,
  ${DbConstants.colCategoryId} $textNullable,
  ${DbConstants.colNotes} $textNullable,
  ${DbConstants.colSource} $textType,
  ${DbConstants.colRawText} $textNullable,
  ${DbConstants.colCreatedAt} $integerType,
  ${DbConstants.colUpdatedAt} $integerType,
  FOREIGN KEY (${DbConstants.colCategoryId}) REFERENCES ${DbConstants.tableCategories} (${DbConstants.colId})
)
    ''');
    
    // Seed default categories
    await _seedCategories(db);
  }
  
  Future<void> _seedCategories(Database db) async {
    // Basic categories
    final defaults = [
      {'id': 'cat_food', 'name': 'Food', 'icon': 'fastfood', 'color': 0xFFFF5722, 'default_type': 'spent'},
      {'id': 'cat_transport', 'name': 'Transport', 'icon': 'directions_bus', 'color': 0xFF2196F3, 'default_type': 'spent'},
      {'id': 'cat_shopping', 'name': 'Shopping', 'icon': 'shopping_bag', 'color': 0xFFE91E63, 'default_type': 'spent'},
      {'id': 'cat_salary', 'name': 'Salary', 'icon': 'attach_money', 'color': 0xFF4CAF50, 'default_type': 'received'},
      {'id': 'cat_bills', 'name': 'Bills', 'icon': 'receipt', 'color': 0xFFFFC107, 'default_type': 'spent'},
    ];
    
    final batch = db.batch();
    for (var cat in defaults) {
      batch.insert(DbConstants.tableCategories, cat);
    }
    await batch.commit();
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete(DbConstants.tableTransactions);
    await db.delete(DbConstants.tableCategories);
    await _seedCategories(db);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
