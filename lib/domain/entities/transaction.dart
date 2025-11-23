import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final double amount;
  final String currency;
  final String type; // 'spent' or 'received'
  final DateTime date;
  final String payee;
  final String? categoryId;
  final String? notes;
  final String source; // 'auto' or 'manual'
  final String? rawText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.date,
    required this.payee,
    this.categoryId,
    this.notes,
    required this.source,
    this.rawText,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        amount,
        currency,
        type,
        date,
        payee,
        categoryId,
        notes,
        source,
        rawText,
        createdAt,
        updatedAt,
      ];
}
