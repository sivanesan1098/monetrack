import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:monetrack/core/utils/message_parser.dart';
import 'package:monetrack/domain/entities/transaction.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();
  final MessageParser _parser = MessageParser();

  SmsService() {
    _parser.loadRules();
  }

  Future<List<TransactionEntity>> fetchAndParseSms({DateTime? start, DateTime? end}) async {
    final permission = await Permission.sms.request();
    if (!permission.isGranted) {
      throw Exception('SMS permission denied');
    }

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 1000, // Increased limit to cover longer periods
    );

    final List<TransactionEntity> transactions = [];

    for (final message in messages) {
      if (message.body == null || message.address == null || message.date == null) continue;

      // Date Filter
      if (start != null && message.date!.isBefore(start)) continue;
      if (end != null && message.date!.isAfter(end)) continue;

      // Basic filter: Only process messages from likely banks/financial sources
      // This is a heuristic; can be improved.
      // Typically bank senders are like "HDFC", "SBI", "PAYPAL", etc. (alphanumeric, no phone numbers)
      if (RegExp(r'^\+?[0-9]+$').hasMatch(message.address!)) {
        continue; // Skip likely personal numbers
      }

      final parsed = _parser.parse(message.body!);
      if (parsed != null) {
        transactions.add(TransactionEntity(
          id: const Uuid().v4(),
          amount: parsed.amount,
          currency: 'INR',
          type: parsed.type,
          date: message.date ?? DateTime.now(),
          payee: parsed.payee,
          notes: 'Imported from ${message.address}',
          source: 'auto_import',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    return transactions;
  }
}
