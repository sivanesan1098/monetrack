import 'package:monetrack/core/constants/db_constants.dart';
import 'package:monetrack/domain/entities/transaction.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.currency,
    required super.type,
    required super.date,
    required super.payee,
    super.categoryId,
    super.notes,
    required super.source,
    super.rawText,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map[DbConstants.colId],
      amount: map[DbConstants.colAmount],
      currency: map[DbConstants.colCurrency],
      type: map[DbConstants.colType],
      date: DateTime.fromMillisecondsSinceEpoch(map[DbConstants.colDate]),
      payee: map[DbConstants.colPayee],
      categoryId: map[DbConstants.colCategoryId],
      notes: map[DbConstants.colNotes],
      source: map[DbConstants.colSource],
      rawText: map[DbConstants.colRawText],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map[DbConstants.colCreatedAt]),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map[DbConstants.colUpdatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colId: id,
      DbConstants.colAmount: amount,
      DbConstants.colCurrency: currency,
      DbConstants.colType: type,
      DbConstants.colDate: date.millisecondsSinceEpoch,
      DbConstants.colPayee: payee,
      DbConstants.colCategoryId: categoryId,
      DbConstants.colNotes: notes,
      DbConstants.colSource: source,
      DbConstants.colRawText: rawText,
      DbConstants.colCreatedAt: createdAt.millisecondsSinceEpoch,
      DbConstants.colUpdatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? currency,
    String? type,
    DateTime? date,
    String? payee,
    String? categoryId,
    String? notes,
    String? source,
    String? rawText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      date: date ?? this.date,
      payee: payee ?? this.payee,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
