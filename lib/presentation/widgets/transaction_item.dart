import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monetrack/domain/entities/transaction.dart';

class TransactionItem extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'spent';
    final color = isExpense ? Colors.red : Colors.green;
    final amountPrefix = isExpense ? '-' : '+';
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(
          isExpense ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
        ),
      ),
      title: Text(
        transaction.payee,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        dateFormat.format(transaction.date),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '$amountPrefix${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
